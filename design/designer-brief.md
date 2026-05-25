# Designer Brief: Premium Telegram-Inspired Messenger

## Goal

Create three distinct visual concepts for My Messenger. The app is a private one-to-one messenger for family use. It should feel familiar to Telegram users, but more premium, calm, and expensive-looking. Avoid flashy effects, decorative blobs, and overcomplicated layouts.

The first deliverable is visual exploration only. Do not change production Flutter code.

## Product Context

- Current app: Flutter client plus Node/Fastify backend.
- Android-first, web remains supported.
- Current public repository: `https://github.com/MaximusStalsky/stalsky-private-messenger`
- Current release line: `0.5.x`
- Existing UI is mostly implemented in `apps/messenger_app/lib/main.dart`.

## Important UI Areas

Read these areas in `apps/messenger_app/lib/main.dart` before designing:

- App theme: around `ThemeData`.
- Main shell and navigation: `AppShell`.
- Chat screen: `ChatPane`.
- Avatars and online status: `UserAvatar`, `PresenceAvatar`.
- Voice call screen: `VoiceCallScreen`.
- Message reactions: `buildReactionPill`.
- Pinned message bar: search for `Pinned message`.

## Concept Requirements

Create three concepts in `design/concepts/`:

1. A premium dark concept inspired by modern Telegram, with richer depth and refined contrast.
2. A light concept that still feels private, polished, and practical.
3. A distinctive third concept with its own palette and mood, still suitable for daily chat use.

Each concept should show at least:

- Mobile chat screen.
- Chat header with back button, avatar, name, online/last seen, call button, menu.
- Pinned message bar.
- Incoming and outgoing bubbles with variable width.
- Reply preview inside a bubble.
- Voice message bubble.
- Reaction pill in Telegram-like style.
- Message time and read ticks.
- Bottom composer with transparent surrounding area and solid/semitransparent inner controls.
- Optional compact chat list/contact list preview.

## Animation Notes

For each concept, include short implementation notes for elegant micro-animations:

- Opening a chat.
- Swipe-to-reply.
- Swipe-back to chat list.
- Message send.
- Reaction menu and selected reaction.
- Pinned bar close/unpin.
- Voice playback progress.

Keep animations subtle and implementable in Flutter.

## Constraints

- Work only under `design/**`.
- Do not edit `apps/**`, `server/**`, `.deploy/**`, `secret.env`, release keys, or deployment files.
- Do not use secrets or private credentials.
- Keep concepts implementable with Flutter widgets, `ThemeData`, and local assets if needed.
- Prefer self-contained HTML/CSS mockups and Markdown handoff notes.
- Use clear design tokens: colors, typography, spacing, radii, shadows, opacity, animation durations.

