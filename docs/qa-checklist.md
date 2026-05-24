# QA Checklist

Use this checklist before handing off prototype changes. Mark items as not applicable when a feature is not implemented yet.

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

## Account And Session

- Initial identity, login, or profile setup flow works, if implemented.
- Refresh keeps the expected session state.
- Logout or reset flow clears local state, if implemented.
- Unauthorized API responses return the user to a recoverable state.

## Realtime Or Refresh Behavior

- Incoming messages appear through realtime updates or refresh, depending on current scope.
- Duplicate realtime events do not create duplicate messages.
- Reconnect behavior is visible or recoverable after temporarily stopping the server.

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

- Record the server URL, client URL, and commit or build identifier.
- Note any skipped checks and why.
- Attach screenshots for any UI issue that remains open.
