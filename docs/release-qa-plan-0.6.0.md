# Release QA Plan 0.6.0

Scope: prepare and verify 0.6.0 locally without creating a commit and without publishing a GitHub release.

## Entry Criteria

- Implementation agents have finished their 0.6.0 work or handed off known gaps.
- Working tree changes are visible for review, but no release commit is required.
- Backend, Flutter, and emulator dependencies are available in the local environment.

## Automated Checks

1. Run backend tests covering messages, attachments, chat state, retry/drafts, unread behavior, and link previews.
2. Run Flutter analyze.
3. Run Flutter tests.
4. Record exact commands, pass/fail status, and any skipped checks in the handoff notes.

## Emulator Scenarios

1. Sign in as two users in separate emulator/device sessions when possible.
2. Send text messages both ways and confirm realtime or refresh behavior.
3. Send a photo, a generic file, and a document.
4. Simulate failed upload or offline mode, reconnect, and retry.
5. Verify typing, recording, and uploading indicators appear and clear.
6. Pin and unpin a chat.
7. Archive a chat and confirm it is reachable from archive state.
8. Verify unread filter behavior before and after opening a chat.
9. Send a URL and confirm rich link preview behavior, including fallback for missing metadata.

## Read-Only Audit

- Review changed files after all agents finish.
- Focus on regressions, incomplete feature wiring, missing tests, and unsafe assumptions.
- Do not edit `apps/**` or `server/**` during this audit unless the owner explicitly expands the scope.

## Exit Criteria

- Required automated checks are passing or documented with clear blockers.
- Manual emulator scenarios are passing or each failure has a reproducible note.
- Deferred features remain tracked in `docs/deferred-features-0.6.0.md`.
- No commit is created and no GitHub release is published.
