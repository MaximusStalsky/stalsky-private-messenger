# My Messenger Visual Concepts

These mockups are visual exploration only. They are self-contained HTML/CSS files and do not change production Flutter UI.

## Selected Theme Families

Chosen direction for implementation handoff:
- `Coffee Wood Premium`: `concept-1.html` dark and `concept-2.html` light.
- `Blue Premium`: `concept-blue-dark.html` dark and `concept-blue-light.html` light.

The intended product model is a switchable theme family plus light/dark mode inside that family. The mineral green concept is not selected for the main implementation path.

Expanded full-app mockups:
- `../full-ui-coffeewood.html` covers CoffeeWood chat list, contacts, add contact, settings sheet, profile/avatar, empty states, chat, pinned state, context menu, reactions, and call screen in dark and light.
- `../full-ui-blue.html` covers the same surfaces for Blue Premium in dark and light.

Component and Flutter handoff:
- `../components.md` contains palette/component tokens and notes for mapping the selected design system into Flutter later.

## Concept 1: Coffee Wood Premium Dark

File: `concept-1.html`

Mood: familiar Telegram dark UI with deeper surfaces, glassy app chrome, sharper text contrast, and coffee/wood warmth instead of cold blue depth.

Tokens:
- Palette: app background `#120C08`, phone `#1C130E`, header `rgba(34,23,17,.92)`, incoming `#2A1C14`, outgoing `#7A4B2C` to `#9A6338`, accent `#C99155`, read ticks `#F0C982`, text `#F7EFE6`.
- Typography: system Inter-like stack, 14px message body, 12px status and pinned labels, 11px metadata, 700-800 weight for names.
- Spacing: 12px header padding, 16px message top padding, 8px bubble rhythm, 10px inner bubble horizontal padding.
- Radii: phone 30px, controls 19-24px, bubbles 18px with 6px Telegram-style tail corner, reply preview 9px, reaction pill 14px.
- Shadows: deep warm black phone shadow, low bubble shadow, amber glow only on active action and pinned rail.
- Opacity: header 92%, composer controls 92%, secondary text 70-78%, reply background 10-14%.
- Animation timings: chat/message enter 320-360ms ease-out cubic, swipe-to-reply 120ms, reaction pop 520ms, pinned unpin 360-420ms, voice waveform 1200ms loop.

Pros:
- Closest to current dark Flutter baseline and Telegram mental model.
- Premium without changing core layout, now with warmer private-room character.
- Best fit for evening/private chat use and a more expensive, less generic mood.

Risks:
- Needs careful contrast tuning on lower-end Android displays.
- Coffee/wood palettes can become muddy if too many surfaces use the same brown; keep amber accents sparse and text contrast high.

## Concept 2: Coffee Wood Premium Light

File: `concept-2.html`

Mood: the same coffee wood premium system as Concept 1, translated into a light ivory/latte theme. Layout, density, radii, bubble behavior, and animation language intentionally match the dark version.

Tokens:
- Palette: page `#EFE6DA`, phone `#FBF7F0`, header `rgba(255,250,243,.92)`, incoming `#FFFFFF`, outgoing `#EAD4BC` to `#DFBF9B`, accent `#A76B3D`, read ticks `#9A6338`, text `#2C1C13`.
- Typography: same stack and scale as Concept 1 for direct theme swapping.
- Spacing: same 74px header, 58px pinned bar, 82px composer, 16px message top padding, 8px bubble rhythm.
- Radii: same as Concept 1: phone 30px, controls 19-24px, bubbles 18px with 6px Telegram-style tail corner, reply preview 9px, reaction pill 14px.
- Shadows: warm soft elevation, mostly on phone, bubbles, and composer controls.
- Opacity: header 92%, composer controls 92%, secondary text 58-68%, reply background 9%.
- Animation timings: same as Concept 1: chat/message enter 320-360ms, swipe-to-reply 120ms, reaction pop 520ms, pinned unpin 360-420ms, voice waveform 1200ms loop.

Pros:
- Gives the coffee wood direction a true day mode without changing component behavior.
- Warmer and more premium than a generic white messenger theme.
- Easy to map to Flutter as a paired light `ThemeData` for Concept 1.

Risks:
- Ivory and latte surfaces can look beige if overused; keep incoming bubbles white and use walnut text for contrast.
- Outgoing bubbles need contrast checks on older Android screens.

## Concept 3: Mineral Green

File: `concept-3.html`

Mood: distinct daily-use palette: mineral green, warm coral action color, off-white surfaces. It avoids a one-note blue/purple/slate/beige feel while staying calm.

Tokens:
- Palette: outer page `#18201D`, phone `#F3F4EF`, text `#18201D`, muted `#687269`, incoming `#FFFFFF`, outgoing `#D8EEE6`, accent `#2F8F7A`, action/coral `#D05F45`.
- Typography: same scale as other concepts, with strong 760-weight chat name.
- Spacing: same 74px header, 58px pinned bar, 82px composer, 8px message rhythm.
- Radii: Telegram-like 18px bubbles with 6px tail corner, 24px composer, 19px icon buttons.
- Shadows: green-gray elevation, subtle enough for daily use.
- Opacity: header 90%, pinned 84%, reply 10%, input 86%, metadata muted.
- Animation timings: message enter 340ms, pinned 380ms, reaction 460ms, voice waveform 1250ms.

Pros:
- Distinctive and premium without relying on dark blue or purple.
- Warm send button creates a clear primary action.
- Good candidate for a secondary theme after the main redesign.

Risks:
- Further validation needed with actual avatars and media thumbnails.
- Coral action color must be reserved for primary actions to avoid noise.

## Additional Variant: Blue Premium Light

File: `concept-blue-light.html`

Mood: the original dark premium Telegram-inspired blue direction translated into a light theme, using the same structure and component styling as the paired coffee wood work.

Tokens:
- Palette: page `#EAF2F8`, phone `#F8FBFD`, header `rgba(255,255,255,.92)`, incoming `#FFFFFF`, outgoing `#CFEEFF` to `#ACDFF9`, accent `#229ED9`, deep accent `#1777A8`, text `#142536`.
- Typography: same 14px message body, 12px status/pinned labels, 11px metadata, 750-weight chat name.
- Spacing: same 74px header, 58px pinned bar, 82px composer, 16px message top padding, 8px bubble rhythm.
- Radii: same 30px phone, 19-24px controls, 18px bubbles with 6px tail corner, 9px reply preview, 14px reaction pill.
- Shadows: soft blue-gray elevation, with restrained blue glow on send action and pinned rail.
- Opacity: header 92%, composer controls 92%, secondary text 58-68%, reply background 9%.
- Animation timings: same as Concept 1 and Concept 2 for easy Flutter reuse.

Pros:
- Keeps the modern Telegram-like blue identity while avoiding a generic flat white UI.
- Works as a direct light companion to the initial blue dark premium concept.
- Uses the same component system as the coffee wood pair, so implementation stays simple.

Risks:
- Blue can feel less distinctive than coffee wood unless depth and spacing stay polished.
- Outgoing blue bubbles need contrast checks in bright sunlight.

## Additional Variant: Blue Premium Dark

File: `concept-blue-dark.html`

Mood: the original premium dark Telegram-inspired blue direction, preserved as the dark pair for `concept-blue-light.html`.

Tokens:
- Palette: app background `#080C11`, phone `#111923`, header `rgba(18,27,38,.92)`, incoming `#1D2A36`, outgoing `#246F9F` to `#2E86BD`, accent `#45B7F0`, read ticks `#9BE2FF`.
- Typography, spacing, radii, shadows, opacity, and animation timings match the shared premium messenger component system.

Use:
- Pair with `concept-blue-light.html` as the selected blue theme family.

## Animation Handoff Notes

- Chat open: slide chat pane 16-24px from right with 180-220ms easeOutCubic; fade header and pinned bar in 80ms after start.
- Swipe-to-reply: translate the active bubble up to 48-56px, reveal a reply arrow behind it, haptic at 34px, snap back in 120ms.
- Swipe-back: whole chat pane tracks finger horizontally; trigger on velocity above current Flutter threshold, dim chat list underneath on wide/web.
- Message send: composer send button compresses to 94%, new bubble enters from bottom/right over 220-320ms, then read ticks fade in.
- Reaction menu: bottom sheet or anchored pill tray scales from 92% to 100%; selected reaction pops once and settles inside the bubble.
- Pinned unpin: pinned bar collapses height from 58px to 0 with opacity fade over 220-280ms.
- Voice playback: waveform bars animate with low amplitude, progress tint advances left-to-right, play button crossfades to pause over 120ms.

## Recommendation

Selected implementation direction: build two switchable theme families. `Coffee Wood Premium` uses `concept-1.html` for dark and `concept-2.html` for light. `Blue Premium` uses `concept-blue-dark.html` for dark and `concept-blue-light.html` for light. Concept 3 is retained as exploration only, not part of the selected main path.
