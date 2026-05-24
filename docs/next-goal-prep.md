# Next Goal Prep

## Secret File

VPS credentials should be written only to:

```text
C:\Users\rdzio\OneDrive\Documents\My Messenger\secret.env
```

The file is already listed in `.gitignore`. Do not paste passwords, private keys, or tokens into chat. Fill the existing fields:

- `VPS_HOST`
- `VPS_PORT`
- `VPS_USER`
- `VPS_AUTH_METHOD`
- `VPS_PASSWORD` or `VPS_SSH_KEY_PATH`
- `VPS_APP_DIR`
- `VPS_DOMAIN`
- `VPS_PUBLIC_PORT`
- `JWT_SECRET`
- optional TLS fields

## Android Tooling From WebVault

Use the shared WebVault tooling without copying it into this project:

```text
Flutter SDK: C:\Users\rdzio\Tools\flutter
WebVault root: C:\Users\Public\Documents\WebVault
Android SDK: C:\Users\Public\Documents\WebVault\tools\android-sdk
Android AVD home: C:\Users\Public\Documents\WebVault\tools\android-avd
AVD name: WebVault_Pixel_API35
JDK: C:\Users\Public\Documents\WebVault\tools\jdk-17
```

Validated on 2026-05-24:

```text
flutter doctor -v: No issues found
emulator -list-avds: WebVault_Pixel_API35
```

Before Android commands in a new PowerShell session:

```powershell
. .\scripts\android-env.ps1
```

## Next Implementation Scope

- Deploy backend and built Flutter web client to the VPS.
- Add open registration without invite requirement.
- Add settings screen with light/dark theme switch.
- Add settings screen with language choice.
- Persist theme, language, and auth session on web and Android.
- Build and run Android app against the VPS endpoint.
- Use `WebVault_Pixel_API35` emulator for Android registration/login/chat smoke tests.
- Keep all My Messenger notes, scripts, and deployment files in this project folder, not in WebVault.

## Expected Android Test Flow

1. Start or reuse the `WebVault_Pixel_API35` emulator.
2. Install/run the Flutter Android app with the VPS API URL.
3. Register a fresh user with username and password.
4. Confirm auth survives app restart.
5. Add/search a demo or real user.
6. Send a text message.
7. Verify the same message appears in the web UI through the in-app browser.
8. Switch theme and language, restart, and confirm settings persist.
