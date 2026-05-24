import { GoogleAuth } from 'google-auth-library';
import type { Db } from './db.js';
import type { MessageView } from './types.js';

type ServiceAccount = {
  project_id?: string;
  client_email?: string;
  private_key?: string;
};

function serviceAccountFromEnv(): ServiceAccount | null {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON
    ?? (process.env.FIREBASE_SERVICE_ACCOUNT_JSON_BASE64
      ? Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_JSON_BASE64, 'base64').toString('utf8')
      : undefined);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as ServiceAccount;
  } catch {
    return null;
  }
}

function firebaseProjectId() {
  return process.env.FIREBASE_PROJECT_ID || serviceAccountFromEnv()?.project_id;
}

async function accessToken() {
  const credentials = serviceAccountFromEnv();
  if (!credentials) return null;
  const auth = new GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging']
  });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return token.token ?? null;
}

export function pushConfigured() {
  return Boolean(firebaseProjectId() && serviceAccountFromEnv());
}

export async function sendPushToUsers(db: Db, userIds: string[], message: MessageView, chatId: string) {
  const projectId = firebaseProjectId();
  if (!projectId || !serviceAccountFromEnv()) return;

  const tokens = db.prepare(`
    SELECT token
    FROM push_tokens
    WHERE user_id IN (${userIds.map(() => '?').join(',')})
  `).all(...userIds).map((row: any) => row.token as string);
  if (tokens.length === 0) return;

  const bearer = await accessToken();
  if (!bearer) return;

  await Promise.allSettled(tokens.map(async (token) => {
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${bearer}`,
        'content-type': 'application/json'
      },
      body: JSON.stringify({
        message: {
          token,
          notification: {
            title: message.senderName,
            body: message.text
          },
          data: {
            chatId,
            messageId: message.id,
            senderId: message.senderId
          },
          android: {
            priority: 'HIGH',
            notification: {
              channel_id: 'messages'
            }
          }
        }
      })
    });

    if (response.status === 404 || response.status === 400) {
      db.prepare('DELETE FROM push_tokens WHERE token = ?').run(token);
    }
  }));
}
