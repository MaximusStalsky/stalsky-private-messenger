import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (await initFirebaseIfPossible()) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(const MyMessengerApp());
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await initFirebaseIfPossible();
}

Future<bool> initFirebaseIfPossible() async {
  if (kIsWeb) return false;
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    return true;
  } catch (_) {
    return false;
  }
}

enum AppLanguage { en, ru }

enum AppThemeStyle { coffeeWood, bluePremium }

enum AttachmentKind { photo, file, document }

enum MessageDeliveryState { sent, sending, failed }

enum ChatActivityKind { typing, recording, uploading }

enum ChatListFilter { active, unread, archived }

// TODO(0.6+): saved/starred messages, chat lock, advanced voice UX,
// notification settings, and location sharing.

extension AppThemeStyleLabel on AppThemeStyle {
  String get storageKey {
    switch (this) {
      case AppThemeStyle.coffeeWood:
        return 'coffee_wood';
      case AppThemeStyle.bluePremium:
        return 'blue_premium';
    }
  }

  String get label {
    switch (this) {
      case AppThemeStyle.coffeeWood:
        return 'CoffeeWood';
      case AppThemeStyle.bluePremium:
        return 'Blue Premium';
    }
  }

  static AppThemeStyle fromStorage(String? value) {
    return value == AppThemeStyle.coffeeWood.storageKey
        ? AppThemeStyle.coffeeWood
        : AppThemeStyle.bluePremium;
  }
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.appBackground,
    required this.panel,
    required this.panelAlt,
    required this.header,
    required this.pinned,
    required this.composer,
    required this.input,
    required this.incomingBubble,
    required this.outgoingBubbleStart,
    required this.outgoingBubble,
    required this.selectedRow,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textMuted,
    required this.textOnOutgoing,
    required this.onlineRing,
    required this.divider,
    required this.reaction,
    required this.danger,
  });

  final Color appBackground;
  final Color panel;
  final Color panelAlt;
  final Color header;
  final Color pinned;
  final Color composer;
  final Color input;
  final Color incomingBubble;
  final Color outgoingBubbleStart;
  final Color outgoingBubble;
  final Color selectedRow;
  final Color accent;
  final Color accentSoft;
  final Color textPrimary;
  final Color textMuted;
  final Color textOnOutgoing;
  final Color onlineRing;
  final Color divider;
  final Color reaction;
  final Color danger;

  Color get chatBackground => panel;
  Color get surface => header;
  Color get surfaceSoft => input;
  Color get surfaceRaised => pinned;
  Color get accentStrong => onlineRing;

  LinearGradient get outgoingGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [outgoingBubbleStart, outgoingBubble],
  );

  LinearGradient get actionGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, outgoingBubble],
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>()!;
  }

  static AppPalette resolve(AppThemeStyle style, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (style) {
      case AppThemeStyle.coffeeWood:
        return dark
            ? const AppPalette(
                appBackground: Color(0xFF120C08),
                panel: Color(0xFF1C130E),
                panelAlt: Color(0xFF241911),
                header: Color(0xEB221711),
                pinned: Color(0xD72B1D14),
                composer: Color(0x1AF7EFE6),
                input: Color(0xEA241911),
                incomingBubble: Color(0xFF2A1C14),
                outgoingBubbleStart: Color(0xFF7A4B2C),
                outgoingBubble: Color(0xFF865330),
                selectedRow: Color(0x30A76B3D),
                accent: Color(0xFFC99155),
                accentSoft: Color(0x33C99155),
                textPrimary: Color(0xFFF7EFE6),
                textMuted: Color(0xFFB8A99A),
                textOnOutgoing: Color(0xFFFFFFFF),
                onlineRing: Color(0xFFE5B977),
                divider: Color(0x24F7EFE6),
                reaction: Color(0xE738271B),
                danger: Color(0xFFD7765F),
              )
            : const AppPalette(
                appBackground: Color(0xFFEFE6DA),
                panel: Color(0xFFFBF7F0),
                panelAlt: Color(0xFFF2E7D9),
                header: Color(0xEBFFFAF3),
                pinned: Color(0xEFFFF5EA),
                composer: Color(0x22FFFFFF),
                input: Color(0xF4FFFFFF),
                incomingBubble: Color(0xFFFFFFFF),
                outgoingBubbleStart: Color(0xFFEAD4BC),
                outgoingBubble: Color(0xFFE3C4A4),
                selectedRow: Color(0x30A76B3D),
                accent: Color(0xFFA76B3D),
                accentSoft: Color(0x28A76B3D),
                textPrimary: Color(0xFF2C1C13),
                textMuted: Color(0xFF8C7A68),
                textOnOutgoing: Color(0xFF2C1C13),
                onlineRing: Color(0xFF7A4B2C),
                divider: Color(0x242C1C13),
                reaction: Color(0xF4FFF4E7),
                danger: Color(0xFFB8553E),
              );
      case AppThemeStyle.bluePremium:
        return dark
            ? const AppPalette(
                appBackground: Color(0xFF080C11),
                panel: Color(0xFF111923),
                panelAlt: Color(0xFF192431),
                header: Color(0xEB121B26),
                pinned: Color(0xFF202D3D),
                composer: Color(0x00000000),
                input: Color(0xEB121B26),
                incomingBubble: Color(0xFF1D2A36),
                outgoingBubbleStart: Color(0xFF246F9F),
                outgoingBubble: Color(0xFF2E86BD),
                selectedRow: Color(0x332D83BD),
                accent: Color(0xFF45B7F0),
                accentSoft: Color(0x3345B7F0),
                textPrimary: Color(0xFFEEF5FB),
                textMuted: Color(0xFF8EA0AF),
                textOnOutgoing: Color(0xFFFFFFFF),
                onlineRing: Color(0xFF7ED7FF),
                divider: Color(0x24F4FAFF),
                reaction: Color(0xE7233446),
                danger: Color(0xFFD65F6A),
              )
            : const AppPalette(
                appBackground: Color(0xFFEAF2F8),
                panel: Color(0xFFF8FBFD),
                panelAlt: Color(0xFFEAF4FB),
                header: Color(0xEBFFFFFF),
                pinned: Color(0xEFF1FAFF),
                composer: Color(0x22FFFFFF),
                input: Color(0xF4FFFFFF),
                incomingBubble: Color(0xFFFFFFFF),
                outgoingBubbleStart: Color(0xFFCFEEFF),
                outgoingBubble: Color(0xFFB9E5FB),
                selectedRow: Color(0x2E229ED9),
                accent: Color(0xFF229ED9),
                accentSoft: Color(0x28229ED9),
                textPrimary: Color(0xFF142536),
                textMuted: Color(0xFF6B7F90),
                textOnOutgoing: Color(0xFF142536),
                onlineRing: Color(0xFF1777A8),
                divider: Color(0x22142536),
                reaction: Color(0xF4E9F7FF),
                danger: Color(0xFFC94F5B),
              );
    }
  }

  @override
  AppPalette copyWith({
    Color? appBackground,
    Color? panel,
    Color? panelAlt,
    Color? header,
    Color? pinned,
    Color? composer,
    Color? input,
    Color? incomingBubble,
    Color? outgoingBubbleStart,
    Color? outgoingBubble,
    Color? selectedRow,
    Color? accent,
    Color? accentSoft,
    Color? textPrimary,
    Color? textMuted,
    Color? textOnOutgoing,
    Color? onlineRing,
    Color? divider,
    Color? reaction,
    Color? danger,
  }) {
    return AppPalette(
      appBackground: appBackground ?? this.appBackground,
      panel: panel ?? this.panel,
      panelAlt: panelAlt ?? this.panelAlt,
      header: header ?? this.header,
      pinned: pinned ?? this.pinned,
      composer: composer ?? this.composer,
      input: input ?? this.input,
      incomingBubble: incomingBubble ?? this.incomingBubble,
      outgoingBubbleStart: outgoingBubbleStart ?? this.outgoingBubbleStart,
      outgoingBubble: outgoingBubble ?? this.outgoingBubble,
      selectedRow: selectedRow ?? this.selectedRow,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textOnOutgoing: textOnOutgoing ?? this.textOnOutgoing,
      onlineRing: onlineRing ?? this.onlineRing,
      divider: divider ?? this.divider,
      reaction: reaction ?? this.reaction,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      appBackground: Color.lerp(appBackground, other.appBackground, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelAlt: Color.lerp(panelAlt, other.panelAlt, t)!,
      header: Color.lerp(header, other.header, t)!,
      pinned: Color.lerp(pinned, other.pinned, t)!,
      composer: Color.lerp(composer, other.composer, t)!,
      input: Color.lerp(input, other.input, t)!,
      incomingBubble: Color.lerp(incomingBubble, other.incomingBubble, t)!,
      outgoingBubbleStart: Color.lerp(
        outgoingBubbleStart,
        other.outgoingBubbleStart,
        t,
      )!,
      outgoingBubble: Color.lerp(outgoingBubble, other.outgoingBubble, t)!,
      selectedRow: Color.lerp(selectedRow, other.selectedRow, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnOutgoing: Color.lerp(textOnOutgoing, other.textOnOutgoing, t)!,
      onlineRing: Color.lerp(onlineRing, other.onlineRing, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      reaction: Color.lerp(reaction, other.reaction, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

List<BoxShadow> premiumShadow(AppPalette palette, {double opacity = 0.16}) {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: opacity),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
  ];
}

class PremiumIconButton extends StatelessWidget {
  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 21),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(38),
        backgroundColor: filled ? palette.accentSoft : Colors.transparent,
        foregroundColor: filled ? palette.accentStrong : palette.textPrimary,
        disabledForegroundColor: palette.textMuted.withValues(alpha: 0.55),
      ),
    );
  }
}

class PremiumSearchField extends StatelessWidget {
  const PremiumSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        style: TextStyle(color: palette.textPrimary, fontSize: 14),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: palette.textMuted, fontSize: 14),
          labelText: null,
          prefixIcon: Icon(Icons.search, color: palette.textMuted, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 13),
          filled: true,
          fillColor: palette.surfaceSoft,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(21),
            borderSide: BorderSide(color: palette.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(21),
            borderSide: BorderSide(color: palette.accent, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class PremiumActionCircle extends StatelessWidget {
  const PremiumActionCircle({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.danger = false,
    this.gradient = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool danger;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient || danger ? null : palette.surfaceRaised,
        gradient: gradient
            ? palette.actionGradient
            : danger
            ? LinearGradient(colors: [palette.danger, palette.danger])
            : null,
        boxShadow: premiumShadow(palette, opacity: 0.10),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(48),
          foregroundColor: gradient || danger
              ? Colors.white
              : palette.textPrimary,
        ),
      ),
    );
  }
}

class PremiumSegmented<T> extends StatelessWidget {
  const PremiumSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onChanged,
    this.iconFor,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelFor;
  final IconData? Function(T value)? iconFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: values.map((value) {
          final active = value == selected;
          final icon = iconFor?.call(value);
          return Flexible(
            fit: FlexFit.tight,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: active ? palette.surfaceSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: active
                      ? premiumShadow(palette, opacity: 0.08)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 16,
                        color: active
                            ? palette.accentStrong
                            : palette.textMuted,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        labelFor(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? palette.accentStrong
                              : palette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AppStrings {
  AppStrings(this.language);
  final AppLanguage language;

  String get appName => 'My Messenger';
  String get login => language == AppLanguage.ru ? 'Войти' : 'Login';
  String get register =>
      language == AppLanguage.ru ? 'Регистрация' : 'Register';
  String get username =>
      language == AppLanguage.ru ? 'Имя пользователя' : 'Username';
  String get password => language == AppLanguage.ru ? 'Пароль' : 'Password';
  String get createAccount =>
      language == AppLanguage.ru ? 'Создать аккаунт' : 'Create account';
  String get openDemo =>
      language == AppLanguage.ru ? 'Открыть демо' : 'Open demo account';
  String get chats => language == AppLanguage.ru ? 'Чаты' : 'Chats';
  String get contacts => language == AppLanguage.ru ? 'Контакты' : 'Contacts';
  String get settings => language == AppLanguage.ru ? 'Настройки' : 'Settings';
  String get logout => language == AppLanguage.ru ? 'Выйти' : 'Logout';
  String get refresh => language == AppLanguage.ru ? 'Обновить' : 'Refresh';
  String get findUsername =>
      language == AppLanguage.ru ? 'Найти пользователя' : 'Find username';
  String get noContacts =>
      language == AppLanguage.ru ? 'Контактов пока нет' : 'No contacts yet';
  String get addContactToStart => language == AppLanguage.ru
      ? 'Добавьте контакт, чтобы начать чат'
      : 'Add a contact to start chatting';
  String get addDemoChats =>
      language == AppLanguage.ru ? 'Добавить демо-чаты' : 'Add demo chats';
  String get selectChat =>
      language == AppLanguage.ru ? 'Выберите чат' : 'Select a chat';
  String get message => language == AppLanguage.ru ? 'Сообщение' : 'Message';
  String get send => language == AppLanguage.ru ? 'Отправить' : 'Send';
  String get theme => language == AppLanguage.ru ? 'Тема' : 'Theme';
  String get light => language == AppLanguage.ru ? 'Светлая' : 'Light';
  String get dark => language == AppLanguage.ru ? 'Темная' : 'Dark';
  String get languageLabel => language == AppLanguage.ru ? 'Язык' : 'Language';
  String get english => language == AppLanguage.ru ? 'Английский' : 'English';
  String get russian => language == AppLanguage.ru ? 'Русский' : 'Russian';
  String get close => language == AppLanguage.ru ? 'Закрыть' : 'Close';
  String get deleteAccount =>
      language == AppLanguage.ru ? 'Удалить мой аккаунт' : 'Delete my account';
  String get incomingMessage =>
      language == AppLanguage.ru ? 'Новое сообщение' : 'New message';
  String get voiceCall => 'Voice call';
  String get calling => 'Calling';
  String get incomingCall => 'Incoming call';
  String get connectingCall => 'Connecting';
  String get callActive => 'Call active';
  String get call => 'Call';
  String get answer => 'Answer';
  String get decline => 'Decline';
  String get endCall => 'End call';
  String get mute => 'Mute';
  String get unmute => 'Unmute';
  String get speaker => 'Speaker';
  String get earpiece => 'Phone';
  String get bluetooth => 'Bluetooth';
  String get changeAvatar => 'Change photo';
}

class MyMessengerApp extends StatefulWidget {
  const MyMessengerApp({super.key});

  @override
  State<MyMessengerApp> createState() => _MyMessengerAppState();
}

class _MyMessengerAppState extends State<MyMessengerApp> {
  ThemeMode themeMode = ThemeMode.light;
  AppThemeStyle appStyle = AppThemeStyle.bluePremium;
  AppLanguage language = AppLanguage.en;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme_mode') ?? 'light';
    final style = prefs.getString('theme_style');
    final lang = prefs.getString('language') ?? 'en';
    setState(() {
      themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      appStyle = AppThemeStyleLabel.fromStorage(style);
      language = lang == 'ru' ? AppLanguage.ru : AppLanguage.en;
      loaded = true;
    });
  }

  Future<void> setThemeMode(ThemeMode value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      value == ThemeMode.dark ? 'dark' : 'light',
    );
    setState(() => themeMode = value);
  }

  Future<void> setAppStyle(AppThemeStyle value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_style', value.storageKey);
    setState(() => appStyle = value);
  }

  Future<void> setLanguage(AppLanguage value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value == AppLanguage.ru ? 'ru' : 'en');
    setState(() => language = value);
  }

  ThemeData theme(Brightness brightness) {
    final palette = AppPalette.resolve(appStyle, brightness);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
        surface: palette.chatBackground,
        primary: palette.accent,
        error: palette.danger,
      ),
      scaffoldBackgroundColor: palette.appBackground,
      dividerColor: palette.divider,
      extensions: [palette],
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: palette.textPrimary,
        selectedTileColor: palette.selectedRow,
        iconColor: palette.textMuted,
        textColor: palette.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: palette.divider)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return palette.accentSoft;
            }
            return palette.surfaceRaised;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return palette.accent;
            return palette.textMuted;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceSoft,
        hintStyle: TextStyle(color: palette.textMuted),
        labelStyle: TextStyle(color: palette.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(21),
          borderSide: BorderSide(color: palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(21),
          borderSide: BorderSide(color: palette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(21),
          borderSide: BorderSide(color: palette.accent, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(language);
    return MaterialApp(
      title: strings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: loaded
          ? MessengerHome(
              strings: strings,
              language: language,
              themeMode: themeMode,
              appStyle: appStyle,
              onThemeChanged: setThemeMode,
              onStyleChanged: setAppStyle,
              onLanguageChanged: setLanguage,
            )
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

String defaultApiBase() {
  const defined = String.fromEnvironment('API_BASE_URL');
  if (defined.isNotEmpty) return defined;
  final base = Uri.base;
  if (kIsWeb && base.scheme.startsWith('http')) return base.origin;
  return 'https://max.stalsky.org';
}

String wsBaseFor(String apiBase) {
  final uri = Uri.parse(apiBase);
  return uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws').toString();
}

String mediaUrl(String apiBase, String? path) {
  if (path == null || path.isEmpty) return '';
  final uri = Uri.tryParse(path);
  if (uri != null && uri.hasScheme) return path;
  final base = Uri.parse(apiBase);
  return base.replace(path: path).toString();
}

String messageClock(String iso) {
  final value = DateTime.tryParse(iso)?.toLocal();
  if (value == null) return '';
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String peerStatus(ChatSummary chat) {
  if (chat.peerOnline) return 'online';
  final lastSeen = DateTime.tryParse(chat.peerLastSeenAt ?? '')?.toLocal();
  if (lastSeen == null) return 'last seen recently';
  final diff = DateTime.now().difference(lastSeen);
  if (diff.inMinutes < 2) return 'last seen recently';
  if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes} min ago';
  if (diff.inHours < 24) return 'last seen ${diff.inHours} h ago';
  return 'last seen ${diff.inDays} d ago';
}

String lastMessagePreview(ChatSummary chat) {
  final text = chat.lastText?.trim();
  if (chat.draftText?.trim().isNotEmpty == true) {
    return 'Draft: ${chat.draftText!.trim()}';
  }
  if (text == null || text.isEmpty) return 'Voice message';
  return text;
}

String activityLabel(ChatActivityKind activity) {
  switch (activity) {
    case ChatActivityKind.typing:
      return 'typing...';
    case ChatActivityKind.recording:
      return 'recording...';
    case ChatActivityKind.uploading:
      return 'uploading...';
  }
}

String attachmentKindValue(AttachmentKind kind) {
  switch (kind) {
    case AttachmentKind.photo:
      return 'photo';
    case AttachmentKind.file:
      return 'file';
    case AttachmentKind.document:
      return 'document';
  }
}

AttachmentKind attachmentKindFromString(String? value) {
  switch (value) {
    case 'image':
    case 'photo':
      return AttachmentKind.photo;
    case 'document':
      return AttachmentKind.document;
    default:
      return AttachmentKind.file;
  }
}

AttachmentKind attachmentKindFor(String fileName, String? mimeType) {
  final lowerName = fileName.toLowerCase();
  final lowerMime = mimeType?.toLowerCase() ?? '';
  if (lowerMime.startsWith('image/') ||
      lowerName.endsWith('.jpg') ||
      lowerName.endsWith('.jpeg') ||
      lowerName.endsWith('.png') ||
      lowerName.endsWith('.gif') ||
      lowerName.endsWith('.webp')) {
    return AttachmentKind.photo;
  }
  if (lowerMime.contains('pdf') ||
      lowerMime.contains('document') ||
      lowerMime.contains('spreadsheet') ||
      lowerMime.contains('presentation') ||
      lowerName.endsWith('.pdf') ||
      lowerName.endsWith('.doc') ||
      lowerName.endsWith('.docx') ||
      lowerName.endsWith('.xls') ||
      lowerName.endsWith('.xlsx') ||
      lowerName.endsWith('.ppt') ||
      lowerName.endsWith('.pptx') ||
      lowerName.endsWith('.txt')) {
    return AttachmentKind.document;
  }
  return AttachmentKind.file;
}

String? mimeTypeForFile(String fileName, String? candidate) {
  final normalized = candidate?.trim().toLowerCase();
  if (normalized != null && normalized.contains('/')) return normalized;
  final nameParts = fileName.split('.');
  final extension = (normalized == null || normalized.isEmpty)
      ? (nameParts.length > 1 ? nameParts.last.toLowerCase() : null)
      : normalized.replaceFirst(RegExp(r'^\.'), '');
  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'zip':
      return 'application/zip';
    case 'txt':
      return 'text/plain';
    default:
      return null;
  }
}

IconData attachmentIcon(AttachmentKind kind) {
  switch (kind) {
    case AttachmentKind.photo:
      return Icons.image_outlined;
    case AttachmentKind.document:
      return Icons.description_outlined;
    case AttachmentKind.file:
      return Icons.insert_drive_file_outlined;
  }
}

String formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var index = 0;
  while (value >= 1024 && index < units.length - 1) {
    value /= 1024;
    index++;
  }
  final decimals = value >= 10 || index == 0 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${units[index]}';
}

String domainForUrl(String? value) {
  final uri = Uri.tryParse(value ?? '');
  if (uri == null || uri.host.isEmpty) return '';
  return uri.host.replaceFirst(RegExp(r'^www\.'), '');
}

String messageContentLabel(ChatMessage message) {
  if (message.voiceUrl != null || message.localVoicePath != null) {
    return 'Voice message';
  }
  final attachment = message.attachment;
  if (attachment != null) {
    return attachment.kind == AttachmentKind.photo
        ? 'Photo'
        : attachment.fileName;
  }
  return message.text;
}

class ApiClient {
  ApiClient(this.baseUrl, {this.token});
  final String baseUrl;
  String? token;

  Uri uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUrl);
    if (query == null && path.contains('?')) {
      final parsed = Uri.parse(path);
      return base.replace(path: parsed.path, query: parsed.query);
    }
    return base.replace(path: path, queryParameters: query);
  }

  Map<String, String> headers() => {
    'content-type': 'application/json',
    if (token != null) 'authorization': 'Bearer $token',
  };

  Map<String, String> authHeaders() => {
    if (token != null) 'authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> getJson(
    String path, [
    Map<String, String>? query,
  ]) async {
    return decode(await http.get(uri(path, query), headers: headers()));
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    return decode(
      await http.post(uri(path), headers: headers(), body: jsonEncode(body)),
    );
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    return decode(
      await http.patch(uri(path), headers: headers(), body: jsonEncode(body)),
    );
  }

  Future<Map<String, dynamic>> postBytes(
    String path,
    Uint8List body,
    String contentType,
  ) async {
    final requestHeaders = {
      'content-type': contentType,
      if (token != null) 'authorization': 'Bearer $token',
    };
    return decode(
      await http.post(uri(path), headers: requestHeaders, body: body),
    );
  }

  Future<Map<String, dynamic>> postMultipartBytes(
    String path,
    String fieldName,
    Uint8List body,
    String filename, [
    Map<String, String>? fields,
  ]) async {
    final request = http.MultipartRequest('POST', uri(path));
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    request.fields.addAll(fields ?? const {});
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, body, filename: filename),
    );
    final streamed = await request.send();
    return decode(await http.Response.fromStream(streamed));
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(uri(path), headers: authHeaders());
    if (response.statusCode >= 400) {
      throw ApiException(
        response.body.isEmpty ? 'request_failed' : response.body,
      );
    }
    return decode(response);
  }

  Future<void> deleteJson(String path, Map<String, dynamic> body) async {
    final request = http.Request('DELETE', uri(path))
      ..headers.addAll(headers())
      ..body = jsonEncode(body);
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 400) {
      throw ApiException(
        response.body.isEmpty ? 'request_failed' : response.body,
      );
    }
  }

  Future<Map<String, dynamic>> editMessage(
    String chatId,
    String messageId,
    String text,
  ) {
    return patchJson('/api/messages/${Uri.encodeComponent(messageId)}', {
      'text': text,
    });
  }

  Future<void> deleteMessages(String chatId, List<String> messageIds) {
    return deleteJson('/api/chats/${Uri.encodeComponent(chatId)}/messages', {
      'messageIds': messageIds,
    });
  }

  Future<Map<String, dynamic>> reactToMessage(
    String chatId,
    String messageId,
    String reaction,
  ) {
    return postJson(
      '/api/messages/${Uri.encodeComponent(messageId)}/reactions',
      {'reaction': reaction},
    );
  }

  Future<Map<String, dynamic>> setMessagePinned(
    String chatId,
    String messageId,
    bool pinned,
  ) async {
    if (pinned) {
      return postJson('/api/chats/${Uri.encodeComponent(chatId)}/pins', {
        'messageId': messageId,
      });
    }
    return delete(
      '/api/chats/${Uri.encodeComponent(chatId)}/pins/${Uri.encodeComponent(messageId)}',
    );
  }

  Future<Map<String, dynamic>> clearPinnedMessages(String chatId) {
    return delete('/api/chats/${Uri.encodeComponent(chatId)}/pins');
  }

  Future<List<ChatMessage>> searchMessages(String chatId, String query) async {
    final data = await getJson(
      '/api/chats/${Uri.encodeComponent(chatId)}/messages/search',
      {'q': query},
    );
    return (data['messages'] as List)
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> setAutoDelete(String chatId, int seconds) async {
    await patchJson('/api/chats/${Uri.encodeComponent(chatId)}/settings', {
      'autoDeleteSeconds': seconds <= 0 ? null : seconds,
    });
  }

  Future<void> markChatRead(String chatId) async {
    await postJson('/api/chats/${Uri.encodeComponent(chatId)}/read', {});
  }

  Future<Map<String, dynamic>> sendMessage(
    String chatId,
    String text, {
    String? replyToMessageId,
  }) {
    final body = <String, dynamic>{'text': text};
    if (replyToMessageId != null) body['replyToMessageId'] = replyToMessageId;
    return postJson('/api/chats/${Uri.encodeComponent(chatId)}/messages', body);
  }

  Future<Map<String, dynamic>> sendAttachmentMessage(
    String chatId,
    Uint8List bytes, {
    required String fileName,
    required AttachmentKind kind,
    String? mimeType,
    String? text,
    String? replyToMessageId,
  }) {
    final contentType = mimeTypeForFile(fileName, mimeType) ?? switch (kind) {
      AttachmentKind.photo => 'image/jpeg',
      AttachmentKind.document => 'application/pdf',
      AttachmentKind.file => 'application/octet-stream',
    };
    return postBytes(
      '/api/chats/${Uri.encodeComponent(chatId)}/attachments?filename=${Uri.encodeQueryComponent(fileName)}',
      bytes,
      contentType,
    );
  }

  Future<void> setChatPinned(String chatId, bool pinned) async {
    await patchJson('/api/chats/${Uri.encodeComponent(chatId)}/user-settings', {
      'pinned': pinned,
    });
  }

  Future<void> setChatArchived(String chatId, bool archived) async {
    await patchJson('/api/chats/${Uri.encodeComponent(chatId)}/user-settings', {
      'archived': archived,
    });
  }

  Future<Map<String, dynamic>> sendVoiceMessage(
    String chatId,
    Uint8List bytes, {
    int durationSeconds = 0,
  }) {
    return postBytes(
      '/api/chats/${Uri.encodeComponent(chatId)}/voice?durationMs=${durationSeconds * 1000}',
      bytes,
      'audio/mp4',
    );
  }

  Map<String, dynamic> decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(body['error']?.toString() ?? 'request_failed');
    }
    return body;
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class NotificationService {
  static const _callChannel = MethodChannel('messenger_app/call_notifications');
  static const _messagesChannelId = 'messages';
  static const _incomingCallsChannelId = 'incoming_calls';
  static const _incomingCallNotificationId = 9001;
  static const _answerActionId = 'call_answer';
  static const _declineActionId = 'call_decline';

  final plugin = FlutterLocalNotificationsPlugin();
  final taps = StreamController<String>.broadcast();
  final callActions = StreamController<CallNotificationAction>.broadcast();
  bool ready = false;
  bool fcmReady = false;
  int nextId = 1;
  StreamSubscription<String>? tokenRefreshSub;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      fcmReady = await initFirebaseIfPossible();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          handleNotificationResponse(response);
        },
      );
      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _messagesChannelId,
          'Messages',
          description: 'Incoming chat messages',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          _incomingCallsChannelId,
          'Incoming calls',
          description: 'Incoming voice calls',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList(<int>[0, 700, 350, 700]),
          audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
      if (fcmReady) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          final chatId = message.data['chatId'];
          if (chatId != null && chatId.isNotEmpty) taps.add(chatId);
        });
      }
      ready = true;
    } catch (_) {
      ready = false;
      fcmReady = false;
    }
  }

  void handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    if (response.actionId == _answerActionId ||
        response.actionId == _declineActionId) {
      final action = response.actionId == _answerActionId
          ? CallNotificationIntent.answer
          : CallNotificationIntent.decline;
      final call = CallNotificationPayload.tryParse(payload);
      if (call != null) {
        callActions.add(CallNotificationAction(action, call));
      }
      return;
    }
    final call = CallNotificationPayload.tryParse(payload);
    if (call != null) {
      taps.add(call.chatId);
      return;
    }
    taps.add(payload);
  }

  Future<void> registerDeviceToken(ApiClient api) async {
    if (!fcmReady || kIsWeb || api.token == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await api.postJson('/api/push/tokens', {
          'token': token,
          'platform': 'android',
        });
      }
      await tokenRefreshSub?.cancel();
      tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
        newToken,
      ) {
        if (api.token != null) {
          unawaited(
            api.postJson('/api/push/tokens', {
              'token': newToken,
              'platform': 'android',
            }),
          );
        }
      });
    } catch (_) {}
  }

  Future<String?> initialChatId() async {
    if (!fcmReady || kIsWeb) return null;
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      return message?.data['chatId'];
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await tokenRefreshSub?.cancel();
    await stopIncomingCall();
    await taps.close();
    await callActions.close();
  }

  Future<void> showIncoming(AppStrings strings, ChatMessage message) async {
    if (!ready || kIsWeb) return;
    const androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'Incoming chat messages',
      importance: Importance.high,
      priority: Priority.high,
    );
    await plugin.show(
      id: nextId++,
      title: strings.incomingMessage,
      body: '${message.senderName}: ${message.text}',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: message.chatId,
    );
  }

  Future<void> showIncomingCall(
    AppStrings strings,
    VoiceCallSession call,
  ) async {
    if (!ready || kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      _incomingCallsChannelId,
      'Incoming calls',
      channelDescription: 'Incoming voice calls',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      vibrationPattern: Int64List.fromList(<int>[0, 700, 350, 700]),
      enableVibration: true,
      playSound: true,
      ongoing: true,
      autoCancel: false,
      timeoutAfter: const Duration(seconds: 45).inMilliseconds,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          _answerActionId,
          strings.answer,
          showsUserInterface: true,
          cancelNotification: true,
          semanticAction: SemanticAction.call,
        ),
        AndroidNotificationAction(
          _declineActionId,
          strings.decline,
          showsUserInterface: true,
          cancelNotification: true,
          semanticAction: SemanticAction.delete,
        ),
      ],
    );
    await plugin.show(
      id: _incomingCallNotificationId,
      title: strings.incomingCall,
      body: call.peerName,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: CallNotificationPayload.fromCall(call).encode(),
    );
    await startIncomingCallRingtone();
  }

  Future<void> stopIncomingCall() async {
    if (kIsWeb) return;
    try {
      await _callChannel.invokeMethod<void>('stopIncomingCallRingtone');
    } catch (_) {}
    if (ready) {
      await plugin.cancel(id: _incomingCallNotificationId);
    }
  }

  Future<void> startIncomingCallRingtone() async {
    if (kIsWeb) return;
    try {
      await _callChannel.invokeMethod<void>('startIncomingCallRingtone');
    } catch (_) {}
  }
}

enum CallNotificationIntent { answer, decline }

class CallNotificationAction {
  const CallNotificationAction(this.intent, this.call);
  final CallNotificationIntent intent;
  final CallNotificationPayload call;
}

class CallNotificationPayload {
  const CallNotificationPayload({required this.chatId, required this.callId});

  final String chatId;
  final String callId;

  factory CallNotificationPayload.fromCall(VoiceCallSession call) {
    return CallNotificationPayload(chatId: call.chatId, callId: call.callId);
  }

  static CallNotificationPayload? tryParse(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data is! Map<String, dynamic> || data['type'] != 'call') return null;
      final chatId = data['chatId'] as String?;
      final callId = data['callId'] as String?;
      if (chatId == null || callId == null) return null;
      return CallNotificationPayload(chatId: chatId, callId: callId);
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(<String, String>{
    'type': 'call',
    'chatId': chatId,
    'callId': callId,
  });
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.lastSeenAt,
  });
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? lastSeenAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    username: json['username'] as String,
    displayName: json['displayName'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    lastSeenAt: json['lastSeenAt'] as String?,
  );
}

class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.peerId,
    required this.peerUsername,
    required this.peerDisplayName,
    this.peerAvatarUrl,
    this.peerOnline = false,
    this.peerLastSeenAt,
    this.lastText,
    this.lastAt,
    this.unreadCount = 0,
    this.pinned = false,
    this.archived = false,
    this.draftText,
  });
  final String id;
  final String peerId;
  final String peerUsername;
  final String peerDisplayName;
  final String? peerAvatarUrl;
  final bool peerOnline;
  final String? peerLastSeenAt;
  final String? lastText;
  final String? lastAt;
  final int unreadCount;
  final bool pinned;
  final bool archived;
  final String? draftText;

  factory ChatSummary.fromJson(Map<String, dynamic> json) => ChatSummary(
    id: json['id'] as String,
    peerId: json['peerId'] as String,
    peerUsername: json['peerUsername'] as String,
    peerDisplayName: json['peerDisplayName'] as String,
    peerAvatarUrl: json['peerAvatarUrl'] as String?,
    peerOnline: json['peerOnline'] == true,
    peerLastSeenAt: json['peerLastSeenAt'] as String?,
    lastText: json['lastText'] as String?,
    lastAt: json['lastAt'] as String?,
    unreadCount: (json['unreadCount'] as num? ?? json['unread'] as num? ?? 0)
        .toInt(),
    pinned: json['pinned'] == true || json['isPinned'] == true,
    archived: json['archived'] == true || json['isArchived'] == true,
  );

  ChatSummary copyWith({
    bool? peerOnline,
    String? peerLastSeenAt,
    int? unreadCount,
    bool? pinned,
    bool? archived,
    String? draftText,
  }) => ChatSummary(
    id: id,
    peerId: peerId,
    peerUsername: peerUsername,
    peerDisplayName: peerDisplayName,
    peerAvatarUrl: peerAvatarUrl,
    peerOnline: peerOnline ?? this.peerOnline,
    peerLastSeenAt: peerLastSeenAt ?? this.peerLastSeenAt,
    lastText: lastText,
    lastAt: lastAt,
    unreadCount: unreadCount ?? this.unreadCount,
    pinned: pinned ?? this.pinned,
    archived: archived ?? this.archived,
    draftText: draftText ?? this.draftText,
  );
}

class MessageAttachment {
  const MessageAttachment({
    required this.kind,
    required this.fileName,
    this.id,
    this.url,
    this.thumbnailUrl,
    this.mimeType,
    this.sizeBytes,
    this.localPath,
    this.localBytes,
  });

  final String? id;
  final AttachmentKind kind;
  final String fileName;
  final String? url;
  final String? thumbnailUrl;
  final String? mimeType;
  final int? sizeBytes;
  final String? localPath;
  final Uint8List? localBytes;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    final fileName =
        json['fileName'] as String? ??
        json['name'] as String? ??
        json['filename'] as String? ??
        'Attachment';
    final mimeType =
        json['mimeType'] as String? ?? json['contentType'] as String?;
    return MessageAttachment(
      id: json['id']?.toString(),
      kind: attachmentKindFromString(
        json['kind'] as String? ??
            json['type'] as String? ??
            json['attachmentType'] as String?,
      ),
      fileName: fileName,
      url:
          json['url'] as String? ??
          json['mediaUrl'] as String? ??
          json['fileUrl'] as String?,
      thumbnailUrl:
          json['thumbnailUrl'] as String? ?? json['thumbUrl'] as String?,
      mimeType: mimeType,
      sizeBytes: (json['sizeBytes'] as num? ?? json['size'] as num?)?.toInt(),
    );
  }

  MessageAttachment copyWith({
    String? id,
    AttachmentKind? kind,
    String? fileName,
    String? url,
    String? thumbnailUrl,
    String? mimeType,
    int? sizeBytes,
    String? localPath,
    Uint8List? localBytes,
  }) => MessageAttachment(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    fileName: fileName ?? this.fileName,
    url: url ?? this.url,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    localPath: localPath ?? this.localPath,
    localBytes: localBytes ?? this.localBytes,
  );
}

class LinkPreview {
  const LinkPreview({
    this.url,
    this.domain,
    this.title,
    this.description,
    this.thumbnailUrl,
  });

  final String? url;
  final String? domain;
  final String? title;
  final String? description;
  final String? thumbnailUrl;

  factory LinkPreview.fromJson(Map<String, dynamic> json) => LinkPreview(
    url: json['url'] as String? ?? json['href'] as String?,
    domain: json['domain'] as String? ?? json['siteName'] as String?,
    title: json['title'] as String?,
    description: json['description'] as String?,
    thumbnailUrl:
        json['thumbnailUrl'] as String? ??
        json['imageUrl'] as String? ??
        json['image'] as String?,
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.editedAt,
    this.pinned = false,
    this.readByPeer = false,
    this.reactions = const {},
    this.reactionUsers = const {},
    this.voiceUrl,
    this.voiceDurationSeconds,
    this.localVoicePath,
    this.uploading = false,
    this.deliveryState = MessageDeliveryState.sent,
    this.attachment,
    this.linkPreview,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderName,
    this.replyToType,
  });
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final String createdAt;
  final String? editedAt;
  final bool pinned;
  final bool readByPeer;
  final Map<String, int> reactions;
  final Map<String, List<String>> reactionUsers;
  final String? voiceUrl;
  final int? voiceDurationSeconds;
  final String? localVoicePath;
  final bool uploading;
  final MessageDeliveryState deliveryState;
  final MessageAttachment? attachment;
  final LinkPreview? linkPreview;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderName;
  final String? replyToType;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawAttachment = json['attachment'];
    final rawAttachments = json['attachments'];
    MessageAttachment? attachment;
    if (rawAttachment is Map<String, dynamic>) {
      attachment = MessageAttachment.fromJson(rawAttachment);
    } else if (rawAttachments is List && rawAttachments.isNotEmpty) {
      final first = rawAttachments.first;
      if (first is Map<String, dynamic>) {
        attachment = MessageAttachment.fromJson(first);
      }
    } else if (json['fileUrl'] != null || json['attachmentUrl'] != null) {
      final fileUri = Uri.tryParse(
        json['fileUrl']?.toString() ?? json['attachmentUrl']?.toString() ?? '',
      );
      final fileName =
          json['fileName'] as String? ??
          (fileUri == null || fileUri.pathSegments.isEmpty
              ? null
              : fileUri.pathSegments.last) ??
          'Attachment';
      final mimeType = json['mimeType'] as String?;
      attachment = MessageAttachment(
        kind: attachmentKindFor(fileName, mimeType),
        fileName: fileName,
        url: json['fileUrl'] as String? ?? json['attachmentUrl'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        mimeType: mimeType,
        sizeBytes: (json['sizeBytes'] as num? ?? json['size'] as num?)?.toInt(),
      );
    }

    final rawPreview = json['linkPreview'] ?? json['preview'];
    return ChatMessage(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] as String,
      editedAt: json['editedAt'] as String?,
      pinned:
          json['pinned'] == true ||
          json['pinned'] == 1 ||
          json['isPinned'] == true,
      readByPeer:
          json['readByPeer'] == true ||
          json['readByPeer'] == 1 ||
          json['isRead'] == true,
      reactions: _parseReactions(json['reactions']),
      reactionUsers: _parseReactionUsers(json['reactions']),
      voiceUrl:
          json['voiceUrl'] as String? ??
          json['audioUrl'] as String? ??
          ((attachment == null) ? json['mediaUrl'] as String? : null),
      voiceDurationSeconds:
          (json['voiceDurationSeconds'] as num? ??
                  json['durationSeconds'] as num? ??
                  ((json['durationMs'] as num?) == null
                      ? null
                      : ((json['durationMs'] as num) / 1000).ceil()))
              ?.toInt(),
      attachment: attachment,
      linkPreview: rawPreview is Map<String, dynamic>
          ? LinkPreview.fromJson(rawPreview)
          : null,
      replyToMessageId: json['replyToMessageId'] as String?,
      replyToText: json['replyToText'] as String?,
      replyToSenderName: json['replyToSenderName'] as String?,
      replyToType: json['replyToType'] as String?,
    );
  }

  ChatMessage copyWith({
    String? text,
    String? editedAt,
    bool? pinned,
    bool? readByPeer,
    Map<String, int>? reactions,
    Map<String, List<String>>? reactionUsers,
    String? voiceUrl,
    int? voiceDurationSeconds,
    String? localVoicePath,
    bool? uploading,
    MessageDeliveryState? deliveryState,
    MessageAttachment? attachment,
    LinkPreview? linkPreview,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
    String? replyToType,
  }) => ChatMessage(
    id: id,
    chatId: chatId,
    senderId: senderId,
    senderName: senderName,
    text: text ?? this.text,
    createdAt: createdAt,
    editedAt: editedAt ?? this.editedAt,
    pinned: pinned ?? this.pinned,
    readByPeer: readByPeer ?? this.readByPeer,
    reactions: reactions ?? this.reactions,
    reactionUsers: reactionUsers ?? this.reactionUsers,
    voiceUrl: voiceUrl ?? this.voiceUrl,
    voiceDurationSeconds: voiceDurationSeconds ?? this.voiceDurationSeconds,
    localVoicePath: localVoicePath ?? this.localVoicePath,
    uploading: uploading ?? this.uploading,
    deliveryState: deliveryState ?? this.deliveryState,
    attachment: attachment ?? this.attachment,
    linkPreview: linkPreview ?? this.linkPreview,
    replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    replyToText: replyToText ?? this.replyToText,
    replyToSenderName: replyToSenderName ?? this.replyToSenderName,
    replyToType: replyToType ?? this.replyToType,
  );
}

class MessageReaction {
  const MessageReaction({required this.count, this.userIds = const []});
  final int count;
  final List<String> userIds;
}

class PeerActivity {
  const PeerActivity({required this.kind, required this.expiresAt});
  final ChatActivityKind kind;
  final DateTime expiresAt;

  bool get active => expiresAt.isAfter(DateTime.now());
}

class PendingOutgoing {
  const PendingOutgoing({
    required this.localId,
    required this.chatId,
    required this.text,
    this.replyToMessageId,
    this.attachment,
    this.bytes,
    this.voicePath,
    this.voiceDurationSeconds = 0,
  });

  final String localId;
  final String chatId;
  final String text;
  final String? replyToMessageId;
  final MessageAttachment? attachment;
  final Uint8List? bytes;
  final String? voicePath;
  final int voiceDurationSeconds;

  bool get isVoice => voicePath != null;
  bool get isAttachment => attachment != null && bytes != null;
}

Map<String, int> _parseReactions(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value.map((key, count) => MapEntry(key, (count as num).toInt()));
  }
  if (value is List) {
    final result = <String, int>{};
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        final reaction = item['reaction']?.toString();
        final count = item['count'];
        if (reaction != null && count is num) result[reaction] = count.toInt();
      }
    }
    return result;
  }
  return const {};
}

Map<String, List<String>> _parseReactionUsers(dynamic value) {
  if (value is List) {
    final result = <String, List<String>>{};
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        final reaction = item['reaction']?.toString();
        final users = item['userIds'];
        if (reaction != null && users is List) {
          result[reaction] = users.map((item) => item.toString()).toList();
        }
      }
    }
    return result;
  }
  return const {};
}

enum VoiceCallPhase { idle, outgoing, incoming, connecting, active }

enum AudioRoute { earpiece, speaker, bluetooth }

class VoiceCallSession {
  const VoiceCallSession({
    required this.phase,
    required this.chatId,
    required this.callId,
    required this.peerId,
    required this.peerName,
    this.peerAvatarUrl,
    this.muted = false,
    this.audioRoute = AudioRoute.earpiece,
  });

  final VoiceCallPhase phase;
  final String chatId;
  final String callId;
  final String peerId;
  final String peerName;
  final String? peerAvatarUrl;
  final bool muted;
  final AudioRoute audioRoute;

  VoiceCallSession copyWith({
    VoiceCallPhase? phase,
    bool? muted,
    AudioRoute? audioRoute,
  }) => VoiceCallSession(
    phase: phase ?? this.phase,
    chatId: chatId,
    callId: callId,
    peerId: peerId,
    peerName: peerName,
    peerAvatarUrl: peerAvatarUrl,
    muted: muted ?? this.muted,
    audioRoute: audioRoute ?? this.audioRoute,
  );
}

class MessengerHome extends StatefulWidget {
  const MessengerHome({
    super.key,
    required this.strings,
    required this.language,
    required this.themeMode,
    required this.appStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
    required this.onLanguageChanged,
  });

  final AppStrings strings;
  final AppLanguage language;
  final ThemeMode themeMode;
  final AppThemeStyle appStyle;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<AppThemeStyle> onStyleChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  State<MessengerHome> createState() => _MessengerHomeState();
}

class _MessengerHomeState extends State<MessengerHome>
    with WidgetsBindingObserver {
  late final ApiClient api;
  final notifications = NotificationService();
  UserProfile? currentUser;
  String? token;
  bool loading = true;
  String? error;
  final contacts = <UserProfile>[];
  final chats = <ChatSummary>[];
  final messages = <String, List<ChatMessage>>{};
  final pendingVoicePaths = <String, List<String>>{};
  final pendingOutgoing = <String, PendingOutgoing>{};
  final peerActivities = <String, PeerActivity>{};
  final chatDrafts = <String, String>{};
  ChatSummary? selectedChat;
  WebSocketChannel? channel;
  StreamSubscription? socketSub;
  StreamSubscription<String>? notificationTapSub;
  StreamSubscription<CallNotificationAction>? callNotificationActionSub;
  Timer? incomingCallTimeoutTimer;
  Timer? activityCleanupTimer;
  String? pendingNotificationChatId;
  AppLifecycleState lifecycleState = AppLifecycleState.resumed;
  VoiceCallSession? voiceCall;
  RTCPeerConnection? peerConnection;
  MediaStream? localVoiceStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    api = ApiClient(defaultApiBase());
    initNotifications();
    restoreSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    socketSub?.cancel();
    notificationTapSub?.cancel();
    callNotificationActionSub?.cancel();
    incomingCallTimeoutTimer?.cancel();
    activityCleanupTimer?.cancel();
    channel?.sink.close();
    for (final track in localVoiceStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    localVoiceStream?.dispose();
    peerConnection?.close();
    unawaited(notifications.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    lifecycleState = state;
  }

  Future<void> initNotifications() async {
    await notifications.init();
    pendingNotificationChatId = await notifications.initialChatId();
    notificationTapSub = notifications.taps.stream.listen((chatId) {
      pendingNotificationChatId = chatId;
      if (currentUser != null) unawaited(openChatById(chatId));
    });
    callNotificationActionSub = notifications.callActions.stream.listen((
      action,
    ) {
      unawaited(handleCallNotificationAction(action));
    });
    if (currentUser != null) {
      unawaited(openPendingNotificationChat());
    }
  }

  Future<void> handleCallNotificationAction(
    CallNotificationAction action,
  ) async {
    final call = voiceCall;
    if (call == null ||
        call.chatId != action.call.chatId ||
        call.callId != action.call.callId) {
      return;
    }
    if (action.intent == CallNotificationIntent.answer) {
      await acceptVoiceCall();
    } else {
      await rejectVoiceCall();
    }
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('auth_token');
    if (stored == null) {
      setState(() => loading = false);
      return;
    }
    api.token = stored;
    try {
      final me = await api.getJson('/api/me');
      currentUser = UserProfile.fromJson(me['user'] as Map<String, dynamic>);
      token = stored;
      await afterLogin();
    } catch (_) {
      await prefs.remove('auth_token');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> afterLogin() async {
    await Future.wait([loadContacts(), loadChats()]);
    await notifications.registerDeviceToken(api);
    await openPendingNotificationChat();
    connectSocket();
  }

  void connectSocket() {
    socketSub?.cancel();
    channel?.sink.close();
    activityCleanupTimer?.cancel();
    if (token == null) return;
    final uri = Uri.parse(
      '${wsBaseFor(api.baseUrl)}/ws?token=${Uri.encodeComponent(token!)}',
    );
    channel = WebSocketChannel.connect(uri);
    socketSub = channel!.stream.listen((event) {
      final data = jsonDecode(event as String) as Map<String, dynamic>;
      if (data['type'] == 'message.created') {
        final message = ChatMessage.fromJson(
          data['message'] as Map<String, dynamic>,
        );
        mergeIncomingMessage(message);
        if (message.senderId != currentUser?.id &&
            lifecycleState == AppLifecycleState.resumed) {
          notifications.showIncoming(widget.strings, message);
          if (selectedChat?.id == message.chatId) {
            unawaited(markSelectedChatRead());
          }
        }
        loadChats();
      } else if (data['type'] == 'message.updated') {
        final message = ChatMessage.fromJson(
          data['message'] as Map<String, dynamic>,
        );
        replaceLocalMessage(message);
      } else if (data['type'] == 'message.deleted') {
        final chatId = data['chatId'] as String?;
        final ids =
            (data['messageIds'] as List?)
                ?.map((item) => item.toString())
                .toSet() ??
            {if (data['messageId'] != null) data['messageId'].toString()};
        if (chatId != null && ids.isNotEmpty) {
          setState(
            () => messages[chatId]?.removeWhere(
              (message) => ids.contains(message.id),
            ),
          );
          loadChats();
        }
      } else if (data['type'] == 'message.reaction') {
        final message = ChatMessage.fromJson(
          data['message'] as Map<String, dynamic>,
        );
        replaceLocalMessage(message);
      } else if (data['type'] == 'message.pinned') {
        final chatId = data['chatId'] as String?;
        final pinIds =
            (data['pins'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map((pin) => pin['messageId']?.toString())
                .whereType<String>()
                .toSet() ??
            const <String>{};
        if (chatId != null) {
          setState(() {
            final list = messages[chatId];
            if (list == null) return;
            messages[chatId] = [
              for (final message in list)
                message.copyWith(pinned: pinIds.contains(message.id)),
            ];
          });
        }
      } else if (data['type'] == 'message.settings') {
        // The settings change affects future messages; existing local messages do not need mutation.
      } else if (data['type'] == 'message.read') {
        final chatId = data['chatId'] as String?;
        final ids =
            (data['messageIds'] as List?)
                ?.map((item) => item.toString())
                .toSet() ??
            const <String>{};
        final readerId = data['readerId'] as String?;
        if (chatId != null && ids.isNotEmpty && readerId != currentUser?.id) {
          setState(() {
            final list = messages[chatId];
            if (list == null) return;
            messages[chatId] = [
              for (final message in list)
                ids.contains(message.id)
                    ? message.copyWith(readByPeer: true)
                    : message,
            ];
          });
        }
      } else if (data['type'] == 'presence.updated') {
        final user = data['user'];
        if (user is Map<String, dynamic>) {
          final userId = user['id'] as String?;
          final online = data['online'] == true;
          final lastSeenAt = user['lastSeenAt'] as String?;
          if (userId != null) updatePeerPresence(userId, online, lastSeenAt);
        }
      } else if (data['type'] == 'chat.activity' ||
          data['type'] == 'typing' ||
          data['type'] == 'recording' ||
          data['type'] == 'uploading') {
        handleChatActivity(data);
      } else if (data['type'] is String &&
          (data['type'] as String).startsWith('call.')) {
        unawaited(handleCallSignal(data));
      }
    }, onError: (_) {});
    activityCleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final before = peerActivities.length;
      peerActivities.removeWhere(
        (_, activity) => !activity.expiresAt.isAfter(now),
      );
      if (before != peerActivities.length) setState(() {});
    });
  }

  void replaceLocalMessage(ChatMessage message) {
    setState(() {
      final list = messages.putIfAbsent(message.chatId, () => []);
      final index = list.indexWhere((item) => item.id == message.id);
      if (index == -1) {
        list.add(message);
      } else {
        list[index] = message;
      }
    });
  }

  void replaceLocalMessageById(String localId, ChatMessage message) {
    setState(() {
      final list = messages.putIfAbsent(message.chatId, () => []);
      final index = list.indexWhere((item) => item.id == localId);
      if (index == -1) {
        if (!list.any((item) => item.id == message.id)) list.add(message);
      } else {
        list[index] = message;
      }
    });
  }

  void mergeIncomingMessage(ChatMessage message) {
    setState(() {
      final list = messages.putIfAbsent(message.chatId, () => []);
      final existingIndex = list.indexWhere((item) => item.id == message.id);
      if (existingIndex != -1) {
        pendingVoicePaths[message.chatId]?.remove(
          list[existingIndex].localVoicePath,
        );
        pendingOutgoing.remove(list[existingIndex].id);
        list[existingIndex] = message.copyWith(
          localVoicePath: list[existingIndex].localVoicePath,
          attachment: message.attachment?.copyWith(
            localPath: list[existingIndex].attachment?.localPath,
            localBytes: list[existingIndex].attachment?.localBytes,
          ),
          uploading: false,
          deliveryState: MessageDeliveryState.sent,
        );
        return;
      }
      if (message.senderId == currentUser?.id) {
        final localIndex = list.indexWhere(
          (item) =>
              item.id.startsWith('local_') &&
              item.senderId == message.senderId &&
              item.deliveryState != MessageDeliveryState.failed &&
              ((message.attachment != null && item.attachment != null) ||
                  (message.voiceUrl != null && item.localVoicePath != null) ||
                  (message.text.trim().isNotEmpty &&
                      item.text.trim() == message.text.trim())),
        );
        if (localIndex != -1) {
          final local = list[localIndex];
          pendingOutgoing.remove(local.id);
          pendingVoicePaths[message.chatId]?.remove(local.localVoicePath);
          list[localIndex] = message.copyWith(
            localVoicePath: local.localVoicePath,
            attachment: message.attachment?.copyWith(
              localPath: local.attachment?.localPath,
              localBytes: local.attachment?.localBytes,
            ),
            uploading: false,
            deliveryState: MessageDeliveryState.sent,
          );
          return;
        }
      }
      if (message.senderId == currentUser?.id && message.voiceUrl != null) {
        final localIndex = list.indexWhere(
          (item) =>
              item.id.startsWith('local_') &&
              item.senderId == message.senderId &&
              item.voiceUrl == null &&
              item.localVoicePath != null,
        );
        if (localIndex != -1) {
          final localPath = list[localIndex].localVoicePath;
          pendingVoicePaths[message.chatId]?.remove(localPath);
          list[localIndex] = message.copyWith(
            localVoicePath: localPath,
            uploading: false,
          );
          return;
        }
        final pending = pendingVoicePaths[message.chatId];
        final localPath = pending == null || pending.isEmpty
            ? null
            : pending.removeAt(0);
        list.add(message.copyWith(localVoicePath: localPath, uploading: false));
        return;
      }
      list.add(message);
    });
  }

  void sendSocketEvent(Map<String, dynamic> event) {
    channel?.sink.add(jsonEncode(event));
  }

  void sendChatActivity(
    String chatId,
    ChatActivityKind kind, {
    required bool active,
  }) {
    sendSocketEvent({
      'type': '${kind.name}.${active ? 'start' : 'stop'}',
      'chatId': chatId,
    });
  }

  void handleChatActivity(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    if (chatId == null) return;
    final from = data['from'];
    final fromId = from is Map<String, dynamic> ? from['id'] as String? : null;
    if (fromId != null && fromId == currentUser?.id) return;
    final type = data['type'] as String?;
    final raw =
        data['activity'] as String? ??
        (type?.contains('.') == true ? type!.split('.').first : type);
    final kind = ChatActivityKind.values
        .where((item) => item.name == raw)
        .firstOrNull;
    if (kind == null) return;
    final active = type?.endsWith('.stop') == true ? false : data['active'] != false;
    setState(() {
      if (active) {
        peerActivities[chatId] = PeerActivity(
          kind: kind,
          expiresAt: DateTime.now().add(const Duration(seconds: 5)),
        );
      } else {
        peerActivities.remove(chatId);
      }
    });
  }

  void updateDraft(String chatId, String value) {
    chatDrafts[chatId] = value;
    final index = chats.indexWhere((chat) => chat.id == chatId);
    if (index != -1) {
      chats[index] = chats[index].copyWith(draftText: value);
      if (selectedChat?.id == chatId) selectedChat = chats[index];
    }
    if (mounted) setState(() {});
  }

  void updatePeerPresence(String userId, bool online, String? lastSeenAt) {
    setState(() {
      for (var index = 0; index < chats.length; index++) {
        final chat = chats[index];
        if (chat.peerId == userId) {
          chats[index] = chat.copyWith(
            peerOnline: online,
            peerLastSeenAt: lastSeenAt,
          );
          if (selectedChat?.id == chat.id) selectedChat = chats[index];
        }
      }
    });
  }

  Future<void> applyAudioRoute(AudioRoute route) async {
    if (kIsWeb) return;
    if (route == AudioRoute.speaker) {
      await Helper.setSpeakerphoneOn(true);
    } else if (route == AudioRoute.bluetooth) {
      await Helper.setSpeakerphoneOnButPreferBluetooth();
    } else {
      await Helper.setSpeakerphoneOn(false);
    }
  }

  Future<RTCPeerConnection> createVoicePeer(
    String chatId,
    String callId,
  ) async {
    await applyAudioRoute(voiceCall?.audioRoute ?? AudioRoute.earpiece);
    final pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });
    pc.onIceCandidate = (candidate) {
      sendSocketEvent({
        'type': 'call.ice',
        'chatId': chatId,
        'callId': callId,
        'candidate': candidate.toMap(),
      });
    };
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    localVoiceStream = stream;
    for (final track in stream.getAudioTracks()) {
      await pc.addTrack(track, stream);
    }
    return pc;
  }

  Future<void> startVoiceCall(ChatSummary chat) async {
    if (voiceCall != null) return;
    final callId =
        'call_${DateTime.now().microsecondsSinceEpoch}_${currentUser?.id ?? 'me'}';
    setState(() {
      voiceCall = VoiceCallSession(
        phase: VoiceCallPhase.outgoing,
        chatId: chat.id,
        callId: callId,
        peerId: chat.peerId,
        peerName: chat.peerDisplayName,
        peerAvatarUrl: chat.peerAvatarUrl,
      );
    });
    sendSocketEvent({
      'type': 'call.invite',
      'chatId': chat.id,
      'callId': callId,
    });
  }

  Future<void> acceptVoiceCall() async {
    final call = voiceCall;
    if (call == null || call.phase != VoiceCallPhase.incoming) return;
    incomingCallTimeoutTimer?.cancel();
    await notifications.stopIncomingCall();
    setState(() => voiceCall = call.copyWith(phase: VoiceCallPhase.connecting));
    peerConnection = await createVoicePeer(call.chatId, call.callId);
    sendSocketEvent({
      'type': 'call.accept',
      'chatId': call.chatId,
      'callId': call.callId,
    });
  }

  Future<void> rejectVoiceCall() async {
    final call = voiceCall;
    if (call == null) return;
    incomingCallTimeoutTimer?.cancel();
    sendSocketEvent({
      'type': 'call.reject',
      'chatId': call.chatId,
      'callId': call.callId,
    });
    await closeVoiceCall(sendEndSignal: false);
  }

  Future<void> endVoiceCall() async {
    await closeVoiceCall(sendEndSignal: true);
  }

  Future<void> closeVoiceCall({required bool sendEndSignal}) async {
    final call = voiceCall;
    incomingCallTimeoutTimer?.cancel();
    if (sendEndSignal && call != null) {
      sendSocketEvent({
        'type': 'call.end',
        'chatId': call.chatId,
        'callId': call.callId,
      });
    }
    await notifications.stopIncomingCall();
    for (final track in localVoiceStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await localVoiceStream?.dispose();
    localVoiceStream = null;
    await peerConnection?.close();
    peerConnection = null;
    await applyAudioRoute(AudioRoute.earpiece);
    if (mounted) setState(() => voiceCall = null);
  }

  Future<void> toggleMute() async {
    final call = voiceCall;
    final stream = localVoiceStream;
    if (call == null || stream == null) return;
    final muted = !call.muted;
    for (final track in stream.getAudioTracks()) {
      track.enabled = !muted;
    }
    setState(() => voiceCall = call.copyWith(muted: muted));
  }

  Future<void> setCallAudioRoute(AudioRoute route) async {
    final call = voiceCall;
    if (call == null) return;
    await applyAudioRoute(route);
    if (mounted) setState(() => voiceCall = call.copyWith(audioRoute: route));
  }

  Future<void> handleCallSignal(Map<String, dynamic> data) async {
    final type = data['type'] as String;
    final chatId = data['chatId'] as String?;
    final callId = data['callId'] as String?;
    final from = data['from'] as Map<String, dynamic>?;
    if (chatId == null || callId == null || from == null) return;
    final fromId = from['id'] as String? ?? '';
    final fromName =
        from['displayName'] as String? ??
        from['username'] as String? ??
        'Caller';
    final fromAvatarUrl = from['avatarUrl'] as String?;

    if (type == 'call.invite') {
      if (voiceCall != null) {
        sendSocketEvent({
          'type': 'call.reject',
          'chatId': chatId,
          'callId': callId,
        });
        return;
      }
      setState(() {
        voiceCall = VoiceCallSession(
          phase: VoiceCallPhase.incoming,
          chatId: chatId,
          callId: callId,
          peerId: fromId,
          peerName: fromName,
          peerAvatarUrl: fromAvatarUrl,
        );
      });
      final call = voiceCall;
      if (call != null) {
        await notifications.showIncomingCall(widget.strings, call);
        incomingCallTimeoutTimer?.cancel();
        incomingCallTimeoutTimer = Timer(const Duration(seconds: 45), () {
          final current = voiceCall;
          if (current != null &&
              current.phase == VoiceCallPhase.incoming &&
              current.chatId == chatId &&
              current.callId == callId) {
            sendSocketEvent({
              'type': 'call.reject',
              'chatId': chatId,
              'callId': callId,
            });
            unawaited(closeVoiceCall(sendEndSignal: false));
          }
        });
      }
      return;
    }

    final call = voiceCall;
    if (call == null || call.callId != callId || call.chatId != chatId) return;

    if (type == 'call.accept') {
      incomingCallTimeoutTimer?.cancel();
      await notifications.stopIncomingCall();
      setState(
        () => voiceCall = call.copyWith(phase: VoiceCallPhase.connecting),
      );
      peerConnection = await createVoicePeer(chatId, callId);
      final offer = await peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });
      await peerConnection!.setLocalDescription(offer);
      sendSocketEvent({
        'type': 'call.offer',
        'chatId': chatId,
        'callId': callId,
        'sdp': offer.sdp,
      });
      return;
    }

    if (type == 'call.offer') {
      incomingCallTimeoutTimer?.cancel();
      await notifications.stopIncomingCall();
      peerConnection ??= await createVoicePeer(chatId, callId);
      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(data['sdp'] as String, 'offer'),
      );
      final answer = await peerConnection!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });
      await peerConnection!.setLocalDescription(answer);
      sendSocketEvent({
        'type': 'call.answer',
        'chatId': chatId,
        'callId': callId,
        'sdp': answer.sdp,
      });
      if (mounted) {
        setState(() => voiceCall = call.copyWith(phase: VoiceCallPhase.active));
      }
      return;
    }

    if (type == 'call.answer') {
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(data['sdp'] as String, 'answer'),
      );
      if (mounted) {
        setState(() => voiceCall = call.copyWith(phase: VoiceCallPhase.active));
      }
      return;
    }

    if (type == 'call.ice') {
      final candidate = data['candidate'];
      if (candidate is Map<String, dynamic>) {
        await peerConnection?.addCandidate(
          RTCIceCandidate(
            candidate['candidate'] as String?,
            candidate['sdpMid'] as String?,
            candidate['sdpMLineIndex'] as int?,
          ),
        );
      }
      return;
    }

    if (type == 'call.reject' || type == 'call.end') {
      await closeVoiceCall(sendEndSignal: false);
    }
  }

  Future<void> login(String username, String password) async {
    await authenticate(
      () => api.postJson('/api/auth/login', {
        'username': username,
        'password': password,
      }),
    );
  }

  Future<void> register(String username, String password) async {
    await authenticate(
      () => api.postJson('/api/auth/register', {
        'username': username,
        'password': password,
        'displayName': username,
      }),
    );
  }

  Future<void> authenticate(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await request();
      token = data['token'] as String;
      api.token = token;
      currentUser = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token!);
      await afterLogin();
    } catch (exception) {
      error = exception.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await socketSub?.cancel();
    await channel?.sink.close();
    setState(() {
      token = null;
      api.token = null;
      currentUser = null;
      contacts.clear();
      chats.clear();
      messages.clear();
      pendingOutgoing.clear();
      peerActivities.clear();
      chatDrafts.clear();
      selectedChat = null;
    });
  }

  Future<void> deleteAccount() async {
    await api.delete('/api/me');
    await logout();
  }

  Future<void> updateAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (!mounted) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 82,
      maxWidth: 512,
      maxHeight: 512,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: widget.strings.changeAvatar,
          lockAspectRatio: true,
        ),
        WebUiSettings(context: context),
      ],
    );
    if (cropped == null) return;
    final bytes = await cropped.readAsBytes();
    final data = await api.postBytes('/api/me/avatar', bytes, 'image/jpeg');
    currentUser = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    await Future.wait([loadContacts(), loadChats()]);
    if (mounted) setState(() {});
  }

  Future<void> loadContacts() async {
    final data = await api.getJson('/api/contacts');
    contacts
      ..clear()
      ..addAll(
        (data['contacts'] as List).map(
          (item) => UserProfile.fromJson(item as Map<String, dynamic>),
        ),
      );
    if (mounted) setState(() {});
  }

  Future<void> loadChats() async {
    final data = await api.getJson('/api/chats');
    final previous = {for (final chat in chats) chat.id: chat};
    chats
      ..clear()
      ..addAll(
        (data['chats'] as List).map((item) {
          final chat = ChatSummary.fromJson(item as Map<String, dynamic>);
          final old = previous[chat.id];
          return chat.copyWith(
            draftText: chatDrafts[chat.id],
            pinned: old?.pinned == true ? true : chat.pinned,
            archived: old?.archived == true ? true : chat.archived,
          );
        }),
      );
    if (selectedChat != null) {
      selectedChat = chats
          .where((chat) => chat.id == selectedChat!.id)
          .firstOrNull;
    }
    if (mounted) setState(() {});
  }

  Future<List<UserProfile>> searchUsers(String username) async {
    final data = await api.getJson('/api/users/search', {'username': username});
    return (data['users'] as List)
        .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addContact(String username) async {
    await api.postJson('/api/contacts', {'username': username});
    await Future.wait([loadContacts(), loadChats()]);
  }

  Future<void> openChat(ChatSummary chat) async {
    selectedChat = chat;
    await loadMessagesForChat(chat.id);
    await markSelectedChatRead();
    if (mounted) setState(() {});
  }

  Future<void> loadMessagesForChat(String chatId) async {
    final data = await api.getJson(
      '/api/chats/${Uri.encodeComponent(chatId)}/messages',
    );
    messages[chatId] = (data['messages'] as List)
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markSelectedChatRead() async {
    final chat = selectedChat;
    final user = currentUser;
    if (chat == null || user == null) return;
    await api.markChatRead(chat.id);
    final list = messages[chat.id];
    if (list == null) return;
    messages[chat.id] = [
      for (final message in list)
        message.senderId == user.id
            ? message
            : message.copyWith(readByPeer: true),
    ];
    final index = chats.indexWhere((item) => item.id == chat.id);
    if (index != -1) {
      chats[index] = chats[index].copyWith(unreadCount: 0);
      selectedChat = chats[index];
    }
  }

  void closeSelectedChat() {
    setState(() => selectedChat = null);
  }

  Future<void> openChatById(String chatId) async {
    if (chats.isEmpty) await loadChats();
    final matches = chats.where((chat) => chat.id == chatId);
    if (matches.isEmpty) return;
    pendingNotificationChatId = null;
    await openChat(matches.first);
  }

  Future<void> openPendingNotificationChat() async {
    final chatId = pendingNotificationChatId;
    if (chatId == null || currentUser == null) return;
    await openChatById(chatId);
  }

  Future<void> sendMessage(String text, {ChatMessage? replyTo}) async {
    final chat = selectedChat;
    if (chat == null || text.trim().isEmpty) return;
    final value = text.trim();
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localMessage = ChatMessage(
      id: localId,
      chatId: chat.id,
      senderId: currentUser!.id,
      senderName: currentUser!.displayName,
      text: value,
      createdAt: DateTime.now().toIso8601String(),
      uploading: true,
      deliveryState: MessageDeliveryState.sending,
      replyToMessageId: replyTo?.id,
      replyToText: replyTo?.text,
      replyToSenderName: replyTo?.senderName,
      replyToType: replyTo == null
          ? null
          : (replyTo.voiceUrl != null || replyTo.localVoicePath != null)
          ? 'voice'
          : replyTo.attachment != null
          ? 'attachment'
          : 'text',
    );
    messages.putIfAbsent(chat.id, () => []).add(localMessage);
    pendingOutgoing[localId] = PendingOutgoing(
      localId: localId,
      chatId: chat.id,
      text: value,
      replyToMessageId: replyTo?.id,
    );
    if (mounted) setState(() {});
    try {
      final data = await api.sendMessage(
        chat.id,
        value,
        replyToMessageId: replyTo?.id,
      );
      final message = ChatMessage.fromJson(
        data['message'] as Map<String, dynamic>,
      );
      pendingOutgoing.remove(localId);
      replaceLocalMessageById(
        localId,
        message.copyWith(
          uploading: false,
          deliveryState: MessageDeliveryState.sent,
        ),
      );
      chatDrafts.remove(chat.id);
      await loadChats();
    } catch (_) {
      replaceLocalMessageById(
        localId,
        localMessage.copyWith(
          uploading: false,
          deliveryState: MessageDeliveryState.failed,
        ),
      );
    }
  }

  Future<void> sendAttachmentMessage(
    MessageAttachment attachment,
    Uint8List bytes, {
    String text = '',
    ChatMessage? replyTo,
  }) async {
    final chat = selectedChat;
    if (chat == null) return;
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localMessage = ChatMessage(
      id: localId,
      chatId: chat.id,
      senderId: currentUser!.id,
      senderName: currentUser!.displayName,
      text: text.trim(),
      createdAt: DateTime.now().toIso8601String(),
      uploading: true,
      deliveryState: MessageDeliveryState.sending,
      attachment: attachment,
      replyToMessageId: replyTo?.id,
      replyToText: replyTo?.text,
      replyToSenderName: replyTo?.senderName,
      replyToType: replyTo == null
          ? null
          : (replyTo.voiceUrl != null || replyTo.localVoicePath != null)
          ? 'voice'
          : replyTo.attachment != null
          ? 'attachment'
          : 'text',
    );
    messages.putIfAbsent(chat.id, () => []).add(localMessage);
    pendingOutgoing[localId] = PendingOutgoing(
      localId: localId,
      chatId: chat.id,
      text: text.trim(),
      replyToMessageId: replyTo?.id,
      attachment: attachment,
      bytes: bytes,
    );
    sendChatActivity(chat.id, ChatActivityKind.uploading, active: true);
    if (mounted) setState(() {});
    try {
      final data = await api.sendAttachmentMessage(
        chat.id,
        bytes,
        fileName: attachment.fileName,
        kind: attachment.kind,
        mimeType: attachment.mimeType,
        text: text,
        replyToMessageId: replyTo?.id,
      );
      final message = ChatMessage.fromJson(
        data['message'] as Map<String, dynamic>,
      );
      pendingOutgoing.remove(localId);
      replaceLocalMessageById(
        localId,
        message.copyWith(
          attachment: message.attachment?.copyWith(
            localPath: attachment.localPath,
            localBytes: attachment.localBytes,
          ),
          uploading: false,
          deliveryState: MessageDeliveryState.sent,
        ),
      );
      await loadChats();
    } catch (_) {
      replaceLocalMessageById(
        localId,
        localMessage.copyWith(
          uploading: false,
          deliveryState: MessageDeliveryState.failed,
        ),
      );
    } finally {
      sendChatActivity(chat.id, ChatActivityKind.uploading, active: false);
    }
  }

  Future<void> retryMessage(ChatMessage message) async {
    final pending = pendingOutgoing[message.id];
    if (pending == null) return;
    replaceLocalMessageById(
      message.id,
      message.copyWith(
        uploading: true,
        deliveryState: MessageDeliveryState.sending,
      ),
    );
    try {
      Map<String, dynamic> data;
      if (pending.isVoice) {
        final bytes = await XFile(pending.voicePath!).readAsBytes();
        data = await api.sendVoiceMessage(
          pending.chatId,
          bytes,
          durationSeconds: pending.voiceDurationSeconds,
        );
      } else if (pending.isAttachment) {
        sendChatActivity(
          pending.chatId,
          ChatActivityKind.uploading,
          active: true,
        );
        data = await api.sendAttachmentMessage(
          pending.chatId,
          pending.bytes!,
          fileName: pending.attachment!.fileName,
          kind: pending.attachment!.kind,
          mimeType: pending.attachment!.mimeType,
          text: pending.text,
          replyToMessageId: pending.replyToMessageId,
        );
      } else {
        data = await api.sendMessage(
          pending.chatId,
          pending.text,
          replyToMessageId: pending.replyToMessageId,
        );
      }
      final sent = ChatMessage.fromJson(
        data['message'] as Map<String, dynamic>,
      );
      pendingOutgoing.remove(message.id);
      replaceLocalMessageById(
        message.id,
        sent.copyWith(
          localVoicePath: message.localVoicePath,
          attachment: sent.attachment?.copyWith(
            localPath: message.attachment?.localPath,
            localBytes: message.attachment?.localBytes,
          ),
          uploading: false,
          deliveryState: MessageDeliveryState.sent,
        ),
      );
      await loadChats();
    } catch (_) {
      replaceLocalMessageById(
        message.id,
        message.copyWith(
          uploading: false,
          deliveryState: MessageDeliveryState.failed,
        ),
      );
    } finally {
      if (pending.isAttachment) {
        sendChatActivity(
          pending.chatId,
          ChatActivityKind.uploading,
          active: false,
        );
      }
    }
  }

  Future<void> editMessage(ChatMessage message, String text) async {
    if (text.trim().isEmpty) return;
    final data = await api.editMessage(message.chatId, message.id, text.trim());
    replaceLocalMessage(
      ChatMessage.fromJson(data['message'] as Map<String, dynamic>),
    );
    await loadChats();
  }

  Future<void> deleteSelectedMessages(List<ChatMessage> selected) async {
    if (selected.isEmpty) return;
    final chatId = selected.first.chatId;
    final ids = selected.map((message) => message.id).toList();
    await api.deleteMessages(chatId, ids);
    setState(
      () =>
          messages[chatId]?.removeWhere((message) => ids.contains(message.id)),
    );
    await loadChats();
  }

  Future<void> reactToMessage(ChatMessage message, String reaction) async {
    final data = await api.reactToMessage(message.chatId, message.id, reaction);
    final updated = data['message'];
    if (updated is Map<String, dynamic>) {
      replaceLocalMessage(ChatMessage.fromJson(updated));
      return;
    }
    final next = Map<String, int>.from(message.reactions);
    next[reaction] = (next[reaction] ?? 0) + 1;
    replaceLocalMessage(message.copyWith(reactions: next));
  }

  void applyPinState(String chatId, Object? rawPins) {
    final pinIds =
        (rawPins as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((pin) => pin['messageId']?.toString())
            .whereType<String>()
            .toSet() ??
        const <String>{};
    setState(() {
      final list = messages[chatId];
      if (list == null) return;
      messages[chatId] = [
        for (final message in list)
          message.copyWith(pinned: pinIds.contains(message.id)),
      ];
    });
  }

  Future<void> setMessagePinned(ChatMessage message, bool pinned) async {
    try {
      final data = await api.setMessagePinned(
        message.chatId,
        message.id,
        pinned,
      );
      if (!mounted) return;
      applyPinState(message.chatId, data['pins']);
      await loadMessagesForChat(message.chatId);
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update pinned message: $exception'),
          ),
        );
      }
    }
  }

  Future<void> clearPinnedMessages(String chatId) async {
    try {
      final data = await api.clearPinnedMessages(chatId);
      if (!mounted) return;
      applyPinState(chatId, data['pins']);
      await loadMessagesForChat(chatId);
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not clear pinned messages: $exception'),
          ),
        );
      }
    }
  }

  Future<void> setChatPinned(ChatSummary chat, bool pinned) async {
    final index = chats.indexWhere((item) => item.id == chat.id);
    if (index != -1) {
      setState(() {
        chats[index] = chats[index].copyWith(pinned: pinned);
        if (selectedChat?.id == chat.id) selectedChat = chats[index];
      });
    }
    try {
      await api.setChatPinned(chat.id, pinned);
      await loadChats();
    } catch (exception) {
      if (index != -1 && mounted) {
        setState(() {
          chats[index] = chats[index].copyWith(pinned: !pinned);
          if (selectedChat?.id == chat.id) selectedChat = chats[index];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update chat: $exception')),
        );
      }
    }
  }

  Future<void> setChatArchived(ChatSummary chat, bool archived) async {
    final index = chats.indexWhere((item) => item.id == chat.id);
    if (index != -1) {
      setState(() {
        chats[index] = chats[index].copyWith(archived: archived);
        if (selectedChat?.id == chat.id) selectedChat = chats[index];
      });
    }
    try {
      await api.setChatArchived(chat.id, archived);
      await loadChats();
    } catch (exception) {
      if (index != -1 && mounted) {
        setState(() {
          chats[index] = chats[index].copyWith(archived: !archived);
          if (selectedChat?.id == chat.id) selectedChat = chats[index];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update chat: $exception')),
        );
      }
    }
  }

  Future<List<ChatMessage>> searchMessages(String query) async {
    final chat = selectedChat;
    if (chat == null || query.trim().isEmpty) return const [];
    return api.searchMessages(chat.id, query.trim());
  }

  Future<void> setAutoDeleteSeconds(int seconds) async {
    final chat = selectedChat;
    if (chat == null) return;
    await api.setAutoDelete(chat.id, seconds);
  }

  Future<void> sendVoiceMessage(String path, int durationSeconds) async {
    final chat = selectedChat;
    if (chat == null) return;
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localMessage = ChatMessage(
      id: localId,
      chatId: chat.id,
      senderId: currentUser!.id,
      senderName: currentUser!.displayName,
      text: '',
      createdAt: DateTime.now().toIso8601String(),
      voiceDurationSeconds: durationSeconds,
      localVoicePath: path,
      uploading: true,
      deliveryState: MessageDeliveryState.sending,
    );
    messages.putIfAbsent(chat.id, () => []);
    messages[chat.id]!.add(localMessage);
    pendingVoicePaths.putIfAbsent(chat.id, () => []).add(path);
    pendingOutgoing[localId] = PendingOutgoing(
      localId: localId,
      chatId: chat.id,
      text: '',
      voicePath: path,
      voiceDurationSeconds: durationSeconds,
    );
    sendChatActivity(chat.id, ChatActivityKind.uploading, active: true);
    if (mounted) setState(() {});
    try {
      final bytes = await XFile(path).readAsBytes();
      final data = await api.sendVoiceMessage(
        chat.id,
        bytes,
        durationSeconds: durationSeconds,
      );
      final message =
          ChatMessage.fromJson(
            data['message'] as Map<String, dynamic>,
          ).copyWith(
            localVoicePath: path,
            uploading: false,
            deliveryState: MessageDeliveryState.sent,
          );
      pendingOutgoing.remove(localId);
      mergeIncomingMessage(message);
      await loadChats();
    } catch (_) {
      replaceLocalMessage(
        localMessage.copyWith(
          uploading: false,
          deliveryState: MessageDeliveryState.failed,
        ),
      );
    } finally {
      sendChatActivity(chat.id, ChatActivityKind.uploading, active: false);
    }
  }

  Future<void> demoLogin() async {
    await authenticate(() => api.postJson('/api/demo/seed', {}));
  }

  Future<void> seedDemoChats() async {
    await api.postJson('/api/demo/seed', {});
    await afterLogin();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading && currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (currentUser == null) {
      return AuthScreen(
        strings: widget.strings,
        error: error,
        onLogin: login,
        onRegister: register,
        onDemoLogin: demoLogin,
      );
    }
    return AppShell(
      strings: widget.strings,
      language: widget.language,
      themeMode: widget.themeMode,
      appStyle: widget.appStyle,
      onThemeChanged: widget.onThemeChanged,
      onStyleChanged: widget.onStyleChanged,
      onLanguageChanged: widget.onLanguageChanged,
      user: currentUser!,
      contacts: contacts,
      chats: chats,
      selectedChat: selectedChat,
      peerActivities: peerActivities,
      chatDrafts: chatDrafts,
      messages: selectedChat == null
          ? const []
          : messages[selectedChat!.id] ?? const [],
      voiceCall: voiceCall,
      onLogout: logout,
      onDeleteAccount: deleteAccount,
      onChangeAvatar: updateAvatar,
      onRefresh: () async => Future.wait([loadContacts(), loadChats()]),
      onSearch: searchUsers,
      onAddContact: addContact,
      onOpenChat: openChat,
      onSendMessage: sendMessage,
      onSendAttachmentMessage: sendAttachmentMessage,
      onRetryMessage: retryMessage,
      onComposerActivity: sendChatActivity,
      onDraftChanged: updateDraft,
      onEditMessage: editMessage,
      onDeleteMessages: deleteSelectedMessages,
      onReactToMessage: reactToMessage,
      onSetMessagePinned: setMessagePinned,
      onSetChatPinned: setChatPinned,
      onSetChatArchived: setChatArchived,
      onClearPinnedMessages: clearPinnedMessages,
      onSearchMessages: searchMessages,
      onSetAutoDeleteSeconds: setAutoDeleteSeconds,
      onSendVoiceMessage: sendVoiceMessage,
      onStartVoiceCall: startVoiceCall,
      onAcceptVoiceCall: acceptVoiceCall,
      onRejectVoiceCall: rejectVoiceCall,
      onEndVoiceCall: endVoiceCall,
      onToggleMute: toggleMute,
      onSetAudioRoute: setCallAudioRoute,
      onCloseChat: closeSelectedChat,
      onSeedDemoChats: seedDemoChats,
      apiBaseUrl: api.baseUrl,
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.strings,
    required this.error,
    required this.onLogin,
    required this.onRegister,
    required this.onDemoLogin,
  });

  final AppStrings strings;
  final String? error;
  final Future<void> Function(String username, String password) onLogin;
  final Future<void> Function(String username, String password) onRegister;
  final Future<void> Function() onDemoLogin;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool registerMode = false;
  bool busy = false;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => busy = true);
    if (registerMode) {
      await widget.onRegister(username.text, password.text);
    } else {
      await widget.onLogin(username.text, password.text);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.appBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.divider),
                boxShadow: premiumShadow(palette),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: palette.actionGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: premiumShadow(palette, opacity: 0.12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PremiumSegmented<bool>(
                    values: const [false, true],
                    selected: registerMode,
                    labelFor: (value) => value ? s.register : s.login,
                    iconFor: (value) => value ? Icons.person_add : Icons.login,
                    onChanged: (value) => setState(() => registerMode = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: username,
                    decoration: InputDecoration(
                      labelText: s.username,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: s.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  if (widget.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: palette.actionGradient,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: FilledButton.icon(
                      onPressed: busy ? null : submit,
                      icon: Icon(registerMode ? Icons.person_add : Icons.login),
                      label: Text(registerMode ? s.createAccount : s.login),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            setState(() => busy = true);
                            await widget.onDemoLogin();
                            if (mounted) setState(() => busy = false);
                          },
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(s.openDemo),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.strings,
    required this.language,
    required this.themeMode,
    required this.appStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
    required this.onLanguageChanged,
    required this.user,
    required this.contacts,
    required this.chats,
    required this.selectedChat,
    required this.peerActivities,
    required this.chatDrafts,
    required this.messages,
    required this.voiceCall,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onChangeAvatar,
    required this.onRefresh,
    required this.onSearch,
    required this.onAddContact,
    required this.onOpenChat,
    required this.onSendMessage,
    required this.onSendAttachmentMessage,
    required this.onRetryMessage,
    required this.onComposerActivity,
    required this.onDraftChanged,
    required this.onEditMessage,
    required this.onDeleteMessages,
    required this.onReactToMessage,
    required this.onSetMessagePinned,
    required this.onSetChatPinned,
    required this.onSetChatArchived,
    required this.onClearPinnedMessages,
    required this.onSearchMessages,
    required this.onSetAutoDeleteSeconds,
    required this.onSendVoiceMessage,
    required this.onStartVoiceCall,
    required this.onAcceptVoiceCall,
    required this.onRejectVoiceCall,
    required this.onEndVoiceCall,
    required this.onToggleMute,
    required this.onSetAudioRoute,
    required this.onCloseChat,
    required this.onSeedDemoChats,
    required this.apiBaseUrl,
  });

  final AppStrings strings;
  final AppLanguage language;
  final ThemeMode themeMode;
  final AppThemeStyle appStyle;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<AppThemeStyle> onStyleChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final UserProfile user;
  final List<UserProfile> contacts;
  final List<ChatSummary> chats;
  final ChatSummary? selectedChat;
  final Map<String, PeerActivity> peerActivities;
  final Map<String, String> chatDrafts;
  final List<ChatMessage> messages;
  final VoiceCallSession? voiceCall;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;
  final Future<void> Function() onChangeAvatar;
  final Future<void> Function() onRefresh;
  final Future<List<UserProfile>> Function(String username) onSearch;
  final Future<void> Function(String username) onAddContact;
  final Future<void> Function(ChatSummary chat) onOpenChat;
  final Future<void> Function(String text, {ChatMessage? replyTo})
  onSendMessage;
  final Future<void> Function(
    MessageAttachment attachment,
    Uint8List bytes, {
    String text,
    ChatMessage? replyTo,
  })
  onSendAttachmentMessage;
  final Future<void> Function(ChatMessage message) onRetryMessage;
  final void Function(
    String chatId,
    ChatActivityKind activity, {
    required bool active,
  })
  onComposerActivity;
  final void Function(String chatId, String value) onDraftChanged;
  final Future<void> Function(ChatMessage message, String text) onEditMessage;
  final Future<void> Function(List<ChatMessage> messages) onDeleteMessages;
  final Future<void> Function(ChatMessage message, String reaction)
  onReactToMessage;
  final Future<void> Function(ChatMessage message, bool pinned)
  onSetMessagePinned;
  final Future<void> Function(ChatSummary chat, bool pinned) onSetChatPinned;
  final Future<void> Function(ChatSummary chat, bool archived)
  onSetChatArchived;
  final Future<void> Function(String chatId) onClearPinnedMessages;
  final Future<List<ChatMessage>> Function(String query) onSearchMessages;
  final Future<void> Function(int seconds) onSetAutoDeleteSeconds;
  final Future<void> Function(String path, int durationSeconds)
  onSendVoiceMessage;
  final Future<void> Function(ChatSummary chat) onStartVoiceCall;
  final Future<void> Function() onAcceptVoiceCall;
  final Future<void> Function() onRejectVoiceCall;
  final Future<void> Function() onEndVoiceCall;
  final Future<void> Function() onToggleMute;
  final Future<void> Function(AudioRoute route) onSetAudioRoute;
  final VoidCallback onCloseChat;
  final Future<void> Function() onSeedDemoChats;
  final String apiBaseUrl;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool contactsMode = false;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final sidebar = Sidebar(
      strings: widget.strings,
      language: widget.language,
      themeMode: widget.themeMode,
      appStyle: widget.appStyle,
      onThemeChanged: widget.onThemeChanged,
      onStyleChanged: widget.onStyleChanged,
      onLanguageChanged: widget.onLanguageChanged,
      user: widget.user,
      apiBaseUrl: widget.apiBaseUrl,
      contactsMode: contactsMode,
      contacts: widget.contacts,
      chats: widget.chats,
      selectedChat: widget.selectedChat,
      peerActivities: widget.peerActivities,
      onModeChanged: (value) => setState(() => contactsMode = value),
      onLogout: widget.onLogout,
      onDeleteAccount: widget.onDeleteAccount,
      onChangeAvatar: widget.onChangeAvatar,
      onRefresh: widget.onRefresh,
      onSearch: widget.onSearch,
      onAddContact: widget.onAddContact,
      onOpenChat: widget.onOpenChat,
      onSetChatPinned: widget.onSetChatPinned,
      onSetChatArchived: widget.onSetChatArchived,
      onSeedDemoChats: widget.onSeedDemoChats,
    );
    final chat = ChatPane(
      strings: widget.strings,
      user: widget.user,
      chat: widget.selectedChat,
      apiBaseUrl: widget.apiBaseUrl,
      messages: widget.messages,
      peerActivity: widget.selectedChat == null
          ? null
          : widget.peerActivities[widget.selectedChat!.id],
      draftText: widget.selectedChat == null
          ? ''
          : widget.chatDrafts[widget.selectedChat!.id] ?? '',
      onBack: wide ? null : widget.onCloseChat,
      onSend: widget.onSendMessage,
      onSendAttachment: widget.onSendAttachmentMessage,
      onRetryMessage: widget.onRetryMessage,
      onComposerActivity: widget.onComposerActivity,
      onDraftChanged: widget.onDraftChanged,
      onEditMessage: widget.onEditMessage,
      onDeleteMessages: widget.onDeleteMessages,
      onReactToMessage: widget.onReactToMessage,
      onSetMessagePinned: widget.onSetMessagePinned,
      onClearPinnedMessages: widget.onClearPinnedMessages,
      onSearchMessages: widget.onSearchMessages,
      onSetAutoDeleteSeconds: widget.onSetAutoDeleteSeconds,
      onSendVoiceMessage: widget.onSendVoiceMessage,
      onStartVoiceCall: widget.onStartVoiceCall,
    );
    return Scaffold(
      backgroundColor: AppPalette.of(context).appBackground,
      body: Stack(
        children: [
          SafeArea(
            child: wide
                ? Row(
                    children: [
                      SizedBox(width: 360, child: sidebar),
                      VerticalDivider(
                        width: 1,
                        color: AppPalette.of(context).divider,
                      ),
                      Expanded(
                        child: Container(
                          color: AppPalette.of(context).appBackground,
                          child: chat,
                        ),
                      ),
                    ],
                  )
                : widget.selectedChat == null
                ? sidebar
                : Container(
                    color: AppPalette.of(context).appBackground,
                    child: chat,
                  ),
          ),
          if (widget.voiceCall != null)
            VoiceCallScreen(
              strings: widget.strings,
              session: widget.voiceCall!,
              apiBaseUrl: widget.apiBaseUrl,
              onAccept: widget.onAcceptVoiceCall,
              onReject: widget.onRejectVoiceCall,
              onEnd: widget.onEndVoiceCall,
              onToggleMute: widget.onToggleMute,
              onSetAudioRoute: widget.onSetAudioRoute,
            ),
        ],
      ),
    );
  }
}

String initialsFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.apiBaseUrl,
    required this.name,
    this.avatarUrl,
    this.radius = 20,
    this.icon,
  });

  final String apiBaseUrl;
  final String name;
  final String? avatarUrl;
  final double radius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final url = mediaUrl(apiBaseUrl, avatarUrl);
    final palette = AppPalette.of(context);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: palette.actionGradient,
        border: Border.all(
          color: palette.surface.withValues(alpha: 0.95),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: url.isEmpty
            ? Center(
                child: icon == null
                    ? Text(
                        initialsFor(name),
                        style: TextStyle(
                          color: palette.textOnOutgoing,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Icon(icon, color: palette.textOnOutgoing),
              )
            : Image.network(url, fit: BoxFit.cover),
      ),
    );
  }
}

class PresenceAvatar extends StatelessWidget {
  const PresenceAvatar({
    super.key,
    required this.apiBaseUrl,
    required this.name,
    this.avatarUrl,
    required this.online,
    this.radius = 20,
  });

  final String apiBaseUrl;
  final String name;
  final String? avatarUrl;
  final bool online;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.all(online ? 2.5 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: online
              ? AppPalette.of(context).onlineRing
              : Colors.transparent,
          width: online ? 2 : 0,
        ),
        boxShadow: online
            ? [
                BoxShadow(
                  color: AppPalette.of(
                    context,
                  ).onlineRing.withValues(alpha: 0.24),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: UserAvatar(
        apiBaseUrl: apiBaseUrl,
        name: name,
        avatarUrl: avatarUrl,
        radius: radius,
      ),
    );
  }
}

class Sidebar extends StatefulWidget {
  const Sidebar({
    super.key,
    required this.strings,
    required this.language,
    required this.themeMode,
    required this.appStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
    required this.onLanguageChanged,
    required this.user,
    required this.apiBaseUrl,
    required this.contactsMode,
    required this.contacts,
    required this.chats,
    required this.selectedChat,
    required this.peerActivities,
    required this.onModeChanged,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onChangeAvatar,
    required this.onRefresh,
    required this.onSearch,
    required this.onAddContact,
    required this.onOpenChat,
    required this.onSetChatPinned,
    required this.onSetChatArchived,
    required this.onSeedDemoChats,
  });

  final AppStrings strings;
  final AppLanguage language;
  final ThemeMode themeMode;
  final AppThemeStyle appStyle;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<AppThemeStyle> onStyleChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final UserProfile user;
  final String apiBaseUrl;
  final bool contactsMode;
  final List<UserProfile> contacts;
  final List<ChatSummary> chats;
  final ChatSummary? selectedChat;
  final Map<String, PeerActivity> peerActivities;
  final ValueChanged<bool> onModeChanged;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;
  final Future<void> Function() onChangeAvatar;
  final Future<void> Function() onRefresh;
  final Future<List<UserProfile>> Function(String username) onSearch;
  final Future<void> Function(String username) onAddContact;
  final Future<void> Function(ChatSummary chat) onOpenChat;
  final Future<void> Function(ChatSummary chat, bool pinned) onSetChatPinned;
  final Future<void> Function(ChatSummary chat, bool archived)
  onSetChatArchived;
  final Future<void> Function() onSeedDemoChats;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final search = TextEditingController();
  List<UserProfile> results = const [];
  bool searching = false;
  bool seedingDemo = false;
  ChatListFilter chatFilter = ChatListFilter.active;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> runSearch() async {
    if (search.text.trim().isEmpty) return;
    setState(() => searching = true);
    try {
      results = await widget.onSearch(search.text.trim());
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> showSettings() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final palette = AppPalette.of(context);
        return AlertDialog(
          backgroundColor: palette.surface,
          title: Text(widget.strings.settings),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surfaceSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.divider),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UserAvatar(
                      apiBaseUrl: widget.apiBaseUrl,
                      name: widget.user.displayName,
                      avatarUrl: widget.user.avatarUrl,
                      radius: 22,
                    ),
                    title: Text(
                      widget.user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '@${widget.user.username}',
                      style: TextStyle(color: palette.textMuted),
                    ),
                    trailing: PremiumIconButton(
                      icon: Icons.photo_camera_outlined,
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await widget.onChangeAvatar();
                      },
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await widget.onChangeAvatar();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SettingsControl(
                  icon: Icons.palette_outlined,
                  label: 'Style',
                  control: SizedBox(
                    width: 238,
                    child: PremiumSegmented<AppThemeStyle>(
                      values: AppThemeStyle.values,
                      selected: widget.appStyle,
                      labelFor: (style) => style == AppThemeStyle.coffeeWood
                          ? 'CoffeeWood'
                          : 'Blue',
                      iconFor: (_) => null,
                      onChanged: widget.onStyleChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SettingsControl(
                  icon: Icons.light_mode,
                  label: widget.strings.theme,
                  control: SizedBox(
                    width: 238,
                    child: PremiumSegmented<ThemeMode>(
                      values: const [ThemeMode.light, ThemeMode.dark],
                      selected: widget.themeMode == ThemeMode.dark
                          ? ThemeMode.dark
                          : ThemeMode.light,
                      labelFor: (mode) => mode == ThemeMode.dark
                          ? widget.strings.dark
                          : widget.strings.light,
                      iconFor: (mode) => mode == ThemeMode.dark
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      onChanged: widget.onThemeChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SettingsControl(
                  icon: Icons.language,
                  label: widget.strings.languageLabel,
                  control: DropdownButton<AppLanguage>(
                    value: widget.language,
                    isDense: true,
                    items: [
                      DropdownMenuItem(
                        value: AppLanguage.en,
                        child: Text(widget.strings.english),
                      ),
                      DropdownMenuItem(
                        value: AppLanguage.ru,
                        child: Text(widget.strings.russian),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) widget.onLanguageChanged(value);
                    },
                  ),
                ),
                const Divider(height: 28),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline),
                  title: Text(
                    widget.strings.deleteAccount,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await widget.onDeleteAccount();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.strings.close),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final palette = AppPalette.of(context);
    return Container(
      color: palette.chatBackground,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(bottom: BorderSide(color: palette.divider)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                PremiumIconButton(
                  icon: Icons.menu,
                  onPressed: showSettings,
                  tooltip: s.settings,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.appName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.chats.where((chat) => chat.peerOnline).length} chats online',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PremiumIconButton(
                  icon: Icons.add,
                  filled: true,
                  onPressed: seedingDemo
                      ? null
                      : () async {
                          setState(() => seedingDemo = true);
                          await widget.onSeedDemoChats();
                          if (mounted) setState(() => seedingDemo = false);
                        },
                  tooltip: s.addDemoChats,
                ),
                PremiumIconButton(
                  onPressed: widget.onRefresh,
                  icon: Icons.refresh,
                  tooltip: s.refresh,
                ),
                PremiumIconButton(
                  onPressed: widget.onLogout,
                  icon: Icons.logout,
                  tooltip: s.logout,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: PremiumSearchField(
              controller: search,
              hint: widget.contactsMode
                  ? s.findUsername
                  : 'Search chats or contacts',
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (widget.contactsMode) unawaited(runSearch());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PremiumSegmented<bool>(
              values: const [false, true],
              selected: widget.contactsMode,
              labelFor: (value) => value ? s.contacts : s.chats,
              iconFor: (value) =>
                  value ? Icons.people_outline : Icons.forum_outlined,
              onChanged: widget.onModeChanged,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: widget.contactsMode
                ? contactsView(context)
                : chatsView(context),
          ),
        ],
      ),
    );
  }

  Future<void> showChatMenu(ChatSummary chat) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        final palette = AppPalette.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.divider),
                boxShadow: premiumShadow(palette, opacity: 0.20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      chat.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    ),
                    title: Text(chat.pinned ? 'Unpin chat' : 'Pin chat'),
                    onTap: () => Navigator.of(context).pop('pin'),
                  ),
                  ListTile(
                    leading: Icon(
                      chat.archived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                    title: Text(
                      chat.archived ? 'Unarchive chat' : 'Archive chat',
                    ),
                    onTap: () => Navigator.of(context).pop('archive'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (action == 'pin') {
      await widget.onSetChatPinned(chat, !chat.pinned);
    } else if (action == 'archive') {
      await widget.onSetChatArchived(chat, !chat.archived);
    }
  }

  Widget chatsView(BuildContext context) {
    final s = widget.strings;
    final palette = AppPalette.of(context);
    if (widget.chats.isEmpty) {
      return Center(
        child: Container(
          height: 130,
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: palette.textMuted.withValues(alpha: 0.34),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.addContactToStart,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textMuted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: seedingDemo
                    ? null
                    : () async {
                        setState(() => seedingDemo = true);
                        await widget.onSeedDemoChats();
                        if (mounted) setState(() => seedingDemo = false);
                      },
                icon: const Icon(Icons.auto_awesome),
                label: Text(s.addDemoChats),
              ),
            ],
          ),
        ),
      );
    }
    final query = search.text.trim().toLowerCase();
    final filteredByMode =
        widget.chats.where((chat) {
          switch (chatFilter) {
            case ChatListFilter.active:
              return !chat.archived;
            case ChatListFilter.unread:
              return !chat.archived && chat.unreadCount > 0;
            case ChatListFilter.archived:
              return chat.archived;
          }
        }).toList()..sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return (b.lastAt ?? '').compareTo(a.lastAt ?? '');
        });
    final visibleChats = query.isEmpty
        ? filteredByMode
        : filteredByMode
              .where(
                (chat) =>
                    chat.peerDisplayName.toLowerCase().contains(query) ||
                    chat.peerUsername.toLowerCase().contains(query) ||
                    lastMessagePreview(chat).toLowerCase().contains(query),
              )
              .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: PremiumSegmented<ChatListFilter>(
            values: ChatListFilter.values,
            selected: chatFilter,
            labelFor: (value) => switch (value) {
              ChatListFilter.active => 'All',
              ChatListFilter.unread => 'Unread',
              ChatListFilter.archived => 'Archive',
            },
            iconFor: (value) => switch (value) {
              ChatListFilter.active => Icons.inbox_outlined,
              ChatListFilter.unread => Icons.mark_chat_unread_outlined,
              ChatListFilter.archived => Icons.archive_outlined,
            },
            onChanged: (value) => setState(() => chatFilter = value),
          ),
        ),
        Expanded(
          child: visibleChats.isEmpty
              ? Center(
                  child: Text(
                    chatFilter == ChatListFilter.archived
                        ? 'No archived chats'
                        : 'No chats match this filter',
                    style: TextStyle(color: palette.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 14),
                  itemCount: visibleChats.length,
                  itemBuilder: (context, index) {
                    final chat = visibleChats[index];
                    final activity = widget.peerActivities[chat.id];
                    final activityText = activity?.active == true
                        ? activityLabel(activity!.kind)
                        : null;
                    final lastAt = chat.lastAt == null
                        ? ''
                        : messageClock(chat.lastAt!);
                    final selected = widget.selectedChat?.id == chat.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () => widget.onOpenChat(chat),
                        onLongPress: () => showChatMenu(chat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          constraints: const BoxConstraints(minHeight: 62),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? palette.selectedRow
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              PresenceAvatar(
                                apiBaseUrl: widget.apiBaseUrl,
                                name: chat.peerDisplayName,
                                avatarUrl: chat.peerAvatarUrl,
                                online: chat.peerOnline,
                                radius: 17,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        if (chat.pinned) ...[
                                          Icon(
                                            Icons.push_pin,
                                            size: 13,
                                            color: palette.accentStrong,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Expanded(
                                          child: Text(
                                            chat.peerDisplayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      activityText ??
                                          (chat.lastAt == null
                                              ? peerStatus(chat)
                                              : '${lastMessagePreview(chat)}  ${chat.peerOnline ? 'online' : peerStatus(chat)}'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: activityText == null
                                            ? palette.textMuted
                                            : palette.accentStrong,
                                        fontSize: 12,
                                        fontWeight: activityText == null
                                            ? FontWeight.w400
                                            : FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (lastAt.isNotEmpty)
                                    Text(
                                      lastAt,
                                      style: TextStyle(
                                        color: palette.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  if (chat.unreadCount > 0) ...[
                                    const SizedBox(height: 5),
                                    Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.accent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        chat.unreadCount > 99
                                            ? '99+'
                                            : chat.unreadCount.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: palette.textOnOutgoing,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Chat actions',
                                icon: Icon(
                                  Icons.more_vert,
                                  color: palette.textMuted,
                                  size: 20,
                                ),
                                onSelected: (value) async {
                                  if (value == 'pin') {
                                    await widget.onSetChatPinned(
                                      chat,
                                      !chat.pinned,
                                    );
                                  } else if (value == 'archive') {
                                    await widget.onSetChatArchived(
                                      chat,
                                      !chat.archived,
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'pin',
                                    child: Text(chat.pinned ? 'Unpin' : 'Pin'),
                                  ),
                                  PopupMenuItem(
                                    value: 'archive',
                                    child: Text(
                                      chat.archived ? 'Unarchive' : 'Archive',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget contactsView(BuildContext context) {
    final s = widget.strings;
    final palette = AppPalette.of(context);
    Widget emptyState(String text) => Center(
      child: Container(
        height: 130,
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.textMuted.withValues(alpha: 0.34)),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted),
          ),
        ),
      ),
    );

    return Column(
      children: [
        if (search.text.trim().isNotEmpty && results.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: searching ? null : runSearch,
                icon: const Icon(Icons.person_add_alt),
                label: Text(s.findUsername),
              ),
            ),
          ),
        if (results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Column(
              children: results.map((user) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: palette.divider),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: UserAvatar(
                      apiBaseUrl: widget.apiBaseUrl,
                      name: user.displayName,
                      avatarUrl: user.avatarUrl,
                      icon: Icons.person_add_alt,
                    ),
                    title: Text(user.displayName),
                    subtitle: Text(
                      '@${user.username}',
                      style: TextStyle(color: palette.textMuted),
                    ),
                    trailing: PremiumIconButton(
                      icon: Icons.add,
                      filled: true,
                      onPressed: () async {
                        await widget.onAddContact(user.username);
                        search.clear();
                        setState(() => results = const []);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        Divider(height: 24, color: palette.divider),
        Expanded(
          child: widget.contacts.isEmpty
              ? emptyState(s.noContacts)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                  children: widget.contacts.map((contact) {
                    final chatMatches = widget.chats.where(
                      (chat) => chat.peerId == contact.id,
                    );
                    final chat = chatMatches.isEmpty ? null : chatMatches.first;
                    final status = chat == null
                        ? '@${contact.username}'
                        : '${peerStatus(chat)} · @${contact.username}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 62),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            PresenceAvatar(
                              apiBaseUrl: widget.apiBaseUrl,
                              name: contact.displayName,
                              avatarUrl: contact.avatarUrl,
                              online: chat?.peerOnline ?? false,
                              radius: 17,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    contact.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class SettingsControl extends StatelessWidget {
  const SettingsControl({
    super.key,
    required this.icon,
    required this.label,
    required this.control,
  });

  final IconData icon;
  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final title = Row(
          children: [
            Icon(icon, color: palette.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.textPrimary),
              ),
            ),
          ],
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surfaceSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.divider),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: control),
                  ],
                )
              : Row(
                  children: [
                    Icon(icon, color: palette.textMuted),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(flex: 0, child: control),
                  ],
                ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  const WaveformPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final inactive = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const bars = 34;
    final gap = size.width / bars;
    for (var i = 0; i < bars; i++) {
      final wave = math.sin(i * 0.72).abs();
      final h = 5 + wave * (size.height - 6);
      final x = i * gap + gap / 2;
      final paint = i / bars <= progress ? active : inactive;
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}

class VoiceCallScreen extends StatelessWidget {
  const VoiceCallScreen({
    super.key,
    required this.strings,
    required this.session,
    required this.apiBaseUrl,
    required this.onAccept,
    required this.onReject,
    required this.onEnd,
    required this.onToggleMute,
    required this.onSetAudioRoute,
  });

  final AppStrings strings;
  final VoiceCallSession session;
  final String apiBaseUrl;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;
  final Future<void> Function() onEnd;
  final Future<void> Function() onToggleMute;
  final Future<void> Function(AudioRoute route) onSetAudioRoute;

  String get status => switch (session.phase) {
    VoiceCallPhase.outgoing => strings.calling,
    VoiceCallPhase.incoming => strings.incomingCall,
    VoiceCallPhase.connecting => strings.connectingCall,
    VoiceCallPhase.active => strings.callActive,
    VoiceCallPhase.idle => strings.voiceCall,
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final canChangeRoute = !kIsWeb && session.phase != VoiceCallPhase.incoming;
    return Positioned.fill(
      child: Material(
        color: palette.appBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              children: [
                const Spacer(),
                UserAvatar(
                  apiBaseUrl: apiBaseUrl,
                  name: session.peerName,
                  avatarUrl: session.peerAvatarUrl,
                  radius: 56,
                ),
                const SizedBox(height: 22),
                Text(
                  session.peerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: palette.textMuted),
                ),
                const Spacer(),
                if (session.phase != VoiceCallPhase.incoming)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _RoundCallButton(
                        label: session.muted ? strings.unmute : strings.mute,
                        icon: session.muted ? Icons.mic_off : Icons.mic,
                        onPressed: onToggleMute,
                        selected: session.muted,
                      ),
                      _RoundCallButton(
                        label: strings.earpiece,
                        icon: Icons.phone_in_talk,
                        onPressed: canChangeRoute
                            ? () => onSetAudioRoute(AudioRoute.earpiece)
                            : null,
                        selected: session.audioRoute == AudioRoute.earpiece,
                      ),
                      _RoundCallButton(
                        label: strings.speaker,
                        icon: Icons.volume_up,
                        onPressed: canChangeRoute
                            ? () => onSetAudioRoute(AudioRoute.speaker)
                            : null,
                        selected: session.audioRoute == AudioRoute.speaker,
                      ),
                      if (!kIsWeb)
                        _RoundCallButton(
                          label: strings.bluetooth,
                          icon: Icons.bluetooth_audio,
                          onPressed: canChangeRoute
                              ? () => onSetAudioRoute(AudioRoute.bluetooth)
                              : null,
                          selected: session.audioRoute == AudioRoute.bluetooth,
                        ),
                    ],
                  ),
                const SizedBox(height: 34),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (session.phase == VoiceCallPhase.incoming) ...[
                      _CallActionButton(
                        label: strings.decline,
                        icon: Icons.call_end,
                        backgroundColor: palette.danger,
                        foregroundColor: Colors.white,
                        onPressed: onReject,
                      ),
                      const SizedBox(width: 32),
                      _CallActionButton(
                        label: strings.answer,
                        icon: Icons.call,
                        backgroundColor: palette.accent,
                        foregroundColor: Colors.white,
                        onPressed: onAccept,
                      ),
                    ] else
                      _CallActionButton(
                        label: strings.endCall,
                        icon: Icons.call_end,
                        backgroundColor: palette.danger,
                        foregroundColor: Colors.white,
                        onPressed: onEnd,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundCallButton extends StatelessWidget {
  const _RoundCallButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final Future<void> Function()? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      width: 82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              fixedSize: const Size.square(58),
              backgroundColor: selected
                  ? palette.accentSoft
                  : palette.surfaceRaised,
              foregroundColor: selected
                  ? palette.accentStrong
                  : palette.textPrimary,
            ),
            onPressed: onPressed,
            icon: Icon(icon),
            tooltip: label,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            fixedSize: const Size.square(52),
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 26),
          tooltip: label,
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class ChatPane extends StatefulWidget {
  const ChatPane({
    super.key,
    required this.strings,
    required this.user,
    required this.chat,
    required this.apiBaseUrl,
    required this.messages,
    required this.peerActivity,
    required this.draftText,
    required this.onBack,
    required this.onSend,
    required this.onSendAttachment,
    required this.onRetryMessage,
    required this.onComposerActivity,
    required this.onDraftChanged,
    required this.onEditMessage,
    required this.onDeleteMessages,
    required this.onReactToMessage,
    required this.onSetMessagePinned,
    required this.onClearPinnedMessages,
    required this.onSearchMessages,
    required this.onSetAutoDeleteSeconds,
    required this.onSendVoiceMessage,
    required this.onStartVoiceCall,
  });

  final AppStrings strings;
  final UserProfile user;
  final ChatSummary? chat;
  final String apiBaseUrl;
  final List<ChatMessage> messages;
  final PeerActivity? peerActivity;
  final String draftText;
  final VoidCallback? onBack;
  final Future<void> Function(String text, {ChatMessage? replyTo}) onSend;
  final Future<void> Function(
    MessageAttachment attachment,
    Uint8List bytes, {
    String text,
    ChatMessage? replyTo,
  })
  onSendAttachment;
  final Future<void> Function(ChatMessage message) onRetryMessage;
  final void Function(
    String chatId,
    ChatActivityKind activity, {
    required bool active,
  })
  onComposerActivity;
  final void Function(String chatId, String value) onDraftChanged;
  final Future<void> Function(ChatMessage message, String text) onEditMessage;
  final Future<void> Function(List<ChatMessage> messages) onDeleteMessages;
  final Future<void> Function(ChatMessage message, String reaction)
  onReactToMessage;
  final Future<void> Function(ChatMessage message, bool pinned)
  onSetMessagePinned;
  final Future<void> Function(String chatId) onClearPinnedMessages;
  final Future<List<ChatMessage>> Function(String query) onSearchMessages;
  final Future<void> Function(int seconds) onSetAutoDeleteSeconds;
  final Future<void> Function(String path, int durationSeconds)
  onSendVoiceMessage;
  final Future<void> Function(ChatSummary chat) onStartVoiceCall;

  @override
  State<ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<ChatPane> {
  final text = TextEditingController();
  final search = TextEditingController();
  final scroll = ScrollController();
  final selectedIds = <String>{};
  final highlightedIds = <String>{};
  final voiceRecorder = AudioRecorder();
  final voicePlayer = AudioPlayer();
  ChatMessage? editingMessage;
  bool searchOpen = false;
  bool searching = false;
  bool recordingVoice = false;
  bool backSwipeArmed = false;
  DateTime? recordStartedAt;
  String? playingVoiceId;
  StreamSubscription<void>? playerCompleteSub;
  ChatMessage? replyingTo;
  String? swipingMessageId;
  double swipeOffset = 0;
  Timer? typingStopTimer;
  bool typingActive = false;

  @override
  void initState() {
    super.initState();
    text.text = widget.draftText;
    text.addListener(() {
      final chatId = widget.chat?.id;
      if (chatId != null) {
        widget.onDraftChanged(chatId, text.text);
        updateTypingActivity(chatId);
      }
      if (mounted) setState(() {});
    });
    playerCompleteSub = voicePlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playingVoiceId = null);
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => scheduleScrollToBottom(),
    );
  }

  @override
  void dispose() {
    text.dispose();
    search.dispose();
    scroll.dispose();
    typingStopTimer?.cancel();
    stopTypingActivity();
    playerCompleteSub?.cancel();
    voicePlayer.dispose();
    unawaited(voiceRecorder.dispose());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chat?.id != oldWidget.chat?.id ||
        widget.messages.length != oldWidget.messages.length) {
      if (widget.chat?.id != oldWidget.chat?.id) {
        typingStopTimer?.cancel();
        typingActive = false;
        text.text = widget.draftText;
      }
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => scheduleScrollToBottom(),
      );
    }
  }

  void scheduleScrollToBottom() {
    scrollToBottom(jump: true);
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) scrollToBottom(jump: true);
    });
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) scrollToBottom(jump: true);
    });
  }

  void scrollToBottom({bool jump = false}) {
    if (!scroll.hasClients) return;
    final target = scroll.position.maxScrollExtent;
    if (jump) {
      scroll.jumpTo(target);
      return;
    }
    unawaited(
      scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void updateTypingActivity(String chatId) {
    if (text.text.trim().isEmpty || recordingVoice) {
      stopTypingActivity();
      return;
    }
    if (!typingActive) {
      typingActive = true;
      widget.onComposerActivity(chatId, ChatActivityKind.typing, active: true);
    }
    typingStopTimer?.cancel();
    typingStopTimer = Timer(const Duration(milliseconds: 1400), () {
      stopTypingActivity();
    });
  }

  void stopTypingActivity() {
    final chatId = widget.chat?.id;
    if (chatId != null && typingActive) {
      widget.onComposerActivity(chatId, ChatActivityKind.typing, active: false);
    }
    typingActive = false;
    typingStopTimer?.cancel();
    typingStopTimer = null;
  }

  Future<void> submit() async {
    final value = text.text;
    text.clear();
    stopTypingActivity();
    final editing = editingMessage;
    if (editing == null) {
      final reply = replyingTo;
      setState(() => replyingTo = null);
      await widget.onSend(value, replyTo: reply);
    } else {
      await widget.onEditMessage(editing, value);
      setState(() => editingMessage = null);
    }
  }

  void toggleSelection(ChatMessage message) {
    setState(() {
      if (!selectedIds.add(message.id)) selectedIds.remove(message.id);
      if (selectedIds.isEmpty) editingMessage = null;
    });
  }

  void selectAll() {
    setState(
      () => selectedIds
        ..clear()
        ..addAll(widget.messages.map((message) => message.id)),
    );
  }

  void clearSelection() {
    setState(() => selectedIds.clear());
  }

  List<ChatMessage> selectedMessages() => widget.messages
      .where((message) => selectedIds.contains(message.id))
      .toList();

  Future<void> copySelected() async {
    final value = selectedMessages()
        .map((message) => message.text)
        .where((value) => value.isNotEmpty)
        .join('\n');
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    clearSelection();
  }

  Future<void> deleteSelected() async {
    final selected = selectedMessages();
    if (selected.isEmpty) return;
    await widget.onDeleteMessages(selected);
    clearSelection();
  }

  Future<void> copyMessage(ChatMessage message) async {
    if (message.text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: message.text));
  }

  Future<void> deleteMessage(ChatMessage message) async {
    await widget.onDeleteMessages([message]);
    selectedIds.remove(message.id);
    if (mounted) setState(() {});
  }

  void startEdit(ChatMessage message) {
    if (message.senderId != widget.user.id ||
        message.voiceUrl != null ||
        message.localVoicePath != null ||
        message.attachment != null) {
      return;
    }
    setState(() {
      editingMessage = message;
      replyingTo = null;
      text.text = message.text;
      selectedIds.clear();
    });
  }

  void startReply(ChatMessage message) {
    HapticFeedback.selectionClick();
    setState(() {
      replyingTo = message;
      editingMessage = null;
      selectedIds.clear();
      swipingMessageId = null;
      swipeOffset = 0;
    });
  }

  Future<void> pickReaction(ChatMessage message) async {
    final reaction = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        final palette = AppPalette.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.divider),
                boxShadow: premiumShadow(palette, opacity: 0.20),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: ['👍', '❤️', '😂', '😮', '😢', '🔥']
                    .map(
                      (emoji) => InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context).pop(emoji),
                        child: Container(
                          width: 48,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.reaction,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: palette.accent.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
    if (reaction != null) await widget.onReactToMessage(message, reaction);
  }

  Widget bottomSheetOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final palette = AppPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, color: palette.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showMessageMenu(ChatMessage message, Offset position) async {
    final mine = message.senderId == widget.user.id;
    final palette = AppPalette.of(context);
    final screen = MediaQuery.sizeOf(context);
    final left = math.min(
      math.max(14.0, position.dx - 110),
      screen.width - 234,
    );
    final top = math.min(math.max(82.0, position.dy - 24), screen.height - 330);
    final action = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Message menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, animation, secondaryAnimation) {
        Widget item(String value, String label) {
          final danger = value == 'delete';
          return InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => Navigator.of(context).pop(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Text(
                label,
                style: TextStyle(
                  color: danger ? palette.danger : palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: 220,
              child: Material(
                color: Colors.transparent,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 34,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        item('reply', 'Reply'),
                        item('react', 'React'),
                        item(
                          'pin',
                          message.pinned ? 'Unpin message' : 'Pin message',
                        ),
                        if (message.text.trim().isNotEmpty)
                          item('copy', 'Copy'),
                        if (mine &&
                            message.voiceUrl == null &&
                            message.localVoicePath == null &&
                            message.attachment == null)
                          item('edit', 'Edit'),
                        item('select', 'Select'),
                        item('delete', 'Delete'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'copy':
        await copyMessage(message);
      case 'reply':
        startReply(message);
      case 'react':
        await pickReaction(message);
      case 'pin':
        await widget.onSetMessagePinned(message, !message.pinned);
      case 'edit':
        startEdit(message);
      case 'select':
        toggleSelection(message);
      case 'delete':
        await deleteMessage(message);
    }
  }

  Future<void> showAutoDeleteSettings() async {
    final value = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        final palette = AppPalette.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.divider),
                boxShadow: premiumShadow(palette, opacity: 0.20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  bottomSheetOption(
                    context,
                    icon: Icons.timer_off_outlined,
                    title: 'Off',
                    onTap: () => Navigator.of(context).pop(0),
                  ),
                  bottomSheetOption(
                    context,
                    icon: Icons.timer_outlined,
                    title: '24 hours',
                    onTap: () => Navigator.of(context).pop(86400),
                  ),
                  bottomSheetOption(
                    context,
                    icon: Icons.timer_outlined,
                    title: '7 days',
                    onTap: () => Navigator.of(context).pop(604800),
                  ),
                  bottomSheetOption(
                    context,
                    icon: Icons.timer_outlined,
                    title: '30 days',
                    onTap: () => Navigator.of(context).pop(2592000),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (value != null) await widget.onSetAutoDeleteSeconds(value);
  }

  Future<void> runMessageSearch() async {
    if (search.text.trim().isEmpty) {
      setState(() => highlightedIds.clear());
      return;
    }
    setState(() => searching = true);
    try {
      final results = await widget.onSearchMessages(search.text);
      setState(() {
        highlightedIds
          ..clear()
          ..addAll(results.map((message) => message.id));
      });
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> showAttachmentMenu() async {
    if (recordingVoice || editingMessage != null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        final palette = AppPalette.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.divider),
                boxShadow: premiumShadow(palette, opacity: 0.20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  bottomSheetOption(
                    context,
                    icon: Icons.photo_outlined,
                    title: 'Photo',
                    onTap: () => Navigator.of(context).pop('photo'),
                  ),
                  bottomSheetOption(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Document',
                    onTap: () => Navigator.of(context).pop('document'),
                  ),
                  bottomSheetOption(
                    context,
                    icon: Icons.attach_file,
                    title: 'File',
                    onTap: () => Navigator.of(context).pop('file'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (action == 'photo') {
      await pickPhotoAttachment();
    } else if (action == 'document') {
      await pickFileAttachment(forceDocument: true);
    } else if (action == 'file') {
      await pickFileAttachment();
    }
  }

  Future<void> pickPhotoAttachment() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final fileName = picked.name.isEmpty
        ? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : picked.name;
    final attachment = MessageAttachment(
      kind: AttachmentKind.photo,
      fileName: fileName,
      localPath: picked.path,
      localBytes: bytes,
      mimeType: picked.mimeType ?? 'image/jpeg',
      sizeBytes: bytes.length,
    );
    final caption = text.text.trim();
    text.clear();
    final reply = replyingTo;
    setState(() => replyingTo = null);
    await widget.onSendAttachment(
      attachment,
      bytes,
      text: caption,
      replyTo: reply,
    );
  }

  Future<void> pickFileAttachment({bool forceDocument = false}) async {
    final result = await FilePicker.platform.pickFiles(withData: kIsWeb);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await XFile(file.path!).readAsBytes();
    }
    if (bytes == null) return;
    final mimeType = mimeTypeForFile(file.name, file.extension);
    final kind = forceDocument
        ? AttachmentKind.document
        : attachmentKindFor(file.name, mimeType);
    final attachment = MessageAttachment(
      kind: kind,
      fileName: file.name,
      localPath: file.path,
      localBytes: kind == AttachmentKind.photo ? bytes : null,
      mimeType: mimeType,
      sizeBytes: file.size > 0 ? file.size : bytes.length,
    );
    final caption = text.text.trim();
    text.clear();
    final reply = replyingTo;
    setState(() => replyingTo = null);
    await widget.onSendAttachment(
      attachment,
      bytes,
      text: caption,
      replyTo: reply,
    );
  }

  Future<void> startVoiceRecord() async {
    if (recordingVoice) return;
    try {
      if (!await voiceRecorder.hasPermission()) return;
      String path;
      if (kIsWeb) {
        path = 'voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      } else {
        final directory = await getTemporaryDirectory();
        path =
            '${directory.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      }
      await voiceRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() {
        recordStartedAt = DateTime.now();
        recordingVoice = true;
      });
      final chatId = widget.chat?.id;
      if (chatId != null) {
        stopTypingActivity();
        widget.onComposerActivity(
          chatId,
          ChatActivityKind.recording,
          active: true,
        );
      }
    } catch (_) {}
  }

  Future<void> stopVoiceRecord({required bool send}) async {
    if (!recordingVoice) return;
    final started = recordStartedAt;
    final path = await voiceRecorder.stop();
    setState(() {
      recordStartedAt = null;
      recordingVoice = false;
    });
    final chatId = widget.chat?.id;
    if (chatId != null) {
      widget.onComposerActivity(
        chatId,
        ChatActivityKind.recording,
        active: false,
      );
    }
    if (send && started != null && path != null) {
      final duration = DateTime.now()
          .difference(started)
          .inSeconds
          .clamp(1, 3600);
      await widget.onSendVoiceMessage(path, duration);
    }
  }

  Future<void> toggleVoicePlayback(ChatMessage message) async {
    if (playingVoiceId == message.id) {
      await voicePlayer.stop();
      setState(() => playingVoiceId = null);
      return;
    }
    await voicePlayer.stop();
    final localPath = message.localVoicePath;
    if (!kIsWeb && localPath != null && localPath.isNotEmpty) {
      try {
        await voicePlayer.play(DeviceFileSource(localPath));
        setState(() => playingVoiceId = message.id);
        return;
      } catch (_) {
        // Fall through to the server copy if the temporary local file vanished.
      }
    }
    final url = mediaUrl(widget.apiBaseUrl, message.voiceUrl);
    if (url.isEmpty) return;
    try {
      await voicePlayer.play(UrlSource(url));
    } catch (_) {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode >= 400 || response.bodyBytes.isEmpty) return;
      try {
        await voicePlayer.play(BytesSource(response.bodyBytes));
      } catch (_) {
        if (kIsWeb) return;
        final directory = await getTemporaryDirectory();
        final segments = Uri.parse(url).pathSegments;
        final safeName = segments.isEmpty ? '${message.id}.m4a' : segments.last;
        final path = '${directory.path}/play_$safeName';
        await XFile.fromData(response.bodyBytes).saveTo(path);
        await voicePlayer.play(DeviceFileSource(path));
      }
    }
    setState(() => playingVoiceId = message.id);
  }

  Widget buildVoiceMessage(
    BuildContext context,
    ChatMessage message,
    bool mine,
  ) {
    final palette = AppPalette.of(context);
    final accent = mine ? palette.textOnOutgoing : palette.accent;
    final playing = playingVoiceId == message.id;
    final duration = message.voiceDurationSeconds ?? 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 206, maxWidth: 286),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            onPressed: () => toggleVoicePlayback(message),
            style: IconButton.styleFrom(
              fixedSize: const Size.square(42),
              backgroundColor: mine
                  ? palette.textOnOutgoing.withValues(alpha: 0.22)
                  : palette.accent,
              foregroundColor: palette.textOnOutgoing,
            ),
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            tooltip: 'Play voice message',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24,
                  child: CustomPaint(
                    painter: WaveformPainter(
                      color: accent,
                      progress: playing ? 0.42 : 0.0,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  duration <= 0
                      ? '0:00'
                      : '0:${duration.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: mine
                        ? palette.textOnOutgoing.withValues(alpha: 0.82)
                        : palette.textMuted,
                  ),
                ),
                if (message.uploading)
                  Text(
                    'sending...',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: mine
                          ? palette.textOnOutgoing.withValues(alpha: 0.62)
                          : palette.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openAttachment(MessageAttachment attachment) async {
    if (!kIsWeb &&
        attachment.localPath != null &&
        attachment.localPath!.isNotEmpty) {
      await OpenFilex.open(attachment.localPath!);
      return;
    }
    final url = mediaUrl(widget.apiBaseUrl, attachment.url);
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget buildAttachmentMessage(
    BuildContext context,
    ChatMessage message,
    bool mine,
  ) {
    final attachment = message.attachment;
    if (attachment == null) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    final textColor = mine ? palette.textOnOutgoing : palette.textPrimary;
    final muted = mine
        ? palette.textOnOutgoing.withValues(alpha: 0.76)
        : palette.textMuted;
    final thumbnail = attachment.thumbnailUrl ?? attachment.url;
    if (attachment.kind == AttachmentKind.photo) {
      Widget image;
      if (attachment.localBytes != null) {
        image = Image.memory(attachment.localBytes!, fit: BoxFit.cover);
      } else {
        final url = mediaUrl(widget.apiBaseUrl, thumbnail);
        image = url.isEmpty
            ? Icon(Icons.image_outlined, size: 44, color: muted)
            : Image.network(url, fit: BoxFit.cover);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => openAttachment(attachment),
              child: SizedBox(
                width: 260,
                height: 180,
                child: ColoredBox(color: palette.surfaceSoft, child: image),
              ),
            ),
          ),
          if (message.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 14, height: 1.34),
            ),
          ],
        ],
      );
    }
    return InkWell(
      onTap: () => openAttachment(attachment),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 230, maxWidth: 310),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: mine
              ? palette.textOnOutgoing.withValues(alpha: 0.14)
              : palette.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: mine
                ? palette.textOnOutgoing.withValues(alpha: 0.18)
                : palette.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(attachmentIcon(attachment.kind), color: textColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      attachment.kind == AttachmentKind.document
                          ? 'Document'
                          : 'File',
                      formatBytes(attachment.sizeBytes),
                    ].where((value) => value.isNotEmpty).join(' - '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  if (message.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      message.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLinkPreview(
    BuildContext context,
    ChatMessage message,
    bool mine,
  ) {
    final preview = message.linkPreview;
    if (preview == null) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    final textColor = mine ? palette.textOnOutgoing : palette.textPrimary;
    final muted = mine
        ? palette.textOnOutgoing.withValues(alpha: 0.74)
        : palette.textMuted;
    final domain = preview.domain ?? domainForUrl(preview.url);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: preview.url == null
            ? null
            : () => launchUrl(
                Uri.parse(preview.url!),
                mode: LaunchMode.externalApplication,
              ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: mine
                ? palette.textOnOutgoing.withValues(alpha: 0.13)
                : palette.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: mine
                  ? palette.textOnOutgoing.withValues(alpha: 0.18)
                  : palette.divider,
            ),
          ),
          child: Row(
            children: [
              if (preview.thumbnailUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    mediaUrl(widget.apiBaseUrl, preview.thumbnailUrl),
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (domain.isNotEmpty)
                      Text(
                        domain,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      preview.title ?? preview.url ?? 'Link',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (preview.description?.isNotEmpty == true)
                      Text(
                        preview.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildReplyPreview(
    BuildContext context,
    ChatMessage message,
    bool mine,
  ) {
    final palette = AppPalette.of(context);
    final title = message.replyToSenderName ?? 'Reply';
    final text = message.replyToType == 'voice'
        ? 'Voice message'
        : message.replyToType == 'attachment'
        ? 'Attachment'
        : (message.replyToText ?? '');
    if (message.replyToMessageId == null || text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      decoration: BoxDecoration(
        color: palette.accentSoft.withValues(alpha: mine ? 0.56 : 0.70),
        borderRadius: BorderRadius.circular(9),
        border: Border(left: BorderSide(color: palette.accentStrong, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: mine ? palette.textOnOutgoing : palette.accentStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: mine
                  ? palette.textOnOutgoing.withValues(alpha: 0.86)
                  : palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget messageMeta(BuildContext context, ChatMessage message, bool mine) {
    final palette = AppPalette.of(context);
    final color = mine
        ? palette.textOnOutgoing.withValues(alpha: 0.82)
        : palette.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.deliveryState == MessageDeliveryState.failed) ...[
          TextButton.icon(
            onPressed: () => widget.onRetryMessage(message),
            icon: Icon(Icons.refresh, size: 14, color: palette.danger),
            label: Text(
              'retry',
              style: TextStyle(color: palette.danger, fontSize: 11),
            ),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 24),
            ),
          ),
          const SizedBox(width: 4),
        ] else if (message.deliveryState == MessageDeliveryState.sending ||
            message.uploading) ...[
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
          ),
          const SizedBox(width: 5),
        ],
        if (message.editedAt != null) ...[
          Text(
            'edited',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color, fontSize: 11),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          messageClock(message.createdAt),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: color, fontSize: 11),
        ),
        if (mine) ...[
          const SizedBox(width: 3),
          Icon(
            message.deliveryState == MessageDeliveryState.failed
                ? Icons.error_outline
                : message.readByPeer
                ? Icons.done_all
                : Icons.done,
            size: 16,
            color: message.deliveryState == MessageDeliveryState.failed
                ? palette.danger
                : message.readByPeer
                ? palette.accentStrong
                : color,
          ),
        ],
      ],
    );
  }

  Widget buildReactionPill(
    BuildContext context,
    ChatMessage message,
    MapEntry<String, int> entry,
    bool mine,
  ) {
    final palette = AppPalette.of(context);
    final userIds = message.reactionUsers[entry.key] ?? const <String>[];
    final showPeerAvatar = userIds.contains(widget.chat?.peerId);
    final showOwnAvatar = userIds.contains(widget.user.id);
    final avatarName = showPeerAvatar
        ? widget.chat?.peerDisplayName ?? ''
        : widget.user.displayName;
    final avatarUrl = showPeerAvatar
        ? widget.chat?.peerAvatarUrl
        : widget.user.avatarUrl;
    final pillColor = mine
        ? palette.textOnOutgoing.withValues(alpha: 0.16)
        : palette.reaction;
    final borderColor = mine
        ? palette.textOnOutgoing.withValues(alpha: 0.22)
        : palette.accent.withValues(alpha: 0.32);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 5, 2),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(entry.key, style: const TextStyle(fontSize: 14)),
          if (entry.value > 1) ...[
            const SizedBox(width: 3),
            Text(
              entry.value.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: mine ? palette.textOnOutgoing : palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (showPeerAvatar || showOwnAvatar) ...[
            const SizedBox(width: 4),
            UserAvatar(
              apiBaseUrl: widget.apiBaseUrl,
              name: avatarName,
              avatarUrl: avatarUrl,
              radius: 8,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final s = widget.strings;
    if (chat == null) return Center(child: Text(s.selectChat));
    final palette = AppPalette.of(context);
    final selected = selectedMessages();
    final pinned = widget.messages
        .where((message) => message.pinned)
        .take(3)
        .toList();
    final selectedMine =
        selected.length == 1 && selected.first.senderId == widget.user.id;
    final hasText = text.text.trim().isNotEmpty;
    final sendTextMode = hasText || editingMessage != null;
    final peerActivityText = widget.peerActivity?.active == true
        ? activityLabel(widget.peerActivity!.kind)
        : null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: widget.onBack == null
          ? null
          : (details) {
              if (!backSwipeArmed && details.delta.dx > 8) {
                backSwipeArmed = true;
                HapticFeedback.selectionClick();
              }
            },
      onHorizontalDragEnd: widget.onBack == null
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity > 650) {
                HapticFeedback.lightImpact();
                widget.onBack!();
              }
              backSwipeArmed = false;
            },
      onHorizontalDragCancel: () => backSwipeArmed = false,
      child: Column(
        children: [
          ClipRect(
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(bottom: BorderSide(color: palette.divider)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  if (selectedIds.isNotEmpty)
                    PremiumIconButton(
                      onPressed: clearSelection,
                      icon: Icons.close,
                      tooltip: 'Cancel',
                    )
                  else if (widget.onBack != null)
                    PremiumIconButton(
                      onPressed: widget.onBack,
                      icon: Icons.arrow_back,
                      tooltip: 'Back',
                    ),
                  if (selectedIds.isNotEmpty) ...[
                    Expanded(
                      child: Text(
                        '${selectedIds.length} selected',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    PremiumIconButton(
                      onPressed: copySelected,
                      icon: Icons.copy,
                      tooltip: 'Copy',
                    ),
                    PremiumIconButton(
                      onPressed: selectAll,
                      icon: Icons.select_all,
                      tooltip: 'Select all',
                    ),
                    if (selectedMine)
                      PremiumIconButton(
                        onPressed: () => startEdit(selected.first),
                        icon: Icons.edit,
                        tooltip: 'Edit',
                      ),
                    PremiumIconButton(
                      onPressed: deleteSelected,
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                    ),
                  ] else ...[
                    PresenceAvatar(
                      apiBaseUrl: widget.apiBaseUrl,
                      name: chat.peerDisplayName,
                      avatarUrl: chat.peerAvatarUrl,
                      online: chat.peerOnline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat.peerDisplayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            peerActivityText ?? peerStatus(chat),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: peerActivityText != null
                                      ? palette.accentStrong
                                      : chat.peerOnline
                                      ? palette.accent
                                      : palette.textMuted,
                                  fontWeight: peerActivityText != null
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                    PremiumIconButton(
                      onPressed: () => setState(() => searchOpen = !searchOpen),
                      icon: Icons.search,
                      tooltip: 'Search',
                    ),
                    PremiumIconButton(
                      onPressed: showAutoDeleteSettings,
                      icon: Icons.timer_outlined,
                      tooltip: 'Auto-delete',
                    ),
                    PremiumIconButton(
                      onPressed: () => widget.onStartVoiceCall(chat),
                      icon: Icons.call,
                      filled: true,
                      tooltip: s.call,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (searchOpen)
            Container(
              color: palette.surface,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: PremiumSearchField(
                      controller: search,
                      hint: 'Search in chat',
                      onSubmitted: (_) => runMessageSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PremiumIconButton(
                    onPressed: searching ? null : runMessageSearch,
                    icon: Icons.arrow_forward,
                    filled: true,
                    tooltip: 'Search',
                  ),
                ],
              ),
            ),
          if (pinned.isNotEmpty)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                border: Border(bottom: BorderSide(color: palette.divider)),
              ),
              padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 38,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          setState(() => highlightedIds.add(pinned.first.id)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pinned.length == 1
                                ? 'Pinned message'
                                : '${pinned.length} pinned messages',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: palette.accentStrong,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            messageContentLabel(pinned.first),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: palette.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PremiumIconButton(
                    onPressed: () =>
                        widget.onSetMessagePinned(pinned.first, false),
                    icon: Icons.close,
                    tooltip: 'Unpin message',
                  ),
                ],
              ),
            ),
          Expanded(
            child: ColoredBox(
              color: palette.chatBackground,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    ListView.builder(
                      controller: scroll,
                      padding: EdgeInsets.fromLTRB(
                        14,
                        14,
                        14,
                        120 +
                            (editingMessage != null ? 58 : 0) +
                            (replyingTo != null ? 68 : 0),
                      ),
                      itemCount: widget.messages.length,
                      itemBuilder: (context, index) {
                        final message = widget.messages[index];
                        final mine = message.senderId == widget.user.id;
                        final isSelected = selectedIds.contains(message.id);
                        final isHighlighted = highlightedIds.contains(
                          message.id,
                        );
                        final maxBubbleWidth = math.min(
                          520.0,
                          constraints.maxWidth * 0.78,
                        );
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GestureDetector(
                            onHorizontalDragStart: (_) => setState(() {
                              swipingMessageId = message.id;
                              swipeOffset = 0;
                            }),
                            onHorizontalDragUpdate: (details) => setState(() {
                              swipingMessageId = message.id;
                              swipeOffset = (swipeOffset + details.delta.dx)
                                  .clamp(0, 56);
                            }),
                            onHorizontalDragEnd: (details) {
                              final velocity = details.primaryVelocity ?? 0;
                              final shouldReply =
                                  velocity > 450 || swipeOffset > 34;
                              setState(() {
                                swipingMessageId = null;
                                swipeOffset = 0;
                              });
                              if (shouldReply) startReply(message);
                            },
                            onHorizontalDragCancel: () => setState(() {
                              swipingMessageId = null;
                              swipeOffset = 0;
                            }),
                            onLongPressStart: (details) => showMessageMenu(
                              message,
                              details.globalPosition,
                            ),
                            onSecondaryTapDown: (details) => showMessageMenu(
                              message,
                              details.globalPosition,
                            ),
                            onTap: selectedIds.isEmpty
                                ? null
                                : () => toggleSelection(message),
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOutCubic,
                              offset: Offset(
                                swipingMessageId == message.id
                                    ? swipeOffset / maxBubbleWidth
                                    : 0,
                                0,
                              ),
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: maxBubbleWidth,
                                ),
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  10,
                                  6,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? null
                                      : isSelected
                                      ? palette.selectedRow
                                      : isHighlighted
                                      ? palette.accentSoft
                                      : palette.incomingBubble,
                                  gradient:
                                      mine && !isSelected && !isHighlighted
                                      ? palette.outgoingGradient
                                      : null,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(mine ? 18 : 5),
                                    bottomRight: Radius.circular(mine ? 5 : 18),
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? palette.accent
                                        : mine
                                        ? Colors.transparent
                                        : palette.divider,
                                  ),
                                  boxShadow: premiumShadow(
                                    palette,
                                    opacity: 0.10,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    buildReplyPreview(context, message, mine),
                                    if (message.voiceUrl != null ||
                                        message.localVoicePath != null)
                                      buildVoiceMessage(context, message, mine)
                                    else if (message.attachment != null)
                                      buildAttachmentMessage(
                                        context,
                                        message,
                                        mine,
                                      )
                                    else
                                      Text(
                                        message.text,
                                        style: TextStyle(
                                          color: mine
                                              ? palette.textOnOutgoing
                                              : palette.textPrimary,
                                          fontSize: 14,
                                          height: 1.34,
                                        ),
                                      ),
                                    buildLinkPreview(context, message, mine),
                                    if (message.reactions.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: message.reactions.entries
                                              .map(
                                                (entry) => buildReactionPill(
                                                  context,
                                                  message,
                                                  entry,
                                                  mine,
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: messageMeta(
                                        context,
                                        message,
                                        mine,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (editingMessage != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: replyingTo != null ? 138 : 82,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            color: palette.surface.withValues(alpha: 0.92),
                            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: palette.accent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    editingMessage!.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PremiumIconButton(
                                  icon: Icons.close,
                                  tooltip: 'Cancel edit',
                                  onPressed: () =>
                                      setState(() => editingMessage = null),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (replyingTo != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 82,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            color: palette.surface.withValues(alpha: 0.92),
                            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                            child: Row(
                              children: [
                                Icon(Icons.reply, color: palette.accent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        replyingTo!.senderName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        messageContentLabel(replyingTo!),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                PremiumIconButton(
                                  icon: Icons.close,
                                  tooltip: 'Cancel reply',
                                  onPressed: () =>
                                      setState(() => replyingTo = null),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(
                        children: [
                          if (recordingVoice) ...[
                            PremiumIconButton(
                              icon: Icons.close,
                              tooltip: 'Cancel voice message',
                              onPressed: () => stopVoiceRecord(send: false),
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            PremiumIconButton(
                              icon: Icons.attach_file,
                              tooltip: 'Attach',
                              onPressed: showAttachmentMenu,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                color: palette.input.withValues(alpha: 0.90),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: palette.divider.withValues(
                                      alpha: 0.72,
                                    ),
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: recordingVoice
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Text(
                                          'Recording voice message...',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                      )
                                    : TextField(
                                        controller: text,
                                        minLines: 1,
                                        maxLines: 4,
                                        style: TextStyle(
                                          color: palette.textPrimary,
                                          fontSize: 14,
                                        ),
                                        onSubmitted: (_) => submit(),
                                        decoration: InputDecoration(
                                          filled: false,
                                          fillColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          hintText: editingMessage == null
                                              ? s.message
                                              : 'Edit message',
                                          hintStyle: TextStyle(
                                            color: palette.textMuted,
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          prefixIcon: const Icon(
                                            Icons.emoji_emotions_outlined,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: palette.actionGradient,
                              shape: BoxShape.circle,
                              boxShadow: premiumShadow(palette, opacity: 0.12),
                            ),
                            child: IconButton(
                              onPressed: recordingVoice
                                  ? () => stopVoiceRecord(send: true)
                                  : sendTextMode
                                  ? submit
                                  : startVoiceRecord,
                              icon: Icon(
                                recordingVoice
                                    ? Icons.check
                                    : sendTextMode
                                    ? Icons.send
                                    : Icons.mic,
                              ),
                              style: IconButton.styleFrom(
                                fixedSize: const Size.square(48),
                                foregroundColor: Colors.white,
                              ),
                              tooltip: recordingVoice
                                  ? 'Send voice message'
                                  : sendTextMode
                                  ? s.send
                                  : 'Record voice message',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
