# Firebase Push Setup

Full Android background push delivery requires Firebase Cloud Messaging.

The code is already wired:

- Android creates notification channel `messages`.
- Android requests notification permission.
- Android sends its FCM token to `/api/push/tokens` after login.
- Backend stores tokens in SQLite.
- Backend sends FCM v1 notifications to other chat members when a new message is created.
- Tapping a notification opens the app and selects the target chat.

Missing production inputs:

```text
apps\messenger_app\android\app\google-services.json
```

```text
FIREBASE_PROJECT_ID=...
FIREBASE_SERVICE_ACCOUNT_JSON=...
```

How to get them:

1. Create or open a Firebase project.
2. Add an Android app with package name:

```text
org.stalsky.max.messenger
```

3. Download `google-services.json` and place it here:

```text
C:\Users\rdzio\OneDrive\Documents\My Messenger\apps\messenger_app\android\app\google-services.json
```

4. In Firebase/Google Cloud, create a service account key that can send Firebase Cloud Messaging v1 messages.
5. Put the compact one-line service account JSON into:

```text
C:\Users\rdzio\OneDrive\Documents\My Messenger\secret.env
```

Required fields:

```text
FIREBASE_PROJECT_ID=<firebase project id>
FIREBASE_SERVICE_ACCOUNT_JSON=<single-line json>
```

6. Rebuild and reinstall Android APK.
7. Redeploy VPS backend.
8. Check:

```text
https://max.stalsky.org/api/push/status
```

Expected result after server credentials are installed:

```json
{"configured":true}
```
