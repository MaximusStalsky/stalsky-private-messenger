import cors from '@fastify/cors';
import staticPlugin from '@fastify/static';
import websocket from '@fastify/websocket';
import bcrypt from 'bcryptjs';
import Fastify, { type FastifyReply, type FastifyRequest } from 'fastify';
import jwt from 'jsonwebtoken';
import fs from 'node:fs';
import path from 'node:path';
import { z, ZodError } from 'zod';
import { openDb, type Db } from './db.js';
import { fetchLinkPreview, firstHttpUrl } from './linkPreview.js';
import { pushConfigured, sendPushToUsers } from './push.js';
import { addClient, broadcastToUsers, closeSocket, onlineUserIds } from './realtime.js';
import type { MessageView, User } from './types.js';

const jwtSecret = process.env.JWT_SECRET ?? 'local-dev-change-me';

const credentialsSchema = z.object({
  username: z.string().trim().min(2).max(32).refine((value) => !/\s/.test(value), 'Username must not contain spaces'),
  password: z.string().min(4).max(128)
});

const registerSchema = credentialsSchema.extend({
  displayName: z.string().trim().min(1).max(60).optional(),
  inviteCode: z.string().trim().min(3).max(64).optional()
});

const textSchema = z.object({
  text: z.string().trim().min(1).max(4000),
  replyToMessageId: z.string().trim().min(1).optional()
});

const reactionSchema = z.object({
  reaction: z.string().trim().min(1).max(32).nullable()
});

const deleteMessagesSchema = z.object({
  messageIds: z.array(z.string().min(1)).min(1).max(100)
});

const pinMessageSchema = z.object({
  messageId: z.string().min(1)
});

const chatSettingsSchema = z.object({
  autoDeleteSeconds: z.number().int().min(60).max(31_536_000).nullable()
});

const chatUserSettingsSchema = z.object({
  pinned: z.boolean().optional(),
  archived: z.boolean().optional()
}).refine((value) => value.pinned !== undefined || value.archived !== undefined, 'At least one setting is required');

const pushTokenSchema = z.object({
  token: z.string().trim().min(20).max(4096),
  platform: z.enum(['android'])
});

const indicatorSchema = z.object({
  type: z.enum(['typing.start', 'typing.stop', 'recording.start', 'recording.stop', 'uploading.start', 'uploading.stop']),
  chatId: z.string().min(1)
});

const attachmentTypes: Record<string, { extension: string; messageType: 'photo' | 'file' | 'document' }> = {
  'image/jpeg': { extension: 'jpg', messageType: 'photo' },
  'image/png': { extension: 'png', messageType: 'photo' },
  'image/webp': { extension: 'webp', messageType: 'photo' },
  'image/gif': { extension: 'gif', messageType: 'photo' },
  'application/pdf': { extension: 'pdf', messageType: 'document' },
  'application/msword': { extension: 'doc', messageType: 'document' },
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': { extension: 'docx', messageType: 'document' },
  'application/vnd.ms-excel': { extension: 'xls', messageType: 'document' },
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': { extension: 'xlsx', messageType: 'document' },
  'application/zip': { extension: 'zip', messageType: 'file' },
  'text/plain': { extension: 'txt', messageType: 'document' },
  'application/octet-stream': { extension: 'bin', messageType: 'file' }
};

const maxAttachmentBytes = 25 * 1024 * 1024;

function dataDirectory() {
  const dbPath = process.env.DATABASE_URL ?? path.join(process.cwd(), 'data', 'messenger.sqlite');
  const normalized = dbPath.startsWith('file:') ? dbPath.slice(5) : dbPath;
  return path.dirname(path.resolve(normalized));
}

function safeClientFilename(value: unknown) {
  const raw = String(value ?? '').trim();
  if (!raw) return null;
  const base = path.basename(raw).replace(/[^\w .()-]/g, '_').replace(/\s+/g, ' ').slice(0, 160).trim();
  return base || null;
}

const callSignalSchema = z.discriminatedUnion('type', [
  z.object({
    type: z.literal('call.invite'),
    chatId: z.string().min(1),
    callId: z.string().min(1).max(128)
  }),
  z.object({
    type: z.enum(['call.accept', 'call.reject', 'call.end']),
    chatId: z.string().min(1),
    callId: z.string().min(1).max(128)
  }),
  z.object({
    type: z.enum(['call.offer', 'call.answer']),
    chatId: z.string().min(1),
    callId: z.string().min(1).max(128),
    sdp: z.string().min(1)
  }),
  z.object({
    type: z.literal('call.ice'),
    chatId: z.string().min(1),
    callId: z.string().min(1).max(128),
    candidate: z.record(z.string(), z.unknown()).nullable()
  })
]);

function id(prefix: string) {
  return `${prefix}_${crypto.randomUUID().replaceAll('-', '')}`;
}

function nowIso() {
  return new Date().toISOString();
}

function publicUser(row: any) {
  return {
    id: row.id,
    username: row.username,
    displayName: row.display_name ?? row.displayName,
    avatarUrl: row.avatar_url ?? row.avatarUrl ?? null,
    lastSeenAt: row.last_seen_at ?? row.lastSeenAt ?? null
  };
}

function getToken(request: FastifyRequest) {
  const auth = request.headers.authorization;
  if (auth?.startsWith('Bearer ')) return auth.slice('Bearer '.length);
  return undefined;
}

function getUserFromToken(db: Db, token?: string): User | null {
  if (!token) return null;
  try {
    const payload = jwt.verify(token, jwtSecret) as { sub: string };
    return db.prepare('SELECT id, username, display_name AS displayName, avatar_url AS avatarUrl, password_hash AS passwordHash, last_seen_at AS lastSeenAt, created_at AS createdAt FROM users WHERE id = ?').get(payload.sub) as User | undefined ?? null;
  } catch {
    return null;
  }
}

async function requireUser(request: FastifyRequest, reply: FastifyReply, db: Db) {
  const user = getUserFromToken(db, getToken(request));
  if (!user) {
    await reply.code(401).send({ error: 'auth_required' });
    return null;
  }
  db.prepare('UPDATE users SET last_seen_at = ? WHERE id = ?').run(nowIso(), user.id);
  return user;
}

function directChatIdFor(userA: string, userB: string) {
  return [userA, userB].sort().join(':');
}

function ensureDirectChat(db: Db, userA: string, userB: string) {
  const chatId = `direct:${directChatIdFor(userA, userB)}`;
  const existing = db.prepare('SELECT id FROM chats WHERE id = ?').get(chatId) as { id: string } | undefined;
  if (!existing) {
    const tx = db.transaction(() => {
      db.prepare('INSERT INTO chats (id, type, created_at) VALUES (?, ?, ?)').run(chatId, 'direct', nowIso());
      db.prepare('INSERT INTO chat_members (chat_id, user_id) VALUES (?, ?), (?, ?)').run(chatId, userA, chatId, userB);
    });
    tx();
  }
  return chatId;
}

function chatMembers(db: Db, chatId: string) {
  return db.prepare('SELECT user_id AS userId FROM chat_members WHERE chat_id = ?').all(chatId).map((row: any) => row.userId as string);
}

function contactUserIds(db: Db, userId: string) {
  const rows = db.prepare('SELECT contact_user_id AS userId FROM contacts WHERE owner_user_id = ?').all(userId) as Array<{ userId: string }>;
  return rows.map((row) => row.userId);
}

function broadcastPresence(db: Db, userId: string, online: boolean) {
  const row = db.prepare('SELECT id, username, display_name, avatar_url, last_seen_at FROM users WHERE id = ?').get(userId) as any | undefined;
  if (!row) return;
  const watchers = contactUserIds(db, userId);
  broadcastToUsers(watchers, { type: 'presence.updated', user: publicUser(row), online });
}

function hasChatAccess(db: Db, chatId: string, userId: string) {
  return Boolean(db.prepare('SELECT 1 FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, userId));
}

function chatSettings(db: Db, chatId: string) {
  const row = db.prepare('SELECT auto_delete_seconds AS autoDeleteSeconds, updated_at AS updatedAt FROM chat_settings WHERE chat_id = ?').get(chatId) as any | undefined;
  return {
    chatId,
    autoDeleteSeconds: row?.autoDeleteSeconds ?? null,
    updatedAt: row?.updatedAt ?? null
  };
}

function upsertChatUserSettings(db: Db, chatId: string, userId: string, patch: { pinned?: boolean; archived?: boolean }) {
  const current = db.prepare('SELECT pinned_at AS pinnedAt, archived_at AS archivedAt FROM chat_user_settings WHERE chat_id = ? AND user_id = ?').get(chatId, userId) as any | undefined;
  const updatedAt = nowIso();
  const pinnedAt = patch.pinned === undefined ? current?.pinnedAt ?? null : patch.pinned ? current?.pinnedAt ?? updatedAt : null;
  const archivedAt = patch.archived === undefined ? current?.archivedAt ?? null : patch.archived ? current?.archivedAt ?? updatedAt : null;
  db.prepare(`
    INSERT INTO chat_user_settings (chat_id, user_id, pinned_at, archived_at, updated_at)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(chat_id, user_id) DO UPDATE SET
      pinned_at = excluded.pinned_at,
      archived_at = excluded.archived_at,
      updated_at = excluded.updated_at
  `).run(chatId, userId, pinnedAt, archivedAt, updatedAt);
  return {
    chatId,
    pinned: Boolean(pinnedAt),
    archived: Boolean(archivedAt),
    pinnedAt,
    archivedAt,
    updatedAt
  };
}

function sweepExpiredMessages(db: Db, chatId: string) {
  db.prepare(`
    UPDATE messages
    SET deleted_at = ?,
        text = '',
        media_url = NULL,
        duration_ms = NULL,
        filename = NULL,
        mime_type = NULL,
        size_bytes = NULL,
        thumbnail_url = NULL,
        preview_url = NULL,
        preview_title = NULL,
        preview_description = NULL,
        preview_image_url = NULL,
        preview_domain = NULL
    WHERE chat_id = ?
      AND deleted_at IS NULL
      AND auto_delete_at IS NOT NULL
      AND auto_delete_at <= ?
  `).run(nowIso(), chatId, nowIso());
}

function messageReactions(db: Db, messageId: string) {
  const rows = db.prepare(`
    SELECT reaction, COUNT(*) AS count, json_group_array(user_id) AS userIdsJson
    FROM message_reactions
    WHERE message_id = ?
    GROUP BY reaction
    ORDER BY reaction
  `).all(messageId) as Array<{ reaction: string; count: number; userIdsJson: string }>;
  return rows.map((row) => ({
    reaction: row.reaction,
    count: Number(row.count),
    userIds: JSON.parse(row.userIdsJson) as string[]
  }));
}

function messageFromRow(message: Omit<MessageView, 'reactions' | 'linkPreview'> & {
  previewUrl: string | null;
  previewTitle: string | null;
  previewDescription: string | null;
  previewImageUrl: string | null;
  previewDomain: string | null;
}) {
  return {
    ...message,
    linkPreview: message.previewUrl && message.previewDomain
      ? {
          url: message.previewUrl,
          title: message.previewTitle,
          description: message.previewDescription,
          imageUrl: message.previewImageUrl,
          domain: message.previewDomain
        }
      : null,
    previewUrl: undefined,
    previewTitle: undefined,
    previewDescription: undefined,
    previewImageUrl: undefined,
    previewDomain: undefined
  } as Omit<MessageView, 'reactions'>;
}

function messageView(db: Db, messageId: string) {
  const message = db.prepare(`
    SELECT m.id,
           m.chat_id AS chatId,
           m.sender_id AS senderId,
           u.display_name AS senderName,
           m.type,
           m.text,
           m.media_url AS mediaUrl,
           m.duration_ms AS durationMs,
           m.filename,
           m.mime_type AS mimeType,
           m.size_bytes AS sizeBytes,
           m.thumbnail_url AS thumbnailUrl,
           m.preview_url AS previewUrl,
           m.preview_title AS previewTitle,
           m.preview_description AS previewDescription,
           m.preview_image_url AS previewImageUrl,
           m.preview_domain AS previewDomain,
           m.reply_to_message_id AS replyToMessageId,
           rm.text AS replyToText,
           ru.display_name AS replyToSenderName,
           rm.type AS replyToType,
           m.deleted_at AS deletedAt,
           m.edited_at AS editedAt,
           EXISTS(SELECT 1 FROM pinned_messages p WHERE p.chat_id = m.chat_id AND p.message_id = m.id) AS pinned,
           EXISTS(SELECT 1 FROM message_reads r WHERE r.message_id = m.id AND r.user_id != m.sender_id) AS readByPeer,
           m.created_at AS createdAt
    FROM messages m
    JOIN users u ON u.id = m.sender_id
    LEFT JOIN messages rm ON rm.id = m.reply_to_message_id AND rm.deleted_at IS NULL
    LEFT JOIN users ru ON ru.id = rm.sender_id
    WHERE m.id = ?
  `).get(messageId) as Parameters<typeof messageFromRow>[0] | undefined;
  if (!message) return undefined;
  return { ...messageFromRow(message), reactions: messageReactions(db, messageId) } as MessageView;
}

function messageRows(db: Db, chatId: string, where = '', ...params: unknown[]) {
  const rows = db.prepare(`
    SELECT m.id,
           m.chat_id AS chatId,
           m.sender_id AS senderId,
           u.display_name AS senderName,
           m.type,
           m.text,
           m.media_url AS mediaUrl,
           m.duration_ms AS durationMs,
           m.filename,
           m.mime_type AS mimeType,
           m.size_bytes AS sizeBytes,
           m.thumbnail_url AS thumbnailUrl,
           m.preview_url AS previewUrl,
           m.preview_title AS previewTitle,
           m.preview_description AS previewDescription,
           m.preview_image_url AS previewImageUrl,
           m.preview_domain AS previewDomain,
           m.reply_to_message_id AS replyToMessageId,
           rm.text AS replyToText,
           ru.display_name AS replyToSenderName,
           rm.type AS replyToType,
           m.deleted_at AS deletedAt,
           m.edited_at AS editedAt,
           EXISTS(SELECT 1 FROM pinned_messages p WHERE p.chat_id = m.chat_id AND p.message_id = m.id) AS pinned,
           EXISTS(SELECT 1 FROM message_reads r WHERE r.message_id = m.id AND r.user_id != m.sender_id) AS readByPeer,
           m.created_at AS createdAt
    FROM messages m
    JOIN users u ON u.id = m.sender_id
    LEFT JOIN messages rm ON rm.id = m.reply_to_message_id AND rm.deleted_at IS NULL
    LEFT JOIN users ru ON ru.id = rm.sender_id
    WHERE m.chat_id = ? ${where}
    ORDER BY m.created_at ASC
    LIMIT 200
  `).all(chatId, ...params) as Array<Parameters<typeof messageFromRow>[0]>;
  return rows.map((message) => ({ ...messageFromRow(message), reactions: messageReactions(db, message.id) }));
}

function userById(db: Db, userId: string) {
  return db.prepare('SELECT id, username, display_name, avatar_url FROM users WHERE id = ?').get(userId) as any | undefined;
}

function senderPayload(db: Db, user: User) {
  const sender = userById(db, user.id);
  return {
    id: user.id,
    username: user.username,
    displayName: sender?.display_name ?? user.displayName,
    avatarUrl: sender?.avatar_url ?? user.avatarUrl ?? null
  };
}

function handleIndicator(db: Db, user: User, raw: unknown) {
  const parsed = indicatorSchema.safeParse(raw);
  if (!parsed.success) return false;
  const event = parsed.data;
  if (!hasChatAccess(db, event.chatId, user.id)) return true;
  const members = chatMembers(db, event.chatId);
  if (members.length !== 2) return true;
  broadcastToUsers(members.filter((userId) => userId !== user.id), {
    type: event.type,
    chatId: event.chatId,
    from: senderPayload(db, user)
  });
  return true;
}

function handleRealtimeClientEvent(db: Db, user: User, raw: string) {
  let decoded: unknown;
  try {
    decoded = JSON.parse(raw);
  } catch {
    return;
  }
  if (handleIndicator(db, user, decoded)) return;
  handleCallSignal(db, user, decoded);
}

function handleCallSignal(db: Db, user: User, raw: unknown) {
  const parsed = callSignalSchema.safeParse(raw);
  if (!parsed.success) return;
  const event = parsed.data;

  if (!hasChatAccess(db, event.chatId, user.id)) return;
  const members = chatMembers(db, event.chatId);
  if (members.length !== 2) return;
  const recipients = members.filter((userId) => userId !== user.id);
  if (recipients.length === 0) return;
  const base = {
    type: event.type,
    chatId: event.chatId,
    callId: event.callId,
    from: senderPayload(db, user)
  };

  if (event.type === 'call.offer' || event.type === 'call.answer') {
    broadcastToUsers(recipients, { ...base, sdp: event.sdp });
    return;
  }
  if (event.type === 'call.ice') {
    broadcastToUsers(recipients, { ...base, candidate: event.candidate });
    return;
  }
  broadcastToUsers(recipients, base);
}

async function upsertDemoUser(db: Db, username: string, displayName: string, password = 'pass1234') {
  const existing = db.prepare('SELECT id FROM users WHERE username = ?').get(username) as { id: string } | undefined;
  const passwordHash = await bcrypt.hash(password, 10);
  if (existing) {
    db.prepare('UPDATE users SET display_name = ?, password_hash = ? WHERE id = ?').run(displayName, passwordHash, existing.id);
    return existing.id;
  }
  const userId = id('usr');
  db.prepare('INSERT INTO users (id, username, display_name, password_hash, created_at) VALUES (?, ?, ?, ?, ?)').run(userId, username, displayName, passwordHash, nowIso());
  return userId;
}

function addDemoMessage(db: Db, chatId: string, senderId: string, text: string) {
  const exists = db.prepare('SELECT 1 FROM messages WHERE chat_id = ? AND sender_id = ? AND text = ?').get(chatId, senderId, text);
  if (exists) return;
  db.prepare('INSERT INTO messages (id, chat_id, sender_id, text, created_at) VALUES (?, ?, ?, ?, ?)').run(id('msg'), chatId, senderId, text, nowIso());
}

async function seedDemoForOwner(db: Db, ownerId: string) {
  const annaId = await upsertDemoUser(db, 'anna', 'Anna');
  const mamaId = await upsertDemoUser(db, 'mama', 'Mama');
  const uncleId = await upsertDemoUser(db, 'uncle', 'Uncle Alex');

  for (const contactId of [annaId, mamaId, uncleId]) {
    db.prepare('INSERT OR IGNORE INTO contacts (owner_user_id, contact_user_id, created_at) VALUES (?, ?, ?)').run(ownerId, contactId, nowIso());
    db.prepare('INSERT OR IGNORE INTO contacts (owner_user_id, contact_user_id, created_at) VALUES (?, ?, ?)').run(contactId, ownerId, nowIso());
    ensureDirectChat(db, ownerId, contactId);
  }

  const annaChat = ensureDirectChat(db, ownerId, annaId);
  const mamaChat = ensureDirectChat(db, ownerId, mamaId);
  const uncleChat = ensureDirectChat(db, ownerId, uncleId);

  addDemoMessage(db, annaChat, annaId, 'Привет! Это демо-чат. Можешь написать сюда любое сообщение.');
  addDemoMessage(db, annaChat, ownerId, 'Отлично, проверяю как выглядит переписка.');
  addDemoMessage(db, mamaChat, mamaId, 'Не забудь показать мне, как этим пользоваться.');
  addDemoMessage(db, uncleChat, uncleId, 'Я фейковый контакт для теста поиска и списка чатов.');
}

export function buildApp(options: { db?: Db } = {}) {
  const db = options.db ?? openDb();
  const app = Fastify({ logger: false });
  const uploadsDir = path.resolve(process.env.UPLOADS_DIR ?? path.join(dataDirectory(), 'uploads'));
  const avatarsDir = path.join(uploadsDir, 'avatars');
  const voicesDir = path.join(uploadsDir, 'voices');
  const attachmentsDir = path.join(uploadsDir, 'attachments');

  fs.mkdirSync(avatarsDir, { recursive: true });
  fs.mkdirSync(voicesDir, { recursive: true });
  fs.mkdirSync(attachmentsDir, { recursive: true });

  app.decorate('db', db);
  app.setErrorHandler((error, request, reply) => {
    if (error instanceof ZodError) {
      const first = error.issues[0];
      return reply.code(400).send({
        error: 'validation_error',
        message: first?.message ?? 'Invalid input'
      });
    }
    console.error('request_failed', {
      method: request.method,
      url: request.url,
      message: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined
    });
    return reply.code(500).send({ error: 'internal_server_error' });
  });
  app.register(cors, { origin: true, credentials: true });
  app.addContentTypeParser(
    [
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
      'audio/mpeg',
      'audio/mp4',
      'audio/aac',
      'audio/ogg',
      'audio/webm',
      'audio/wav',
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/zip',
      'text/plain',
      'application/octet-stream'
    ],
    { parseAs: 'buffer', bodyLimit: maxAttachmentBytes },
    (_request, body, done) => done(null, body)
  );
  app.register(websocket, {
    errorHandler(error, socket) {
      closeSocket(socket, 1011, error instanceof Error ? error.message : 'websocket_error');
    }
  });

  app.get('/api/health', async () => ({ ok: true }));

  app.get('/api/push/status', async () => ({ configured: pushConfigured() }));

  app.get('/uploads/*', async (request, reply) => {
    const wildcard = (request.params as { '*': string })['*'];
    const resolved = path.resolve(uploadsDir, wildcard);
    const root = path.resolve(uploadsDir);
    if (!resolved.startsWith(root + path.sep) || !fs.existsSync(resolved)) {
      return reply.code(404).send({ error: 'not_found' });
    }
    const extension = path.extname(resolved).toLowerCase();
    const contentTypeByExtension: Record<string, string> = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.gif': 'image/gif',
      '.m4a': 'audio/mp4',
      '.mp4': 'audio/mp4',
      '.aac': 'audio/aac',
      '.mp3': 'audio/mpeg',
      '.ogg': 'audio/ogg',
      '.webm': 'audio/webm',
      '.wav': 'audio/wav',
      '.pdf': 'application/pdf',
      '.doc': 'application/msword',
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xls': 'application/vnd.ms-excel',
      '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      '.zip': 'application/zip'
    };
    reply.type(contentTypeByExtension[extension] ?? 'application/octet-stream');
    return reply.send(fs.createReadStream(resolved));
  });

  app.post('/api/invites', async (request, reply) => {
    const body = z.object({ code: z.string().trim().min(3).max(64).optional(), maxUses: z.number().int().min(1).max(100).optional() }).parse(request.body ?? {});
    const code = body.code ?? crypto.randomUUID().slice(0, 8);
    db.prepare('INSERT INTO invites (code, max_uses, used_count, created_at) VALUES (?, ?, 0, ?)').run(code, body.maxUses ?? 1, nowIso());
    return reply.code(201).send({ code });
  });

  app.post('/api/auth/register', async (request, reply) => {
    const body = registerSchema.parse(request.body);
    if (body.inviteCode) {
      const invite = db.prepare('SELECT code, max_uses AS maxUses, used_count AS usedCount, expires_at AS expiresAt FROM invites WHERE code = ?').get(body.inviteCode) as any;
      if (!invite || invite.usedCount >= invite.maxUses || (invite.expiresAt && new Date(invite.expiresAt) < new Date())) {
        return reply.code(400).send({ error: 'invalid_invite' });
      }
    }
    const userId = id('usr');
    const displayName = body.displayName || body.username;
    const passwordHash = await bcrypt.hash(body.password, 10);
    try {
      const tx = db.transaction(() => {
        db.prepare('INSERT INTO users (id, username, display_name, password_hash, created_at) VALUES (?, ?, ?, ?, ?)').run(userId, body.username, displayName, passwordHash, nowIso());
        if (body.inviteCode) db.prepare('UPDATE invites SET used_count = used_count + 1 WHERE code = ?').run(body.inviteCode);
      });
      tx();
    } catch (error: any) {
      if (String(error.message).includes('UNIQUE')) return reply.code(409).send({ error: 'username_taken' });
      throw error;
    }
    const token = jwt.sign({ sub: userId }, jwtSecret, { expiresIn: '30d' });
    return reply.code(201).send({ token, user: { id: userId, username: body.username, displayName, avatarUrl: null, lastSeenAt: null } });
  });

  app.post('/api/auth/login', async (request, reply) => {
    const body = credentialsSchema.parse(request.body);
    const user = db.prepare('SELECT id, username, display_name AS displayName, avatar_url AS avatarUrl, password_hash AS passwordHash, last_seen_at AS lastSeenAt FROM users WHERE username = ?').get(body.username) as any;
    if (!user || !(await bcrypt.compare(body.password, user.passwordHash))) {
      return reply.code(401).send({ error: 'bad_credentials' });
    }
    const token = jwt.sign({ sub: user.id }, jwtSecret, { expiresIn: '30d' });
    return { token, user: { id: user.id, username: user.username, displayName: user.displayName, avatarUrl: user.avatarUrl ?? null, lastSeenAt: user.lastSeenAt ?? null } };
  });

  app.post('/api/demo/seed', async (request) => {
    const authedUser = getUserFromToken(db, getToken(request));
    const ownerId = authedUser?.id ?? await upsertDemoUser(db, 'max', 'Max');
    await seedDemoForOwner(db, ownerId);
    db.prepare('INSERT OR IGNORE INTO invites (code, max_uses, used_count, created_at) VALUES (?, ?, 0, ?)').run('family', 50, nowIso());

    const user = db.prepare('SELECT id, username, display_name AS displayName, avatar_url AS avatarUrl, last_seen_at AS lastSeenAt FROM users WHERE id = ?').get(ownerId) as any;
    const token = jwt.sign({ sub: ownerId }, jwtSecret, { expiresIn: '30d' });
    return { token, user: { id: user.id, username: user.username, displayName: user.displayName, avatarUrl: user.avatarUrl ?? null, lastSeenAt: user.lastSeenAt ?? null } };
  });

  app.get('/api/me', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    return { user: { id: user.id, username: user.username, displayName: user.displayName, avatarUrl: user.avatarUrl ?? null, lastSeenAt: user.lastSeenAt ?? null } };
  });

  app.post('/api/me/avatar', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const body = request.body;
    if (!Buffer.isBuffer(body) || body.length < 16) {
      return reply.code(400).send({ error: 'invalid_avatar' });
    }

    const contentType = String(request.headers['content-type'] ?? '').split(';')[0].trim().toLowerCase();
    const extension = contentType === 'image/png' ? 'png' : contentType === 'image/webp' ? 'webp' : 'jpg';
    const filename = `${user.id}.${extension}`;
    const avatarPath = path.join(avatarsDir, filename);

    for (const ext of ['jpg', 'png', 'webp']) {
      if (ext !== extension) fs.rmSync(path.join(avatarsDir, `${user.id}.${ext}`), { force: true });
    }

    fs.writeFileSync(avatarPath, body);
    const avatarUrl = `/uploads/avatars/${filename}`;
    db.prepare('UPDATE users SET avatar_url = ? WHERE id = ?').run(avatarUrl, user.id);

    return {
      avatarUrl,
      user: { id: user.id, username: user.username, displayName: user.displayName, avatarUrl }
    };
  });

  app.delete('/api/me', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    db.prepare('DELETE FROM users WHERE id = ?').run(user.id);
    return reply.code(204).send();
  });

  app.post('/api/push/tokens', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const body = pushTokenSchema.parse(request.body);
    db.prepare(`
      INSERT INTO push_tokens (token, user_id, platform, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(token) DO UPDATE SET
        user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = excluded.updated_at
    `).run(body.token, user.id, body.platform, nowIso(), nowIso());
    return reply.code(204).send();
  });

  app.delete('/api/push/tokens', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const body = z.object({ token: z.string().trim().min(1).max(4096) }).parse(request.body);
    db.prepare('DELETE FROM push_tokens WHERE token = ? AND user_id = ?').run(body.token, user.id);
    return reply.code(204).send();
  });

  app.get('/api/users/search', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const query = z.object({ username: z.string().trim().min(1).max(32) }).parse(request.query);
    const rows = db.prepare(`
      SELECT id, username, display_name, avatar_url, last_seen_at
      FROM users
      WHERE username LIKE ? AND id <> ?
      ORDER BY username
      LIMIT 10
    `).all(`${query.username}%`, user.id);
    return { users: rows.map(publicUser) };
  });

  app.post('/api/contacts', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const body = z.object({ username: z.string().trim().min(1).max(32) }).parse(request.body);
    const contact = db.prepare('SELECT id, username, display_name, avatar_url, last_seen_at FROM users WHERE username = ? AND id <> ?').get(body.username, user.id) as any;
    if (!contact) return reply.code(404).send({ error: 'user_not_found' });
    db.prepare('INSERT OR IGNORE INTO contacts (owner_user_id, contact_user_id, created_at) VALUES (?, ?, ?)').run(user.id, contact.id, nowIso());
    ensureDirectChat(db, user.id, contact.id);
    return reply.code(201).send({ contact: publicUser(contact) });
  });

  app.get('/api/contacts', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const rows = db.prepare(`
      SELECT u.id, u.username, u.display_name, u.avatar_url, u.last_seen_at
      FROM contacts c
      JOIN users u ON u.id = c.contact_user_id
      WHERE c.owner_user_id = ?
      ORDER BY u.display_name COLLATE NOCASE
    `).all(user.id);
    return { contacts: rows.map(publicUser) };
  });

  app.get('/api/chats', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const online = onlineUserIds();
    const rows = db.prepare(`
      SELECT c.id,
             u.id AS peerId,
             u.username AS peerUsername,
             u.display_name AS peerDisplayName,
             u.avatar_url AS peerAvatarUrl,
             u.last_seen_at AS peerLastSeenAt,
             cus.pinned_at AS pinnedAt,
             cus.archived_at AS archivedAt,
             (SELECT text FROM messages WHERE chat_id = c.id ORDER BY created_at DESC LIMIT 1) AS lastText,
             (SELECT created_at FROM messages WHERE chat_id = c.id ORDER BY created_at DESC LIMIT 1) AS lastAt
      FROM chats c
      JOIN chat_members me ON me.chat_id = c.id AND me.user_id = ?
      JOIN chat_members other ON other.chat_id = c.id AND other.user_id <> ?
      JOIN users u ON u.id = other.user_id
      LEFT JOIN chat_user_settings cus ON cus.chat_id = c.id AND cus.user_id = ?
      ORDER BY CASE WHEN cus.pinned_at IS NULL THEN 1 ELSE 0 END, COALESCE(cus.pinned_at, lastAt, c.created_at) DESC, COALESCE(lastAt, c.created_at) DESC
    `).all(user.id, user.id, user.id);
    return { chats: rows.map((row: any) => ({ ...row, pinned: Boolean(row.pinnedAt), archived: Boolean(row.archivedAt), peerOnline: online.has(row.peerId) })) };
  });

  app.get('/api/chats/:chatId/messages', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    sweepExpiredMessages(db, chatId);
    const messages = messageRows(db, chatId);
    return { messages };
  });

  app.patch('/api/chats/:chatId/user-settings', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    const body = chatUserSettingsSchema.parse(request.body);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    const settings = upsertChatUserSettings(db, chatId, user.id, body);
    broadcastToUsers([user.id], { type: 'chat.user_settings', chatId, settings });
    return { settings };
  });

  app.put('/api/chats/:chatId/pin', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    const settings = upsertChatUserSettings(db, chatId, user.id, { pinned: true });
    return { settings };
  });

  app.delete('/api/chats/:chatId/pin', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    const settings = upsertChatUserSettings(db, chatId, user.id, { pinned: false });
    return { settings };
  });

  app.put('/api/chats/:chatId/archive', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    const settings = upsertChatUserSettings(db, chatId, user.id, { archived: true });
    return { settings };
  });

  app.delete('/api/chats/:chatId/archive', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    const settings = upsertChatUserSettings(db, chatId, user.id, { archived: false });
    return { settings };
  });

  app.post('/api/chats/:chatId/read', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    const rows = db.prepare(`
      SELECT id
      FROM messages
      WHERE chat_id = ?
        AND sender_id <> ?
        AND deleted_at IS NULL
        AND id NOT IN (SELECT message_id FROM message_reads WHERE user_id = ?)
      ORDER BY created_at ASC
      LIMIT 200
    `).all(chatId, user.id, user.id) as Array<{ id: string }>;
    if (rows.length === 0) return reply.code(204).send();
    const readAt = nowIso();
    const insert = db.prepare('INSERT OR IGNORE INTO message_reads (message_id, user_id, read_at) VALUES (?, ?, ?)');
    const tx = db.transaction(() => {
      for (const row of rows) insert.run(row.id, user.id, readAt);
    });
    tx();
    broadcastToUsers(chatMembers(db, chatId), { type: 'message.read', chatId, readerId: user.id, messageIds: rows.map((row) => row.id), readAt });
    return reply.code(204).send();
  });

  app.get('/api/chats/:chatId/messages/search', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    const query = z.object({ q: z.string().trim().min(1).max(200) }).parse(request.query);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    sweepExpiredMessages(db, chatId);
    const messages = messageRows(db, chatId, 'AND m.deleted_at IS NULL AND m.text LIKE ?', `%${query.q}%`);
    return { messages };
  });

  app.post('/api/chats/:chatId/messages', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    const body = textSchema.parse(request.body);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    if (body.replyToMessageId) {
      const replyTarget = db.prepare('SELECT id FROM messages WHERE id = ? AND chat_id = ? AND deleted_at IS NULL').get(body.replyToMessageId, chatId);
      if (!replyTarget) return reply.code(404).send({ error: 'reply_message_not_found' });
    }
    const messageId = id('msg');
    const settings = chatSettings(db, chatId);
    const autoDeleteAt = settings.autoDeleteSeconds === null ? null : new Date(Date.now() + settings.autoDeleteSeconds * 1000).toISOString();
    const previewUrl = firstHttpUrl(body.text);
    const preview = previewUrl ? await fetchLinkPreview(previewUrl) : null;
    db.prepare(`
      INSERT INTO messages (
        id, chat_id, sender_id, type, text, reply_to_message_id, auto_delete_at,
        preview_url, preview_title, preview_description, preview_image_url, preview_domain,
        created_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      messageId,
      chatId,
      user.id,
      'text',
      body.text,
      body.replyToMessageId ?? null,
      autoDeleteAt,
      preview?.url ?? null,
      preview?.title ?? null,
      preview?.description ?? null,
      preview?.imageUrl ?? null,
      preview?.domain ?? null,
      nowIso()
    );
    const message = messageView(db, messageId);
    if (!message) throw new Error('message_not_created');
    const members = chatMembers(db, chatId);
    broadcastToUsers(members, { type: 'message.created', chatId, message });
    void sendPushToUsers(db, members.filter((userId) => userId !== user.id), message, chatId);
    return reply.code(201).send({ message });
  });

  app.post('/api/chats/:chatId/voice', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    const query = z.object({ durationMs: z.coerce.number().int().min(1).max(3_600_000) }).parse(request.query);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    const body = request.body;
    if (!Buffer.isBuffer(body) || body.length < 1) return reply.code(400).send({ error: 'invalid_voice' });

    const contentType = String(request.headers['content-type'] ?? '').split(';')[0].trim().toLowerCase();
    const extensionByType: Record<string, string> = {
      'audio/mpeg': 'mp3',
      'audio/mp4': 'm4a',
      'audio/aac': 'aac',
      'audio/ogg': 'ogg',
      'audio/webm': 'webm',
      'audio/wav': 'wav',
      'application/octet-stream': 'bin'
    };
    const extension = extensionByType[contentType];
    if (!extension) return reply.code(400).send({ error: 'invalid_voice_type' });

    const messageId = id('msg');
    const filename = `${messageId}.${extension}`;
    fs.writeFileSync(path.join(voicesDir, filename), body);
    const mediaUrl = `/uploads/voices/${filename}`;
    const settings = chatSettings(db, chatId);
    const autoDeleteAt = settings.autoDeleteSeconds === null ? null : new Date(Date.now() + settings.autoDeleteSeconds * 1000).toISOString();
    db.prepare(`
      INSERT INTO messages (id, chat_id, sender_id, type, text, media_url, duration_ms, filename, mime_type, size_bytes, auto_delete_at, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(messageId, chatId, user.id, 'voice', '', mediaUrl, query.durationMs, filename, contentType, body.length, autoDeleteAt, nowIso());
    const message = messageView(db, messageId);
    const members = chatMembers(db, chatId);
    broadcastToUsers(members, { type: 'message.created', chatId, message });
    return reply.code(201).send({ message });
  });

  app.post('/api/chats/:chatId/attachments', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    const query = z.object({ filename: z.string().trim().min(1).max(240).optional() }).parse(request.query);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    const chat = db.prepare('SELECT type FROM chats WHERE id = ?').get(chatId) as { type: string } | undefined;
    if (chat?.type !== 'direct') return reply.code(400).send({ error: 'direct_chat_required' });

    const body = request.body;
    if (!Buffer.isBuffer(body) || body.length < 1) return reply.code(400).send({ error: 'invalid_attachment' });
    if (body.length > maxAttachmentBytes) return reply.code(413).send({ error: 'attachment_too_large' });

    const contentType = String(request.headers['content-type'] ?? '').split(';')[0].trim().toLowerCase();
    const typeInfo = attachmentTypes[contentType];
    if (!typeInfo) return reply.code(400).send({ error: 'invalid_attachment_type' });

    const messageId = id('msg');
    const clientFilename = safeClientFilename(query.filename ?? request.headers['x-filename']);
    const storedFilename = `${messageId}.${typeInfo.extension}`;
    fs.writeFileSync(path.join(attachmentsDir, storedFilename), body);
    const mediaUrl = `/uploads/attachments/${storedFilename}`;
    const settings = chatSettings(db, chatId);
    const autoDeleteAt = settings.autoDeleteSeconds === null ? null : new Date(Date.now() + settings.autoDeleteSeconds * 1000).toISOString();

    db.prepare(`
      INSERT INTO messages (id, chat_id, sender_id, type, text, media_url, filename, mime_type, size_bytes, thumbnail_url, auto_delete_at, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      messageId,
      chatId,
      user.id,
      typeInfo.messageType,
      '',
      mediaUrl,
      clientFilename ?? storedFilename,
      contentType,
      body.length,
      null,
      autoDeleteAt,
      nowIso()
    );
    const message = messageView(db, messageId);
    const members = chatMembers(db, chatId);
    broadcastToUsers(members, { type: 'message.created', chatId, message });
    return reply.code(201).send({ message });
  });

  app.patch('/api/messages/:messageId', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { messageId } = z.object({ messageId: z.string() }).parse(request.params);
    const body = textSchema.parse(request.body);
    const existing = db.prepare('SELECT id, chat_id AS chatId, sender_id AS senderId, deleted_at AS deletedAt FROM messages WHERE id = ?').get(messageId) as any | undefined;
    if (!existing) return reply.code(404).send({ error: 'message_not_found' });
    if (!hasChatAccess(db, existing.chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    if (existing.senderId !== user.id) return reply.code(403).send({ error: 'not_message_owner' });
    if (existing.deletedAt) return reply.code(409).send({ error: 'message_deleted' });
    db.prepare('UPDATE messages SET text = ?, edited_at = ? WHERE id = ?').run(body.text, nowIso(), messageId);
    const message = messageView(db, messageId);
    const members = chatMembers(db, existing.chatId);
    broadcastToUsers(members, { type: 'message.updated', chatId: existing.chatId, message });
    return { message };
  });

  app.delete('/api/chats/:chatId/messages', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    const body = deleteMessagesSchema.parse(request.body);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    const chat = db.prepare('SELECT type FROM chats WHERE id = ?').get(chatId) as { type: string } | undefined;
    if (chat?.type !== 'direct') return reply.code(400).send({ error: 'direct_chat_required' });

    const placeholders = body.messageIds.map(() => '?').join(',');
    const rows = db.prepare(`
      SELECT id
      FROM messages
      WHERE chat_id = ? AND id IN (${placeholders})
    `).all(chatId, ...body.messageIds) as Array<{ id: string }>;
    if (rows.length !== body.messageIds.length) return reply.code(404).send({ error: 'message_not_found' });

    db.prepare(`
      UPDATE messages
      SET deleted_at = ?,
          text = '',
          media_url = NULL,
          duration_ms = NULL,
          filename = NULL,
          mime_type = NULL,
          size_bytes = NULL,
          thumbnail_url = NULL,
          preview_url = NULL,
          preview_title = NULL,
          preview_description = NULL,
          preview_image_url = NULL,
          preview_domain = NULL
      WHERE chat_id = ? AND id IN (${placeholders})
    `).run(nowIso(), chatId, ...body.messageIds);
    db.prepare(`DELETE FROM pinned_messages WHERE chat_id = ? AND message_id IN (${placeholders})`).run(chatId, ...body.messageIds);

    const messageIds = rows.map((row) => row.id);
    broadcastToUsers(chatMembers(db, chatId), { type: 'message.deleted', chatId, messageIds });
    return reply.code(204).send();
  });

  app.post('/api/messages/:messageId/reactions', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { messageId } = z.object({ messageId: z.string() }).parse(request.params);
    const body = reactionSchema.parse(request.body);
    const existing = db.prepare('SELECT id, chat_id AS chatId FROM messages WHERE id = ?').get(messageId) as any | undefined;
    if (!existing) return reply.code(404).send({ error: 'message_not_found' });
    if (!hasChatAccess(db, existing.chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    if (body.reaction === null) {
      db.prepare('DELETE FROM message_reactions WHERE message_id = ? AND user_id = ?').run(messageId, user.id);
    } else {
      db.prepare(`
        INSERT INTO message_reactions (message_id, user_id, reaction, created_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(message_id, user_id) DO UPDATE SET reaction = excluded.reaction, created_at = excluded.created_at
      `).run(messageId, user.id, body.reaction, nowIso());
    }
    const message = messageView(db, messageId);
    broadcastToUsers(chatMembers(db, existing.chatId), { type: 'message.reaction', chatId: existing.chatId, message });
    return { message };
  });

  app.get('/api/chats/:chatId/pins', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    const pins = db.prepare('SELECT message_id AS messageId, pinned_by AS pinnedBy, pinned_at AS pinnedAt FROM pinned_messages WHERE chat_id = ? ORDER BY pinned_at DESC').all(chatId);
    return { pins };
  });

  app.post('/api/chats/:chatId/pins', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    const body = pinMessageSchema.parse(request.body);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    const message = db.prepare('SELECT id, deleted_at AS deletedAt FROM messages WHERE id = ? AND chat_id = ?').get(body.messageId, chatId) as any | undefined;
    if (!message) return reply.code(404).send({ error: 'message_not_found' });
    if (message.deletedAt) return reply.code(409).send({ error: 'message_deleted' });
    const count = db.prepare('SELECT COUNT(*) AS count FROM pinned_messages WHERE chat_id = ?').get(chatId) as { count: number };
    const alreadyPinned = db.prepare('SELECT 1 FROM pinned_messages WHERE chat_id = ? AND message_id = ?').get(chatId, body.messageId);
    if (!alreadyPinned && count.count >= 3) return reply.code(409).send({ error: 'pin_limit_reached' });
    db.prepare(`
      INSERT INTO pinned_messages (chat_id, message_id, pinned_by, pinned_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(chat_id, message_id) DO UPDATE SET pinned_by = excluded.pinned_by, pinned_at = excluded.pinned_at
    `).run(chatId, body.messageId, user.id, nowIso());
    const pins = db.prepare('SELECT message_id AS messageId, pinned_by AS pinnedBy, pinned_at AS pinnedAt FROM pinned_messages WHERE chat_id = ? ORDER BY pinned_at DESC').all(chatId);
    broadcastToUsers(chatMembers(db, chatId), { type: 'message.pinned', chatId, pins });
    return reply.code(201).send({ pins });
  });

  app.delete('/api/chats/:chatId/pins/:messageId', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId, messageId } = z.object({ chatId: z.string(), messageId: z.string() }).parse(request.params);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    db.prepare('DELETE FROM pinned_messages WHERE chat_id = ? AND message_id = ?').run(chatId, messageId);
    const pins = db.prepare('SELECT message_id AS messageId, pinned_by AS pinnedBy, pinned_at AS pinnedAt FROM pinned_messages WHERE chat_id = ? ORDER BY pinned_at DESC').all(chatId);
    broadcastToUsers(chatMembers(db, chatId), { type: 'message.pinned', chatId, pins });
    return { pins };
  });

  app.delete('/api/chats/:chatId/pins', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    db.prepare('DELETE FROM pinned_messages WHERE chat_id = ?').run(chatId);
    const pins: any[] = [];
    broadcastToUsers(chatMembers(db, chatId), { type: 'message.pinned', chatId, pins });
    return { pins };
  });

  app.get('/api/chats/:chatId/settings', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    return { settings: chatSettings(db, chatId) };
  });

  app.patch('/api/chats/:chatId/settings', async (request, reply) => {
    const user = await requireUser(request, reply, db);
    if (!user) return;
    const { chatId } = z.object({ chatId: z.string() }).parse(request.params);
    const body = chatSettingsSchema.parse(request.body);
    if (!hasChatAccess(db, chatId, user.id)) return reply.code(403).send({ error: 'forbidden' });
    db.prepare(`
      INSERT INTO chat_settings (chat_id, auto_delete_seconds, updated_by, updated_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(chat_id) DO UPDATE SET
        auto_delete_seconds = excluded.auto_delete_seconds,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at
    `).run(chatId, body.autoDeleteSeconds, user.id, nowIso());
    const settings = chatSettings(db, chatId);
    broadcastToUsers(chatMembers(db, chatId), { type: 'message.settings', chatId, settings });
    return { settings };
  });

  app.register(async (fastify) => {
    fastify.get('/ws', { websocket: true }, (socket, request) => {
      const token = new URL(request.url ?? '', 'http://localhost').searchParams.get('token') ?? getToken(request);
      const user = getUserFromToken(db, token);
      if (!user) {
        closeSocket(socket, 1008, 'auth_required');
        return;
      }
      db.prepare('UPDATE users SET last_seen_at = ? WHERE id = ?').run(nowIso(), user.id);
      addClient(
        user.id,
        socket,
        (_userId, data) => handleRealtimeClientEvent(db, user, data),
        (userId) => {
          try {
            db.prepare('UPDATE users SET last_seen_at = ? WHERE id = ?').run(nowIso(), userId);
            if (!onlineUserIds().has(userId)) broadcastPresence(db, userId, false);
          } catch {
            // The app can be shutting down while WebSocket close callbacks drain.
          }
        }
      );
      broadcastPresence(db, user.id, true);
      socket.send(JSON.stringify({ type: 'connected', userId: user.id }));
    });
  });

  const publicDir = path.join(process.cwd(), '..', 'apps', 'messenger_app', 'build', 'web');
  app.register(staticPlugin, {
    root: publicDir,
    prefix: '/',
    decorateReply: false,
    wildcard: false
  }).after(() => {
    app.setNotFoundHandler((request, reply) => {
      if (request.url.startsWith('/api/') || request.url.startsWith('/ws')) {
        return reply.code(404).send({ error: 'not_found' });
      }
      return reply.sendFile('index.html');
    });
  });

  return app;
}
