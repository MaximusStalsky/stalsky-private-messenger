# My Messenger Component System Handoff

This is design-only guidance. Do not treat this file as an implementation change request by itself.

## Selected Theme Model

The selected product model is two independent user choices:

- Style family: `CoffeeWood Premium` or `Blue Premium`.
- Brightness: `Light` or `Dark`.

Implementation should avoid hardcoding colors directly in widgets. Prefer a small `AppPalette` plus `AppStyle` layer that can be selected from `(styleFamily, brightness)`.

## Palette Tokens

### CoffeeWood Premium Dark

- `appBackground`: `#120C08`
- `chatBackground`: `#1C130E`
- `surface`: `rgba(34,23,17,.92)`
- `surfaceSoft`: `rgba(45,31,23,.88)`
- `surfaceRaised`: `rgba(61,42,31,.82)`
- `textPrimary`: `#F7EFE6`
- `textMuted`: `#B8A99A`
- `divider`: `rgba(255,239,222,.09)`
- `accent`: `#C99155`
- `accentStrong`: `#E5B977`
- `bubbleIncoming`: `#2A1C14`
- `bubbleOutgoingStart`: `#7A4B2C`
- `bubbleOutgoingEnd`: `#9A6338`
- `danger`: `#D7765F`

### CoffeeWood Premium Light

- `appBackground`: `#EFE6DA`
- `chatBackground`: `#FBF7F0`
- `surface`: `rgba(255,250,243,.92)`
- `surfaceSoft`: `rgba(255,250,243,.88)`
- `surfaceRaised`: `rgba(243,232,218,.84)`
- `textPrimary`: `#2C1C13`
- `textMuted`: `#8C7A68`
- `divider`: `rgba(87,55,34,.11)`
- `accent`: `#A76B3D`
- `accentStrong`: `#7A4B2C`
- `bubbleIncoming`: `#FFFFFF`
- `bubbleOutgoingStart`: `#EAD4BC`
- `bubbleOutgoingEnd`: `#DFBF9B`
- `danger`: `#B8553E`

### Blue Premium Dark

- `appBackground`: `#080C11`
- `chatBackground`: `#111923`
- `surface`: `rgba(18,27,38,.92)`
- `surfaceSoft`: `rgba(25,36,49,.88)`
- `surfaceRaised`: `rgba(32,45,61,.82)`
- `textPrimary`: `#EEF5FB`
- `textMuted`: `#8EA0AF`
- `divider`: `rgba(255,255,255,.08)`
- `accent`: `#45B7F0`
- `accentStrong`: `#7ED7FF`
- `bubbleIncoming`: `#1D2A36`
- `bubbleOutgoingStart`: `#246F9F`
- `bubbleOutgoingEnd`: `#2E86BD`
- `danger`: `#D65F6A`

### Blue Premium Light

- `appBackground`: `#EAF2F8`
- `chatBackground`: `#F8FBFD`
- `surface`: `rgba(255,255,255,.92)`
- `surfaceSoft`: `rgba(255,255,255,.88)`
- `surfaceRaised`: `rgba(229,242,250,.84)`
- `textPrimary`: `#142536`
- `textMuted`: `#6B7F90`
- `divider`: `rgba(20,37,54,.10)`
- `accent`: `#229ED9`
- `accentStrong`: `#1777A8`
- `bubbleIncoming`: `#FFFFFF`
- `bubbleOutgoingStart`: `#CFEEFF`
- `bubbleOutgoingEnd`: `#ACDFF9`
- `danger`: `#C94F5B`

## Component Tokens

### App Background

- Root scaffold uses `appBackground`.
- Chat pane/message area uses `chatBackground`.
- Keep subtle texture optional. In Flutter this can be skipped at first; use flat color plus depth from surfaces and shadows.

### Sidebar and Lists

- Sidebar/list surface: `chatBackground`.
- Search field: `surfaceSoft`, 42px height, 21px radius.
- Chat/contact row: 62px minimum height, 10px horizontal inner gap, 15px radius.
- Active row: `accent` at 14-18% opacity, no heavy border.
- Last message/status text: `textMuted`, 12px.
- Timestamp: `textMuted`, 11px.
- Divider: prefer spacing over full-width lines; use `divider` only between major regions.

### Chat Header

- Height: 68-74px.
- Background: `surface` at about 92% opacity.
- Border bottom: `divider`.
- Back/call/menu buttons: 36-38px circles.
- Filled call button: `accent` at 12-16% opacity, icon `accentStrong`.

### Pinned Bar

- Height: 56-58px.
- Background: `surfaceRaised`.
- Left rail: 3px wide, 38-40px tall, 6px radius, color `accent`.
- Label: 12px, 700 weight, `accentStrong`.
- Body preview: 13px, `textMuted`, single-line ellipsis.
- Unpin/close action stays transparent until pressed.

### Message Bubbles

- Max width: 78% of chat width on mobile.
- Padding: 8px top/bottom, 10-12px horizontal.
- Radius: 18px, with Telegram-like tail corner 6px on bottom-left for incoming and bottom-right for outgoing.
- Incoming bubble: `bubbleIncoming`, subtle `divider` border.
- Outgoing bubble: gradient from `bubbleOutgoingStart` to `bubbleOutgoingEnd`.
- Reply preview: 9px radius, 3px left rail in `accent` or `accentStrong`, background `accent` at 9-11% opacity.
- Metadata: 11px, `textMuted`; read ticks use `accent`/`accentStrong`.

### Composer

- Outer composer area stays transparent with a bottom fade from `appBackground`.
- Input control: 48px height, 24px radius, `surface`, `divider` border.
- Send/mic button: 48px circle, gradient based on `accent` to darker family-specific accent.
- Composer icons use `textMuted` until active.

### Modal Settings and Sheets

- Sheet/card radius: 18-22px.
- Background: `surface`.
- Border: `divider`.
- Elevation: soft, family-tinted shadow.
- Row height: 42-48px.
- Theme controls use segmented controls:
  - Style segment: `CoffeeWood` / `Blue`.
  - Brightness segment: `Light` / `Dark`.
- Active segment: `surfaceSoft` over `surfaceRaised`, text `accentStrong`.

### Segmented Controls

- Container radius: 18px, padding 3px.
- Active segment radius: 15px.
- Container background: `surfaceRaised`.
- Active background: `surfaceSoft`.
- Inactive text: `textMuted`.
- Active text: `accentStrong`, 700 weight.

### Buttons

- Icon buttons: 36-38px circular hit target.
- Primary circular action: 48px, filled with accent gradient, white foreground.
- Destructive call/end/delete action: `danger`, white foreground.
- Text actions in rows use `accentStrong`.

### Dividers

- Use `divider` only at header bottom, pinned bottom, sheet row separators, and major sidebar boundaries.
- Avoid full card grids or nested cards; keep app surfaces utilitarian.

### Online Ring and Avatars

- Avatar size: 40-42px in headers, 34px in lists, 72px in profile/call screen.
- Online ring: 2px accent ring plus 2-3px outer soft glow.
- Avatar gradient should follow style family:
  - CoffeeWood: amber to walnut.
  - Blue: cyan to deep blue.

### Reactions and Context Menu

- Reaction pill radius: 14px, 2px vertical padding, 6px horizontal padding.
- Reaction background: `surface` or `accent` at 10-14% opacity.
- Reaction border: `accent` at 20-28% opacity.
- Context menu radius: 16px, background `surface`, border `divider`, row radius 11px, row height about 38px.
- Menu items: Reply, React, Pin/Unpin, Copy, Edit where allowed, Select, Delete.

### Empty States

- Use simple centered copy, not illustration-heavy screens.
- Container can be dashed `textMuted` at 30-35% opacity, radius 18px.
- Empty copy: 13-14px, `textMuted`, max two lines.

### Call Screen

- Full-screen call state uses `appBackground` or `chatBackground`.
- Avatar: 72-112px depending screen size.
- Controls: circular 52px actions, active/selected states use `accent` at 16-24% opacity.
- End call: `danger`.

## Flutter Handoff Notes

### Suggested Data Structures

Add a style-family enum beside existing brightness handling:

```dart
enum AppThemeFamily { coffeeWoodPremium, bluePremium }
```

Suggested palette object:

```dart
class AppPalette {
  final Color appBackground;
  final Color chatBackground;
  final Color surface;
  final Color surfaceSoft;
  final Color surfaceRaised;
  final Color textPrimary;
  final Color textMuted;
  final Color divider;
  final Color accent;
  final Color accentStrong;
  final Color bubbleIncoming;
  final Color bubbleOutgoingStart;
  final Color bubbleOutgoingEnd;
  final Color danger;
}
```

Suggested style object:

```dart
class AppStyle {
  final AppPalette palette;
  final BorderRadius bubbleIncomingRadius;
  final BorderRadius bubbleOutgoingRadius;
  final BorderRadius controlRadius;
  final Duration fastMotion;
  final Duration normalMotion;
}
```

### Widgets in `apps/messenger_app/lib/main.dart` to Recolor

- `ThemeData theme(Brightness brightness)`: replace single seed-only theme with palette-driven `ColorScheme`.
- `AppShell`: apply `appBackground` to the root scaffold and keep wide-layout divider from `palette.divider`.
- `Sidebar`: use `chatBackground`, `surfaceSoft` search fields, active row state, segmented style/brightness controls.
- `UserAvatar` and `PresenceAvatar`: derive avatar fallback gradient/ring from `palette.accent` and `palette.accentStrong`.
- `ChatPane`: apply palette to chat header, pinned bar, message list background, composer, reply/edit bars, selection/highlight states.
- `buildReplyPreview`: use `accent` left rail and `accent` low-opacity background.
- `buildVoiceMessage`: use family-specific play button, waveform, duration text, and upload state.
- `messageMeta`: use `textMuted` and accent read ticks.
- `buildReactionPill`: use reaction background/border tokens.
- Pinned message bar: use `surfaceRaised`, `accent` rail, `accentStrong` label.
- Message context menu and reaction bottom sheet: use `surface`, `divider`, `controlRadius`, and accent selected states.
- `VoiceCallScreen`: use `appBackground`, large avatar treatment, circular call controls, `danger` end button.

### Implementation Notes

- Keep `ThemeMode` for light/dark, but add a persisted `AppThemeFamily` setting for `CoffeeWood Premium` / `Blue Premium`.
- The settings sheet should expose two segmented controls: style family and brightness.
- Avoid scattering `const Color(...)` in widget build methods. Move current hardcoded blues like `0xFF229ED9`, `0xFF54B7F3`, `0xFF2D83BD`, and scaffold colors into the palette.
- Gradients can start with outgoing bubbles and primary action buttons. If Flutter implementation needs a smaller first pass, use solid `bubbleOutgoingEnd` and add gradients later.
- Preserve current Android-first spacing and gestures. The design changes are mostly color, surface, radius, shadow, and control-state changes, not navigation changes.
