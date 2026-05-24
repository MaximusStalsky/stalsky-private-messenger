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
  type: 'text' | 'voice';
  text: string;
  mediaUrl: string | null;
  durationMs: number | null;
  replyToMessageId: string | null;
  replyToText: string | null;
  replyToSenderName: string | null;
  replyToType: 'text' | 'voice' | null;
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
