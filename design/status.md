# Design Status

Designer subagent visual concept and design-system pass completed.

Current scope:

- Produce three premium Telegram-inspired visual concepts.
- Save all outputs under `design/concepts/`.
- Do not modify production Flutter or backend code.

Completed files:

- `design/concepts/concept-1.html` - coffee wood premium dark Telegram-inspired mobile chat mockup.
- `design/concepts/concept-2.html` - coffee wood premium light mobile chat mockup matching Concept 1's layout and component style.
- `design/concepts/concept-3.html` - distinct mineral green/coral daily-use mobile chat mockup.
- `design/concepts/concept-blue-dark.html` - blue premium dark companion for the selected blue theme family.
- `design/concepts/concept-blue-light.html` - blue premium light companion for the original dark blue premium direction.
- `design/full-ui-coffeewood.html` - expanded CoffeeWood Premium full-app mockup covering chat list, contacts, add contact, settings, profile/avatar, empty states, chat, pinned state, context menu, reactions, and call screen in dark and light.
- `design/full-ui-blue.html` - expanded Blue Premium full-app mockup covering the same surfaces in dark and light.
- `design/components.md` - component tokens, palette mapping, and Flutter handoff notes for `AppPalette` / `AppStyle` and `main.dart` recoloring.
- `design/concepts/README.md` - concept descriptions, design tokens, animation handoff notes, pros, risks, and recommendation.

Recommendation:

Selected direction is two switchable theme families:

- Coffee Wood Premium: `concept-1.html` dark and `concept-2.html` light.
- Blue Premium: `concept-blue-dark.html` dark and `concept-blue-light.html` light.

The main app should eventually expose theme family selection plus light/dark mode inside that family. Concept 3 is retained only as exploration and is not selected for the main implementation path.

Flutter handoff summary:

- Add a persisted style-family setting for CoffeeWood Premium / Blue Premium beside existing light/dark mode.
- Extract palette tokens into an `AppPalette` and shared dimensions/motion into `AppStyle`.
- Recolor `ThemeData`, `AppShell`, `Sidebar`, `UserAvatar`, `PresenceAvatar`, `ChatPane`, pinned bar, message bubbles, composer, reaction/context menus, settings sheets, and `VoiceCallScreen` using those tokens.
- Keep implementation Android-first and avoid production changes until the main coding pass.
