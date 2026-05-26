# Deferred Features For 0.6.0

These features are intentionally out of the 0.6.0 release scope. Keep them visible for planning, but do not block 0.6.0 QA on them.

## Saved/Starred Messages

- Deferred because 0.6.0 is focused on core attachment, chat state, offline recovery, and preview flows.
- Needs product decisions for saved vs starred semantics, per-user visibility, search/filter behavior, and sync rules.
- Suggested next step: define the message metadata model and UI entry points after 0.6.0 stabilizes.

## Chat Lock

- Deferred because it adds privacy, authentication, and recovery edge cases that should not be mixed into the 0.6.0 messaging surface.
- Needs decisions for PIN/biometric support, lock timeout, notification redaction, backup/restore behavior, and failed unlock handling.
- Suggested next step: write a security and UX spec before implementation.

## Voice UX Improvements

- Deferred because 0.6.0 only needs basic recording/indicator coverage, not a complete advanced voice experience.
- Includes waveform polish, scrubber behavior, pause/resume recording, playback speed, drafts for recordings, and advanced permission recovery.
- Suggested next step: split voice work into separate recording, playback, and accessibility tasks.

## Notification Settings

- Deferred because notification preferences require durable settings, push delivery assumptions, and platform-specific QA.
- Needs decisions for per-chat mute, global notification toggles, preview redaction, sound/vibration, and quiet hours.
- Suggested next step: align notification settings with the push notification implementation plan.

## Location Sharing

- Deferred because location introduces permission, privacy, map/provider, accuracy, and retention requirements.
- Needs decisions for live vs static location, expiry, map rendering, reverse geocoding, and abuse controls.
- Suggested next step: create a separate privacy review and platform permission checklist.
