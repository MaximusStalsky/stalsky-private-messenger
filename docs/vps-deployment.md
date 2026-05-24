# VPS Deployment

Production web URL:

```text
https://max.stalsky.org/
```

Android debug APK:

```text
C:\Users\rdzio\OneDrive\Documents\My Messenger\apps\messenger_app\build\app\outputs\flutter-apk\app-debug.apk
```

Server location on VPS:

```text
/opt/my-messenger/app
```

The app runs in Docker and is bound only to `127.0.0.1:8080` on the VPS. Nginx terminates HTTPS on `443` and proxies `max.stalsky.org` to that local port.

Cloudflare changes made:

- Created one DNS `A` record for `max.stalsky.org`.
- Kept it DNS-only, not proxied.
- Did not use Cloudflare Tunnel or Zero Trust.
- Did not change existing tunnel/hostname setup for other services.

VPS changes made:

- Created `/opt/my-messenger`.
- Added `/etc/nginx/sites-available/my-messenger.conf`.
- Enabled `/etc/nginx/sites-enabled/my-messenger.conf`.
- Installed `certbot` and `python3-certbot-nginx` if missing.
- Issued a Let's Encrypt certificate for `max.stalsky.org`.
- Kept the app container on localhost only.

Backups were created under:

```text
/root/my-messenger-backups
```

Useful server commands:

```bash
cd /opt/my-messenger/app
docker compose ps
docker compose logs --tail=100 my-messenger
docker compose up -d --build --force-recreate
```

Validated on 2026-05-24:

- Backend tests: passed.
- Flutter analyze: passed.
- Flutter widget tests: passed.
- Flutter web release build: passed.
- Android debug APK build: passed.
- External HTTPS API registration/login/contact/message flow: passed.
- WebSocket delivery over `wss://max.stalsky.org/ws`: passed.
- Message history after Docker restart: passed.
- Web UI loads over HTTPS and demo chat UI is visible.
- Android emulator opens the app, demo account works, registration works, settings are visible, and auth survives app restart.

Current notification behavior:

Local Android notifications are implemented for incoming WebSocket messages while the app is running.

Firebase Cloud Messaging support has also been wired in:

- Android registers an FCM token after login when Firebase is configured.
- Backend stores tokens in `push_tokens`.
- Backend sends FCM v1 messages to other chat members when a message is created.
- `GET /api/push/status` returns whether server-side Firebase credentials are configured.

To enable full background push delivery, add:

```text
apps\messenger_app\android\app\google-services.json
```

Then fill these VPS environment values in `/opt/my-messenger/app/.env.production`:

```text
FIREBASE_PROJECT_ID=...
FIREBASE_SERVICE_ACCOUNT_JSON=...
```

`FIREBASE_SERVICE_ACCOUNT_JSON` should be the compact single-line JSON for a Firebase service account with permission to send Firebase Cloud Messaging v1 messages. After adding those values, rebuild/redeploy the backend and rebuild/reinstall the Android APK.
