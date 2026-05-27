import type { FastifyRequest } from 'fastify';

export type User = {
  id: string;
  username: string;
  displayName: string;
  avatarUrl?: string | null;
  passwordHash: string;
  lastSeenAt?: string | null;
  createdAt: string;
};

export type AuthedRequest = FastifyRequest & {
  user: User;
};

export type MessageView = {
  id: string;
  chatId: string;
  senderId: string;
  senderName: string;
  type: 'text' | 'voice' | 'photo' | 'file' | 'document';
  text: string;
  mediaUrl: string | null;
  durationMs: number | null;
  filename: string | null;
  mimeType: string | null;
  sizeBytes: number | null;
  thumbnailUrl: string | null;
  attachment?: {
    kind: 'photo' | 'file' | 'document';
    type: 'photo' | 'file' | 'document';
    fileName: string;
    filename: string;
    url: string;
    mediaUrl: string;
    thumbnailUrl: string | null;
    mimeType: string | null;
    sizeBytes: number | null;
  } | null;
  linkPreview: {
    url: string;
    title: string | null;
    description: string | null;
    imageUrl: string | null;
    domain: string;
  } | null;
  replyToMessageId: string | null;
  replyToText: string | null;
  replyToSenderName: string | null;
  replyToType: 'text' | 'voice' | 'photo' | 'file' | 'document' | null;
  deletedAt: string | null;
  editedAt: string | null;
  pinned: 0 | 1 | boolean;
  readByPeer: 0 | 1 | boolean;
  reactions: Array<{
    reaction: string;
    count: number;
    userIds: string[];
  }>;
  createdAt: string;
};
