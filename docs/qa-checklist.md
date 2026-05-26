# QA Checklist

Use this checklist before handing off prototype changes. Mark items as not applicable when a feature is not implemented yet.

## 0.6.0 Release Gate

- Backend tests pass for message, attachment, chat state, offline retry/draft, unread, and link preview behavior.
- Flutter analyze completes without new warnings or errors.
- Flutter unit/widget tests pass.
- Android emulator smoke test uses two signed-in users on separate sessions/devices where possible.
- No GitHub release is created for 0.6.0 unless a later release task explicitly asks for it.

## Startup

- Server starts without fatal errors.
- Client starts without fatal errors.
- Browser can load the client URL.
- Client can reach the server URL.
- Console does not show repeated runtime errors.

## Core Messaging Flow

- Empty state is clear when there are no conversations or messages.
- Existing conversations load, if seeded data exists.
- Selecting a conversation shows the correct messages.
- Sending a text message appends it once.
- Sent messages remain visible after refresh, if persistence is implemented.
- Failed sends show a clear retry or error state.
- Long messages wrap without breaking layout.
- Rapid sends do not duplicate or reorder messages unexpectedly.
- Draft text survives leaving and returning to a chat.
- Offline text sends queue or fail into a recoverable retry state.
- Retry after reconnect sends the intended message once.
- Unread filter shows only conversations with unread messages.
- Unread state clears when the conversation is opened or read, according to implemented rules.

## Attachments And Rich Content

- Photo send works from Android emulator/device and appears in the receiving chat.
- Generic file send works and preserves the expected file name/type.
- Document send works for a common document type such as PDF.
- Upload progress or uploading state is visible while a larger file is being sent.
- Failed upload shows a clear retry/error state.
- Failed upload retry after reconnect sends the attachment once.
- Attachment download/open action is visible and usable on the receiving side.
- Rich link preview is generated for a normal HTTPS URL.
- Link preview degrades cleanly when metadata cannot be fetched.

## Account And Session

- Initial identity, login, or profile setup flow works, if implemented.
- Refresh keeps the expected session state.
- Logout or reset flow clears local state, if implemented.
- Unauthorized API responses return the user to a recoverable state.

## Realtime Or Refresh Behavior

- Incoming messages appear through realtime updates or refresh, depending on current scope.
- Duplicate realtime events do not create duplicate messages.
- Reconnect behavior is visible or recoverable after temporarily stopping the server.
- Typing indicator appears for the other user and clears after send, stop, or timeout.
- Recording indicator appears for the other user while voice recording is active, if voice recording exists in scope.
- Uploading indicator appears for the other user or current conversation while attachment upload is active.

## Chat Organization

- Pinning a chat moves or marks it according to the implemented sort rules.
- Unpinning a chat restores normal ordering.
- Archiving a chat removes it from the default chat list.
- Archived chats remain accessible from the archive view/filter.
- New activity in an archived chat follows the intended unarchive or unread behavior.

## Voice Calls

- 1-on-1 audio call can be started from one Android device or emulator and answered on another signed-in account.
- Android microphone permission prompt appears on first call attempt, and accepting it lets local audio start.
- Call audio works both ways without video surfaces appearing.
- Ending the call on either side returns both users to a usable chat state.
- Bluetooth headset routing works on Android 12+ when Bluetooth permission is granted, if a headset is available.

## Layout

- Main views fit at desktop width.
- Main views fit at mobile width.
- Text does not overlap buttons, headers, or message bubbles.
- Keyboard focus is visible for interactive controls.
- Loading and error states do not shift the layout excessively.

## Accessibility Smoke Test

- Primary actions are reachable by keyboard.
- Inputs have clear labels or accessible names.
- Color alone is not required to understand errors or selected state.
- Screen reader order follows the visible flow.

## Data Safety

- Test data can be reset without manual database surgery, if reset tooling exists.
- No secrets are printed in browser console or server logs.
- Local storage and cookies only contain expected prototype data.

## Final Handoff

- Before every GitHub commit or release, verify `apps/messenger_app/pubspec.yaml` has an Android build number higher than the latest installed/released APK.
- Record the server URL, client URL, and commit or build identifier.
- Record backend test, Flutter analyze, Flutter test, and emulator scenario results.
- Note any skipped checks and why.
- Attach screenshots for any UI issue that remains open.
