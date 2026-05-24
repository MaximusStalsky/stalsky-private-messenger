# Local Development

This prototype is split into a Node.js server and a Flutter client. The server stores data in local SQLite and can also serve the built Flutter web app.

## Prerequisites

- Node.js and npm.
- Flutter SDK. In this workspace it is installed at `C:\Users\rdzio\Tools\flutter`; add `C:\Users\rdzio\Tools\flutter\bin` to PATH for each shell.
- Chrome for Flutter web testing.
- Android SDK is not installed yet, so Android builds are a follow-up setup step.

## First Run

1. Start the server:

```powershell
cd server
npm start
```

2. Open the built web app through the server:

```text
http://127.0.0.1:8080
```

3. For Flutter development mode:

```powershell
$env:Path="C:\Users\rdzio\Tools\flutter\bin;$env:Path"
cd apps\messenger_app
flutter run -d chrome --dart-define API_BASE_URL=http://127.0.0.1:8080
```

Keep server and client terminals separate so logs remain readable.

## Suggested Local Ports

These are defaults for QA helpers and documentation only. The implementation may use different ports.

| Service | Default URL |
| --- | --- |
| Full app and API server | `http://127.0.0.1:8080` |
| API health | `http://127.0.0.1:8080/api/health` |

Override these when running QA:

```powershell
.\scripts\qa\run-local-qa.ps1 -WebUrl http://127.0.0.1:8080 -ApiUrl http://127.0.0.1:8080/api/health
```

## Checks

```powershell
cd server
npm run build
npm test

$env:Path="C:\Users\rdzio\Tools\flutter\bin;$env:Path"
cd ..\apps\messenger_app
flutter analyze
flutter test
flutter build web --dart-define API_BASE_URL=http://127.0.0.1:8080
```

## Environment Hygiene

- Keep secrets out of committed files.
- Prefer `.env.local` for developer-specific values.
- Restart the server after changing environment variables.
- Check browser devtools and server logs together when debugging connection failures.

## Common Checks

- App shell loads without a blank screen.
- Create a local invite from the login screen.
- Register two users with the invite.
- Add one user as a contact from the other account.
- Send messages in both directions and refresh to confirm persistence.
- Network failures show a usable error instead of leaving the UI stuck.
