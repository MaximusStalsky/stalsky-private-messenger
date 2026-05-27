import Database from 'better-sqlite3';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import WebSocket from 'ws';
import { buildApp } from '../src/app.js';
import { migrate, type Db } from '../src/db.js';
import { fallbackLinkPreview } from '../src/linkPreview.js';
import { pushConfigured } from '../src/push.js';

let db: Db;
let app: ReturnType<typeof buildApp>;
let uploadsDir: string;
let previousUploadsDir: string | undefined;

async function createInvite(code = 'family', maxUses = 10) {
  return app.inject({
    method: 'POST',
    url: '/api/invites',
    payload: { code, maxUses }
  });
}

async function register(username: string, password = 'pass1234') {
  const res = await app.inject({
    method: 'POST',
    url: '/api/auth/register',
    payload: { username, password, displayName: username[0].toUpperCase() + username.slice(1) }
  });
  expect(res.statusCode).toBe(201);
  return res.json() as { token: string; user: { id: string; username: string; displayName: string } };
}

async function registerWithInvite(username: string, inviteCode: string, password = 'pass1234') {
  const res = await app.inject({
    method: 'POST',
    url: '/api/auth/register',
    payload: { username, password, inviteCode, displayName: username[0].toUpperCase() + username.slice(1) }
  });
  return res;
}

async function authGet(token: string, url: string) {
  return app.inject({ method: 'GET', url, headers: { authorization: `Bearer ${token}` } });
}

async function authPost(token: string, url: string, payload: any) {
  return app.inject({ method: 'POST', url, headers: { authorization: `Bearer ${token}` }, payload });
}

async function authPatch(token: string, url: string, payload: any) {
  return app.inject({ method: 'PATCH', url, headers: { authorization: `Bearer ${token}` }, payload });
}

async function authPut(token: string, url: string, payload?: any) {
  return app.inject({ method: 'PUT', url, headers: { authorization: `Bearer ${token}` }, payload });
}

async function authDelete(token: string, url: string, payload?: any) {
  return app.inject({ method: 'DELETE', url, headers: { authorization: `Bearer ${token}` }, payload });
}

beforeEach(async () => {
  previousUploadsDir = process.env.UPLOADS_DIR;
  uploadsDir = fs.mkdtempSync(path.join(os.tmpdir(), 'messenger-test-uploads-'));
  process.env.UPLOADS_DIR = uploadsDir;
  db = new Database(':memory:');
  migrate(db);
  app = buildApp({ db });
  await app.ready();
});

afterEach(async () => {
  await app.close();
  db.close();
  fs.rmSync(uploadsDir, { recursive: true, force: true });
  if (previousUploadsDir === undefined) delete process.env.UPLOADS_DIR;
  else process.env.UPLOADS_DIR = previousUploadsDir;
});

describe('auth and invites', () => {
  it('allows open registration and rejects only an explicitly invalid invite', async () => {
    const open = await register('openuser');
    expect(open.token).toBeTruthy();

    const res = await registerWithInvite('max', 'bad');
    expect(res.statusCode).toBe(400);
    expect(res.json().error).toBe('invalid_invite');
  });

  it('registers with optional invite, enforces unique username, and logs in', async () => {
    await createInvite();
    const firstResponse = await registerWithInvite('max', 'family');
    expect(firstResponse.statusCode).toBe(201);
    const first = firstResponse.json();
    expect(first.token).toBeTruthy();

    const duplicate = await app.inject({
      method: 'POST',
      url: '/api/auth/register',
      payload: { username: 'MAX', password: 'pass1234', inviteCode: 'family' }
    });
    expect(duplicate.statusCode).toBe(409);

    const login = await app.inject({
      method: 'POST',
      url: '/api/auth/login',
      payload: { username: 'max', password: 'pass1234' }
    });
    expect(login.statusCode).toBe(200);
    expect(login.json().token).toBeTruthy();
  });

  it('deletes the current user and invalidates future access', async () => {
    const user = await register('delete_me');
    const me = await authGet(user.token, '/api/me');
    expect(me.statusCode).toBe(200);

    const deleted = await app.inject({ method: 'DELETE', url: '/api/me', headers: { authorization: `Bearer ${user.token}` } });
    expect(deleted.statusCode).toBe(204);

    const after = await authGet(user.token, '/api/me');
    expect(after.statusCode).toBe(401);
  });

  it('stores and updates Android push tokens for the current user', async () => {
    const user = await register('push_user');
    const token = 'fcm_' + 'a'.repeat(80);

    const saved = await authPost(user.token, '/api/push/tokens', { token, platform: 'android' });
    expect(saved.statusCode).toBe(204);

    const rows = db.prepare('SELECT user_id AS userId, platform FROM push_tokens WHERE token = ?').all(token) as any[];
    expect(rows).toHaveLength(1);
    expect(rows[0].userId).toBe(user.user.id);
    expect(rows[0].platform).toBe('android');
  });

  it('recognizes Firebase credentials supplied as base64 JSON', async () => {
    const previousProjectId = process.env.FIREBASE_PROJECT_ID;
    const previousJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    const previousBase64 = process.env.FIREBASE_SERVICE_ACCOUNT_JSON_BASE64;
    const serviceAccount = {
      project_id: 'test-project',
      client_email: 'push@test-project.iam.gserviceaccount.com',
      private_key: 'fake'
    };

    try {
      delete process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
      process.env.FIREBASE_PROJECT_ID = 'test-project';
      process.env.FIREBASE_SERVICE_ACCOUNT_JSON_BASE64 = Buffer.from(JSON.stringify(serviceAccount), 'utf8').toString('base64');

      expect(pushConfigured()).toBe(true);
    } finally {
      if (previousProjectId === undefined) delete process.env.FIREBASE_PROJECT_ID;
      else process.env.FIREBASE_PROJECT_ID = previousProjectId;
      if (previousJson === undefined) delete process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
      else process.env.FIREBASE_SERVICE_ACCOUNT_JSON = previousJson;
      if (previousBase64 === undefined) delete process.env.FIREBASE_SERVICE_ACCOUNT_JSON_BASE64;
      else process.env.FIREBASE_SERVICE_ACCOUNT_JSON_BASE64 = previousBase64;
    }
  });
});

describe('contacts, chats, and messages', () => {
  it('stores the current user avatar and returns it in profile, contacts, and chats', async () => {
    const max = await register('max');
    const anna = await register('anna');
    const avatarBytes = Buffer.concat([
      Buffer.from([0xff, 0xd8, 0xff, 0xe0]),
      Buffer.alloc(64, 7),
      Buffer.from([0xff, 0xd9])
    ]);

    const unauthorized = await app.inject({
      method: 'POST',
      url: '/api/me/avatar',
      headers: { 'content-type': 'image/jpeg' },
      payload: avatarBytes
    });
    expect(unauthorized.statusCode).toBe(401);

    const uploaded = await app.inject({
      method: 'POST',
      url: '/api/me/avatar',
      headers: { authorization: `Bearer ${max.token}`, 'content-type': 'image/jpeg' },
      payload: avatarBytes
    });
    expect(uploaded.statusCode).toBe(200);
    const avatarUrl = uploaded.json().avatarUrl;
    expect(avatarUrl).toMatch(/^\/uploads\/avatars\/usr_/);
    expect(fs.existsSync(path.join(uploadsDir, 'avatars', path.basename(avatarUrl)))).toBe(true);

    const me = await authGet(max.token, '/api/me');
    expect(me.json().user.avatarUrl).toBe(avatarUrl);

    await authPost(anna.token, '/api/contacts', { username: 'max' });
    const contacts = await authGet(anna.token, '/api/contacts');
    expect(contacts.json().contacts[0].avatarUrl).toBe(avatarUrl);

    const chats = await authGet(anna.token, '/api/chats');
    expect(chats.json().chats[0].peerAvatarUrl).toBe(avatarUrl);
  });

  it('adds a contact, creates one direct chat, and protects chat access', async () => {
    const max = await register('max');
    const anna = await register('anna');
    const stranger = await register('stranger');

    const search = await authGet(max.token, '/api/users/search?username=ann');
    expect(search.statusCode).toBe(200);
    expect(search.json().users[0].username).toBe('anna');

    const contact = await authPost(max.token, '/api/contacts', { username: 'anna' });
    expect(contact.statusCode).toBe(201);

    const chats = await authGet(max.token, '/api/chats');
    expect(chats.statusCode).toBe(200);
    expect(chats.json().chats).toHaveLength(1);
    const chatId = chats.json().chats[0].id;

    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatsAgain = await authGet(max.token, '/api/chats');
    expect(chatsAgain.json().chats).toHaveLength(1);

    const blocked = await authGet(stranger.token, `/api/chats/${encodeURIComponent(chatId)}/messages`);
    expect(blocked.statusCode).toBe(403);

    const sent = await authPost(max.token, `/api/chats/${encodeURIComponent(chatId)}/messages`, { text: 'Hello Anna' });
    expect(sent.statusCode).toBe(201);
    expect(sent.json().message.text).toBe('Hello Anna');

    const replied = await authPost(anna.token, `/api/chats/${encodeURIComponent(chatId)}/messages`, { text: 'Reply text', replyToMessageId: sent.json().message.id });
    expect(replied.statusCode).toBe(201);
    expect(replied.json().message.replyToText).toBe('Hello Anna');
    expect(replied.json().message.replyToSenderName).toBe('Max');

    const messages = await authGet(anna.token, `/api/chats/${encodeURIComponent(chatId)}/messages`);
    expect(messages.statusCode).toBe(200);
    expect(messages.json().messages[0].text).toBe('Hello Anna');
    expect(messages.json().messages[1].replyToMessageId).toBe(sent.json().message.id);
  });

  it('edits own messages, searches chat text, reacts, and deletes selected direct messages for everyone', async () => {
    const max = await register('max');
    const anna = await register('anna');
    const stranger = await register('stranger');
    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatId = (await authGet(max.token, '/api/chats')).json().chats[0].id;

    const sent = await authPost(max.token, `/api/chats/${encodeURIComponent(chatId)}/messages`, { text: 'First searchable text' });
    expect(sent.statusCode).toBe(201);
    const message = sent.json().message;
    expect(message.type).toBe('text');
    expect(message.mediaUrl).toBeNull();
    expect(message.durationMs).toBeNull();
    expect(message.deletedAt).toBeNull();
    expect(message.editedAt).toBeNull();
    expect(message.reactions).toEqual([]);

    const forbiddenEdit = await authPatch(anna.token, `/api/messages/${encodeURIComponent(message.id)}`, { text: 'Nope' });
    expect(forbiddenEdit.statusCode).toBe(403);

    const edited = await authPatch(max.token, `/api/messages/${encodeURIComponent(message.id)}`, { text: 'Edited searchable text' });
    expect(edited.statusCode).toBe(200);
    expect(edited.json().message.text).toBe('Edited searchable text');
    expect(edited.json().message.editedAt).toBeTruthy();

    const search = await authGet(anna.token, `/api/chats/${encodeURIComponent(chatId)}/messages/search?q=searchable`);
    expect(search.statusCode).toBe(200);
    expect(search.json().messages).toHaveLength(1);
    expect(search.json().messages[0].id).toBe(message.id);

    const reacted = await authPost(anna.token, `/api/messages/${encodeURIComponent(message.id)}/reactions`, { reaction: 'heart' });
    expect(reacted.statusCode).toBe(200);
    expect(reacted.json().message.reactions).toEqual([{ reaction: 'heart', count: 1, userIds: [anna.user.id] }]);

    const blockedDelete = await authDelete(stranger.token, `/api/chats/${encodeURIComponent(chatId)}/messages`, { messageIds: [message.id] });
    expect(blockedDelete.statusCode).toBe(403);

    const deleted = await authDelete(anna.token, `/api/chats/${encodeURIComponent(chatId)}/messages`, { messageIds: [message.id] });
    expect(deleted.statusCode).toBe(204);

    const messages = await authGet(max.token, `/api/chats/${encodeURIComponent(chatId)}/messages`);
    expect(messages.json().messages[0].deletedAt).toBeTruthy();
    expect(messages.json().messages[0].text).toBe('');
  });

  it('limits pins to three messages and applies auto-delete settings', async () => {
    const max = await register('max');
    const anna = await register('anna');
    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatId = (await authGet(max.token, '/api/chats')).json().chats[0].id;

    const messageIds: string[] = [];
    for (const text of ['one', 'two', 'three', 'four']) {
      const sent = await authPost(max.token, `/api/chats/${encodeURIComponent(chatId)}/messages`, { text });
      messageIds.push(sent.json().message.id);
    }

    for (const messageId of messageIds.slice(0, 3)) {
      const pinned = await authPost(max.token, `/api/chats/${encodeURIComponent(chatId)}/pins`, { messageId });
      expect(pinned.statusCode).toBe(201);
    }
    const overLimit = await authPost(max.token, `/api/chats/${encodeURIComponent(chatId)}/pins`, { messageId: messageIds[3] });
    expect(overLimit.statusCode).toBe(409);
    expect(overLimit.json().error).toBe('pin_limit_reached');

    const pins = await authGet(anna.token, `/api/chats/${encodeURIComponent(chatId)}/pins`);
    expect(pins.statusCode).toBe(200);
    expect(pins.json().pins).toHaveLength(3);
    const unpinned = await authDelete(max.token, `/api/chats/${encodeURIComponent(chatId)}/pins/${encodeURIComponent(messageIds[0])}`);
    expect(unpinned.statusCode).toBe(200);
    expect(unpinned.json().pins).toHaveLength(2);
    const clearedPins = await authDelete(max.token, `/api/chats/${encodeURIComponent(chatId)}/pins`);
    expect(clearedPins.statusCode).toBe(200);
    expect(clearedPins.json().pins).toHaveLength(0);

    const settings = await authPatch(max.token, `/api/chats/${encodeURIComponent(chatId)}/settings`, { autoDeleteSeconds: 60 });
    expect(settings.statusCode).toBe(200);
    expect(settings.json().settings.autoDeleteSeconds).toBe(60);

    const expiring = await authPost(max.token, `/api/chats/${encodeURIComponent(chatId)}/messages`, { text: 'expires' });
    const expiringId = expiring.json().message.id;
    db.prepare("UPDATE messages SET auto_delete_at = datetime('now', '-1 second') WHERE id = ?").run(expiringId);

    const messages = await authGet(anna.token, `/api/chats/${encodeURIComponent(chatId)}/messages`);
    const expired = messages.json().messages.find((row: any) => row.id === expiringId);
    expect(expired.deletedAt).toBeTruthy();
    expect(expired.text).toBe('');
  });

  it('uploads voice messages with storage metadata', async () => {
    const max = await register('max');
    const anna = await register('anna');
    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatId = (await authGet(max.token, '/api/chats')).json().chats[0].id;
    const bytes = Buffer.from([1, 2, 3, 4, 5, 6, 7, 8]);

    const uploaded = await app.inject({
      method: 'POST',
      url: `/api/chats/${encodeURIComponent(chatId)}/voice?durationMs=1234`,
      headers: { authorization: `Bearer ${max.token}`, 'content-type': 'audio/webm' },
      payload: bytes
    });

    expect(uploaded.statusCode).toBe(201);
    const message = uploaded.json().message;
    expect(message.type).toBe('voice');
    expect(message.text).toBe('');
    expect(message.durationMs).toBe(1234);
    expect(message.mimeType).toBe('audio/webm');
    expect(message.sizeBytes).toBe(bytes.length);
    expect(message.mediaUrl).toMatch(/^\/uploads\/voices\/msg_.*\.webm$/);
    expect(fs.existsSync(path.join(uploadsDir, 'voices', path.basename(message.mediaUrl)))).toBe(true);
    const downloaded = await app.inject({ method: 'GET', url: message.mediaUrl });
    expect(downloaded.statusCode).toBe(200);
    expect(Buffer.compare(downloaded.rawPayload, bytes)).toBe(0);
  });

  it('uploads attachments in direct chats with media metadata', async () => {
    const max = await register('max');
    const anna = await register('anna');
    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatId = (await authGet(max.token, '/api/chats')).json().chats[0].id;
    const bytes = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(32, 5), Buffer.from([0xff, 0xd9])]);

    const uploaded = await app.inject({
      method: 'POST',
      url: `/api/chats/${encodeURIComponent(chatId)}/attachments?filename=family.jpg`,
      headers: { authorization: `Bearer ${max.token}`, 'content-type': 'image/jpeg' },
      payload: bytes
    });

    expect(uploaded.statusCode).toBe(201);
    const message = uploaded.json().message;
    expect(message.type).toBe('photo');
    expect(message.text).toBe('');
    expect(message.filename).toBe('family.jpg');
    expect(message.mimeType).toBe('image/jpeg');
    expect(message.sizeBytes).toBe(bytes.length);
    expect(message.mediaUrl).toMatch(/^\/uploads\/attachments\/msg_.*\.jpg$/);
    expect(message.attachment).toMatchObject({
      kind: 'photo',
      fileName: 'family.jpg',
      url: message.mediaUrl,
      mimeType: 'image/jpeg',
      sizeBytes: bytes.length
    });
    expect(fs.existsSync(path.join(uploadsDir, 'attachments', path.basename(message.mediaUrl)))).toBe(true);

    const messages = await authGet(anna.token, `/api/chats/${encodeURIComponent(chatId)}/messages`);
    expect(messages.json().messages[0].id).toBe(message.id);
    expect(messages.json().messages[0].mimeType).toBe('image/jpeg');
    expect(messages.json().messages[0].attachment.url).toBe(message.mediaUrl);
  });

  it('uploads plain text attachments as documents', async () => {
    const max = await register('max');
    await register('anna');
    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatId = (await authGet(max.token, '/api/chats')).json().chats[0].id;
    const bytes = Buffer.from('family note');

    const uploaded = await app.inject({
      method: 'POST',
      url: `/api/chats/${encodeURIComponent(chatId)}/attachments?filename=note.txt`,
      headers: { authorization: `Bearer ${max.token}`, 'content-type': 'text/plain' },
      payload: bytes
    });

    expect(uploaded.statusCode).toBe(201);
    const message = uploaded.json().message;
    expect(message.type).toBe('document');
    expect(message.filename).toBe('note.txt');
    expect(message.mimeType).toBe('text/plain');
    expect(message.mediaUrl).toMatch(/^\/uploads\/attachments\/msg_.*\.txt$/);
  });

  it('pins and archives chats per current user', async () => {
    const max = await register('max');
    const anna = await register('anna');
    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatId = (await authGet(max.token, '/api/chats')).json().chats[0].id;

    const settings = await authPatch(max.token, `/api/chats/${encodeURIComponent(chatId)}/user-settings`, { pinned: true, archived: true });
    expect(settings.statusCode).toBe(200);
    expect(settings.json().settings.pinned).toBe(true);
    expect(settings.json().settings.archived).toBe(true);

    const maxChats = await authGet(max.token, '/api/chats');
    expect(maxChats.json().chats[0].pinned).toBe(true);
    expect(maxChats.json().chats[0].archived).toBe(true);

    const annaChats = await authGet(anna.token, '/api/chats');
    expect(annaChats.json().chats[0].pinned).toBe(false);
    expect(annaChats.json().chats[0].archived).toBe(false);

    const unpinned = await authDelete(max.token, `/api/chats/${encodeURIComponent(chatId)}/pin`);
    expect(unpinned.statusCode).toBe(200);
    expect(unpinned.json().settings.pinned).toBe(false);

    const archived = await authPut(max.token, `/api/chats/${encodeURIComponent(chatId)}/archive`);
    expect(archived.statusCode).toBe(200);
    expect(archived.json().settings.archived).toBe(true);
  });

  it('returns domain-only link previews when richer parsing is unavailable', async () => {
    expect(fallbackLinkPreview('https://example.com/path?x=1')).toEqual({
      url: 'https://example.com/path?x=1',
      title: null,
      description: null,
      imageUrl: null,
      domain: 'example.com'
    });

    const max = await register('max');
    const anna = await register('anna');
    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatId = (await authGet(max.token, '/api/chats')).json().chats[0].id;

    const sent = await authPost(max.token, `/api/chats/${encodeURIComponent(chatId)}/messages`, { text: 'Check http://127.0.0.1/private' });
    expect(sent.statusCode).toBe(201);
    expect(sent.json().message.linkPreview).toEqual({
      url: 'http://127.0.0.1/private',
      title: null,
      description: null,
      imageUrl: null,
      domain: '127.0.0.1'
    });
  });

  it('broadcasts websocket events for updates, deletes, reactions, pins, and settings', async () => {
    const max = await register('max');
    const anna = await register('anna');
    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatId = (await authGet(max.token, '/api/chats')).json().chats[0].id;
    const sent = await authPost(max.token, `/api/chats/${encodeURIComponent(chatId)}/messages`, { text: 'Realtime target' });
    const messageId = sent.json().message.id;

    const address = await app.listen({ port: 0, host: '127.0.0.1' });
    const socket = new WebSocket(address.replace('http://', 'ws://') + `/ws?token=${encodeURIComponent(anna.token)}`);
    const received = new Set<string>();
    const expected = new Set(['message.updated', 'message.reaction', 'message.pinned', 'message.settings', 'message.deleted']);

    const eventsPromise = new Promise<Set<string>>((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('websocket events timeout')), 3000);
      socket.on('message', (data: Buffer) => {
        const event = JSON.parse(data.toString());
        if (expected.has(event.type)) received.add(event.type);
        if ([...expected].every((type) => received.has(type))) {
          clearTimeout(timer);
          resolve(received);
        }
      });
      socket.on('error', reject);
    });

    await new Promise<void>((resolve, reject) => {
      socket.once('open', () => resolve());
      socket.once('error', reject);
    });

    await authPatch(max.token, `/api/messages/${encodeURIComponent(messageId)}`, { text: 'Realtime edited' });
    await authPost(anna.token, `/api/messages/${encodeURIComponent(messageId)}/reactions`, { reaction: 'ok' });
    await authPost(max.token, `/api/chats/${encodeURIComponent(chatId)}/pins`, { messageId });
    await authPatch(max.token, `/api/chats/${encodeURIComponent(chatId)}/settings`, { autoDeleteSeconds: 60 });
    await authDelete(max.token, `/api/chats/${encodeURIComponent(chatId)}/messages`, { messageIds: [messageId] });

    const events = await eventsPromise;
    expect([...expected].every((type) => events.has(type))).toBe(true);
    socket.close();
  }, 10000);

  it('delivers new messages through websocket', async () => {
    const max = await register('max');
    const anna = await register('anna');
    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatId = (await authGet(max.token, '/api/chats')).json().chats[0].id;

    const address = await app.listen({ port: 0, host: '127.0.0.1' });
    const socket = new WebSocket(address.replace('http://', 'ws://') + `/ws?token=${encodeURIComponent(anna.token)}`);

    const eventPromise = new Promise<any>((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('websocket timeout')), 3000);
      socket.on('message', (data: Buffer) => {
        const event = JSON.parse(data.toString());
        if (event.type === 'message.created') {
          clearTimeout(timer);
          resolve(event);
        }
      });
      socket.on('error', reject);
    });

    await new Promise<void>((resolve, reject) => {
      socket.once('open', () => resolve());
      socket.once('error', reject);
    });
    await authPost(max.token, `/api/chats/${encodeURIComponent(chatId)}/messages`, { text: 'Realtime hello' });
    const event = await eventPromise;
    expect(event.message.text).toBe('Realtime hello');
    socket.close();
  }, 10000);

  it('routes call signaling only to the other direct chat member', async () => {
    const max = await register('max');
    const anna = await register('anna');
    const stranger = await register('stranger');
    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatId = (await authGet(max.token, '/api/chats')).json().chats[0].id;

    const address = await app.listen({ port: 0, host: '127.0.0.1' });
    const annaSocket = new WebSocket(address.replace('http://', 'ws://') + `/ws?token=${encodeURIComponent(anna.token)}`);
    const strangerSocket = new WebSocket(address.replace('http://', 'ws://') + `/ws?token=${encodeURIComponent(stranger.token)}`);
    const maxSocket = new WebSocket(address.replace('http://', 'ws://') + `/ws?token=${encodeURIComponent(max.token)}`);

    await Promise.all([annaSocket, strangerSocket, maxSocket].map((socket) => new Promise<void>((resolve, reject) => {
      socket.once('open', () => resolve());
      socket.once('error', reject);
    })));

    let strangerReceived = false;
    strangerSocket.on('message', (data: Buffer) => {
      const event = JSON.parse(data.toString());
      if (event.type?.startsWith('call.')) strangerReceived = true;
    });

    const invitePromise = new Promise<any>((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('call signal timeout')), 3000);
      annaSocket.on('message', (data: Buffer) => {
        const event = JSON.parse(data.toString());
        if (event.type === 'call.invite') {
          clearTimeout(timer);
          resolve(event);
        }
      });
    });

    maxSocket.send(JSON.stringify({ type: 'call.invite', chatId, callId: 'call_test' }));
    const invite = await invitePromise;

    expect(invite.chatId).toBe(chatId);
    expect(invite.callId).toBe('call_test');
    expect(invite.from.username).toBe('max');
    expect(strangerReceived).toBe(false);

    annaSocket.close();
    strangerSocket.close();
    maxSocket.close();
  }, 10000);

  it('routes typing, recording, and uploading indicators only to the other direct chat member', async () => {
    const max = await register('max');
    const anna = await register('anna');
    const stranger = await register('stranger');
    await authPost(max.token, '/api/contacts', { username: 'anna' });
    const chatId = (await authGet(max.token, '/api/chats')).json().chats[0].id;

    const address = await app.listen({ port: 0, host: '127.0.0.1' });
    const annaSocket = new WebSocket(address.replace('http://', 'ws://') + `/ws?token=${encodeURIComponent(anna.token)}`);
    const strangerSocket = new WebSocket(address.replace('http://', 'ws://') + `/ws?token=${encodeURIComponent(stranger.token)}`);
    const maxSocket = new WebSocket(address.replace('http://', 'ws://') + `/ws?token=${encodeURIComponent(max.token)}`);

    await Promise.all([annaSocket, strangerSocket, maxSocket].map((socket) => new Promise<void>((resolve, reject) => {
      socket.once('open', () => resolve());
      socket.once('error', reject);
    })));

    const expected = new Set(['typing.start', 'recording.start', 'uploading.stop']);
    const received = new Set<string>();
    let strangerReceived = false;

    strangerSocket.on('message', (data: Buffer) => {
      const event = JSON.parse(data.toString());
      if (expected.has(event.type)) strangerReceived = true;
    });

    const indicatorPromise = new Promise<Set<string>>((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('indicator timeout')), 3000);
      annaSocket.on('message', (data: Buffer) => {
        const event = JSON.parse(data.toString());
        if (expected.has(event.type)) {
          received.add(event.type);
          expect(event.chatId).toBe(chatId);
          expect(event.from.username).toBe('max');
        }
        if ([...expected].every((type) => received.has(type))) {
          clearTimeout(timer);
          resolve(received);
        }
      });
    });

    maxSocket.send(JSON.stringify({ type: 'typing.start', chatId }));
    maxSocket.send(JSON.stringify({ type: 'recording.start', chatId }));
    maxSocket.send(JSON.stringify({ type: 'uploading.stop', chatId }));

    const indicators = await indicatorPromise;
    expect([...expected].every((type) => indicators.has(type))).toBe(true);
    expect(strangerReceived).toBe(false);

    annaSocket.close();
    strangerSocket.close();
    maxSocket.close();
  }, 10000);
});
