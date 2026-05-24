import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final lang = prefs.getString('language') ?? 'en';
    setState(() {
      themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
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

  Future<void> setLanguage(AppLanguage value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value == AppLanguage.ru ? 'ru' : 'en');
    setState(() => language = value);
  }

  ThemeData theme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF229ED9),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF101820)
          : const Color(0xFFF4F7FA),
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
              onThemeChanged: setThemeMode,
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
  if (text == null || text.isEmpty) return 'Voice message';
  return text;
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

  Future<void> delete(String path) async {
    final response = await http.delete(uri(path), headers: headers());
    if (response.statusCode >= 400) {
      throw ApiException(
        response.body.isEmpty ? 'request_failed' : response.body,
      );
    }
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
    await delete(
      '/api/chats/${Uri.encodeComponent(chatId)}/pins/${Uri.encodeComponent(messageId)}',
    );
    return <String, dynamic>{};
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
  );

  ChatSummary copyWith({bool? peerOnline, String? peerLastSeenAt}) =>
      ChatSummary(
        id: id,
        peerId: peerId,
        peerUsername: peerUsername,
        peerDisplayName: peerDisplayName,
        peerAvatarUrl: peerAvatarUrl,
        peerOnline: peerOnline ?? this.peerOnline,
        peerLastSeenAt: peerLastSeenAt ?? this.peerLastSeenAt,
        lastText: lastText,
        lastAt: lastAt,
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
    this.voiceUrl,
    this.voiceDurationSeconds,
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
  final String? voiceUrl;
  final int? voiceDurationSeconds;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
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
    voiceUrl:
        json['voiceUrl'] as String? ??
        json['audioUrl'] as String? ??
        json['mediaUrl'] as String?,
    voiceDurationSeconds:
        (json['voiceDurationSeconds'] as num? ??
                json['durationSeconds'] as num? ??
                ((json['durationMs'] as num?) == null
                    ? null
                    : ((json['durationMs'] as num) / 1000).ceil()))
            ?.toInt(),
  );

  ChatMessage copyWith({
    String? text,
    String? editedAt,
    bool? pinned,
    bool? readByPeer,
    Map<String, int>? reactions,
    String? voiceUrl,
    int? voiceDurationSeconds,
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
    voiceUrl: voiceUrl ?? this.voiceUrl,
    voiceDurationSeconds: voiceDurationSeconds ?? this.voiceDurationSeconds,
  );
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
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  final AppStrings strings;
  final AppLanguage language;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
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
  ChatSummary? selectedChat;
  WebSocketChannel? channel;
  StreamSubscription? socketSub;
  StreamSubscription<String>? notificationTapSub;
  StreamSubscription<CallNotificationAction>? callNotificationActionSub;
  Timer? incomingCallTimeoutTimer;
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
        setState(() {
          messages.putIfAbsent(message.chatId, () => []);
          if (!messages[message.chatId]!.any((item) => item.id == message.id)) {
            messages[message.chatId]!.add(message);
          }
        });
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
      } else if (data['type'] is String &&
          (data['type'] as String).startsWith('call.')) {
        unawaited(handleCallSignal(data));
      }
    }, onError: (_) {});
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

  void sendSocketEvent(Map<String, dynamic> event) {
    channel?.sink.add(jsonEncode(event));
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
    chats
      ..clear()
      ..addAll(
        (data['chats'] as List).map(
          (item) => ChatSummary.fromJson(item as Map<String, dynamic>),
        ),
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
    final data = await api.getJson(
      '/api/chats/${Uri.encodeComponent(chat.id)}/messages',
    );
    messages[chat.id] = (data['messages'] as List)
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
    await markSelectedChatRead();
    if (mounted) setState(() {});
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

  Future<void> sendMessage(String text) async {
    final chat = selectedChat;
    if (chat == null || text.trim().isEmpty) return;
    final data = await api.postJson(
      '/api/chats/${Uri.encodeComponent(chat.id)}/messages',
      {'text': text.trim()},
    );
    final message = ChatMessage.fromJson(
      data['message'] as Map<String, dynamic>,
    );
    messages.putIfAbsent(chat.id, () => []);
    if (!messages[chat.id]!.any((item) => item.id == message.id)) {
      messages[chat.id]!.add(message);
    }
    await loadChats();
    if (mounted) setState(() {});
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

  Future<void> setMessagePinned(ChatMessage message, bool pinned) async {
    final data = await api.setMessagePinned(message.chatId, message.id, pinned);
    final updated = data['message'];
    if (updated is Map<String, dynamic>) {
      replaceLocalMessage(ChatMessage.fromJson(updated));
    } else {
      replaceLocalMessage(message.copyWith(pinned: pinned));
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

  Future<void> sendVoiceMessage(Uint8List bytes, int durationSeconds) async {
    final chat = selectedChat;
    if (chat == null) return;
    final data = await api.sendVoiceMessage(
      chat.id,
      bytes,
      durationSeconds: durationSeconds,
    );
    final message = ChatMessage.fromJson(
      data['message'] as Map<String, dynamic>,
    );
    messages.putIfAbsent(chat.id, () => []);
    if (!messages[chat.id]!.any((item) => item.id == message.id)) {
      messages[chat.id]!.add(message);
    }
    await loadChats();
    if (mounted) setState(() {});
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
      onThemeChanged: widget.onThemeChanged,
      onLanguageChanged: widget.onLanguageChanged,
      user: currentUser!,
      contacts: contacts,
      chats: chats,
      selectedChat: selectedChat,
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
      onEditMessage: editMessage,
      onDeleteMessages: deleteSelectedMessages,
      onReactToMessage: reactToMessage,
      onSetMessagePinned: setMessagePinned,
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
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.chat_bubble,
                    size: 56,
                    color: Color(0xFF229ED9),
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
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(s.login),
                        icon: const Icon(Icons.login),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(s.register),
                        icon: const Icon(Icons.person_add),
                      ),
                    ],
                    selected: {registerMode},
                    onSelectionChanged: (value) =>
                        setState(() => registerMode = value.first),
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
                  FilledButton.icon(
                    onPressed: busy ? null : submit,
                    icon: Icon(registerMode ? Icons.person_add : Icons.login),
                    label: Text(registerMode ? s.createAccount : s.login),
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
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.user,
    required this.contacts,
    required this.chats,
    required this.selectedChat,
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
    required this.onEditMessage,
    required this.onDeleteMessages,
    required this.onReactToMessage,
    required this.onSetMessagePinned,
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
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final UserProfile user;
  final List<UserProfile> contacts;
  final List<ChatSummary> chats;
  final ChatSummary? selectedChat;
  final List<ChatMessage> messages;
  final VoiceCallSession? voiceCall;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;
  final Future<void> Function() onChangeAvatar;
  final Future<void> Function() onRefresh;
  final Future<List<UserProfile>> Function(String username) onSearch;
  final Future<void> Function(String username) onAddContact;
  final Future<void> Function(ChatSummary chat) onOpenChat;
  final Future<void> Function(String text) onSendMessage;
  final Future<void> Function(ChatMessage message, String text) onEditMessage;
  final Future<void> Function(List<ChatMessage> messages) onDeleteMessages;
  final Future<void> Function(ChatMessage message, String reaction)
  onReactToMessage;
  final Future<void> Function(ChatMessage message, bool pinned)
  onSetMessagePinned;
  final Future<List<ChatMessage>> Function(String query) onSearchMessages;
  final Future<void> Function(int seconds) onSetAutoDeleteSeconds;
  final Future<void> Function(Uint8List bytes, int durationSeconds)
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
      onThemeChanged: widget.onThemeChanged,
      onLanguageChanged: widget.onLanguageChanged,
      user: widget.user,
      apiBaseUrl: widget.apiBaseUrl,
      contactsMode: contactsMode,
      contacts: widget.contacts,
      chats: widget.chats,
      selectedChat: widget.selectedChat,
      onModeChanged: (value) => setState(() => contactsMode = value),
      onLogout: widget.onLogout,
      onDeleteAccount: widget.onDeleteAccount,
      onChangeAvatar: widget.onChangeAvatar,
      onRefresh: widget.onRefresh,
      onSearch: widget.onSearch,
      onAddContact: widget.onAddContact,
      onOpenChat: widget.onOpenChat,
      onSeedDemoChats: widget.onSeedDemoChats,
    );
    final chat = ChatPane(
      strings: widget.strings,
      user: widget.user,
      chat: widget.selectedChat,
      apiBaseUrl: widget.apiBaseUrl,
      messages: widget.messages,
      onBack: wide ? null : widget.onCloseChat,
      onSend: widget.onSendMessage,
      onEditMessage: widget.onEditMessage,
      onDeleteMessages: widget.onDeleteMessages,
      onReactToMessage: widget.onReactToMessage,
      onSetMessagePinned: widget.onSetMessagePinned,
      onSearchMessages: widget.onSearchMessages,
      onSetAutoDeleteSeconds: widget.onSetAutoDeleteSeconds,
      onSendVoiceMessage: widget.onSendVoiceMessage,
      onStartVoiceCall: widget.onStartVoiceCall,
    );
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: wide
                ? Row(
                    children: [
                      SizedBox(width: 360, child: sidebar),
                      const VerticalDivider(width: 1),
                      Expanded(child: chat),
                    ],
                  )
                : widget.selectedChat == null
                ? sidebar
                : chat,
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
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF229ED9),
      foregroundColor: Colors.white,
      backgroundImage: url.isEmpty ? null : NetworkImage(url),
      child: url.isEmpty
          ? (icon == null ? Text(initialsFor(name)) : Icon(icon))
          : null,
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatar(
          apiBaseUrl: apiBaseUrl,
          name: name,
          avatarUrl: avatarUrl,
          radius: radius,
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: online ? const Color(0xFF37C978) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Sidebar extends StatefulWidget {
  const Sidebar({
    super.key,
    required this.strings,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.user,
    required this.apiBaseUrl,
    required this.contactsMode,
    required this.contacts,
    required this.chats,
    required this.selectedChat,
    required this.onModeChanged,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onChangeAvatar,
    required this.onRefresh,
    required this.onSearch,
    required this.onAddContact,
    required this.onOpenChat,
    required this.onSeedDemoChats,
  });

  final AppStrings strings;
  final AppLanguage language;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final UserProfile user;
  final String apiBaseUrl;
  final bool contactsMode;
  final List<UserProfile> contacts;
  final List<ChatSummary> chats;
  final ChatSummary? selectedChat;
  final ValueChanged<bool> onModeChanged;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;
  final Future<void> Function() onChangeAvatar;
  final Future<void> Function() onRefresh;
  final Future<List<UserProfile>> Function(String username) onSearch;
  final Future<void> Function(String username) onAddContact;
  final Future<void> Function(ChatSummary chat) onOpenChat;
  final Future<void> Function() onSeedDemoChats;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final search = TextEditingController();
  List<UserProfile> results = const [];
  bool searching = false;
  bool seedingDemo = false;

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
      builder: (context) => AlertDialog(
        title: Text(widget.strings.settings),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
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
                subtitle: Text('@${widget.user.username}'),
                trailing: const Icon(Icons.photo_camera_outlined),
                onTap: () async {
                  Navigator.of(context).pop();
                  await widget.onChangeAvatar();
                },
              ),
              const Divider(height: 28),
              SettingsControl(
                icon: Icons.light_mode,
                label: widget.strings.theme,
                control: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(widget.strings.light),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(widget.strings.dark),
                    ),
                  ],
                  selected: {
                    widget.themeMode == ThemeMode.dark
                        ? ThemeMode.dark
                        : ThemeMode.light,
                  },
                  onSelectionChanged: (value) =>
                      widget.onThemeChanged(value.first),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
            child: Row(
              children: [
                UserAvatar(
                  apiBaseUrl: widget.apiBaseUrl,
                  name: widget.user.displayName,
                  avatarUrl: widget.user.avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.user.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: s.refresh,
                ),
                IconButton(
                  onPressed: showSettings,
                  icon: const Icon(Icons.settings),
                  tooltip: s.settings,
                ),
                IconButton(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout),
                  tooltip: s.logout,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(s.chats),
                  icon: const Icon(Icons.forum_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(s.contacts),
                  icon: const Icon(Icons.people_outline),
                ),
              ],
              selected: {widget.contactsMode},
              onSelectionChanged: (value) => widget.onModeChanged(value.first),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: widget.contactsMode
                ? contactsView(context)
                : chatsView(context),
          ),
        ],
      ),
    );
  }

  Widget chatsView(BuildContext context) {
    final s = widget.strings;
    if (widget.chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.addContactToStart, textAlign: TextAlign.center),
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
    return ListView.builder(
      itemCount: widget.chats.length,
      itemBuilder: (context, index) {
        final chat = widget.chats[index];
        final lastAt = chat.lastAt == null ? '' : messageClock(chat.lastAt!);
        return ListTile(
          selected: widget.selectedChat?.id == chat.id,
          leading: PresenceAvatar(
            apiBaseUrl: widget.apiBaseUrl,
            name: chat.peerDisplayName,
            avatarUrl: chat.peerAvatarUrl,
            online: chat.peerOnline,
          ),
          title: Text(
            chat.peerDisplayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            chat.lastAt == null
                ? peerStatus(chat)
                : '${lastMessagePreview(chat)}  ${chat.peerOnline ? 'online' : peerStatus(chat)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: lastAt.isEmpty
              ? null
              : Text(
                  lastAt,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
          onTap: () => widget.onOpenChat(chat),
        );
      },
    );
  }

  Widget contactsView(BuildContext context) {
    final s = widget.strings;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: search,
                  onSubmitted: (_) => runSearch(),
                  decoration: InputDecoration(
                    labelText: s.findUsername,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: searching ? null : runSearch,
                icon: const Icon(Icons.search),
                tooltip: s.findUsername,
              ),
            ],
          ),
        ),
        if (results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: results
                  .map(
                    (user) => ListTile(
                      dense: true,
                      leading: UserAvatar(
                        apiBaseUrl: widget.apiBaseUrl,
                        name: user.displayName,
                        avatarUrl: user.avatarUrl,
                        icon: Icons.person_add_alt,
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          await widget.onAddContact(user.username);
                          search.clear();
                          setState(() => results = const []);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const Divider(height: 24),
        Expanded(
          child: widget.contacts.isEmpty
              ? Center(child: Text(s.noContacts))
              : ListView(
                  children: widget.contacts.map((contact) {
                    final chatMatches = widget.chats.where(
                      (chat) => chat.peerId == contact.id,
                    );
                    final chat = chatMatches.isEmpty ? null : chatMatches.first;
                    return ListTile(
                      leading: PresenceAvatar(
                        apiBaseUrl: widget.apiBaseUrl,
                        name: contact.displayName,
                        avatarUrl: contact.avatarUrl,
                        online: chat?.peerOnline ?? false,
                      ),
                      title: Text(contact.displayName),
                      subtitle: Text(
                        chat == null
                            ? '@${contact.username}'
                            : '${peerStatus(chat)} · @${contact.username}',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final title = Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Align(alignment: Alignment.centerLeft, child: control),
              ),
            ],
          );
        }
        return Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 16),
            Flexible(flex: 0, child: control),
          ],
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
    final scheme = Theme.of(context).colorScheme;
    final canChangeRoute = !kIsWeb && session.phase != VoiceCallPhase.incoming;
    return Positioned.fill(
      child: Material(
        color: scheme.surface,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
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
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                        onPressed: onReject,
                      ),
                      const SizedBox(width: 32),
                      _CallActionButton(
                        label: strings.answer,
                        icon: Icons.call,
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        onPressed: onAccept,
                      ),
                    ] else
                      _CallActionButton(
                        label: strings.endCall,
                        icon: Icons.call_end,
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              fixedSize: const Size.square(58),
              backgroundColor: selected ? scheme.primaryContainer : null,
              foregroundColor: selected ? scheme.onPrimaryContainer : null,
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
            fixedSize: const Size.square(66),
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 30),
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
    required this.onBack,
    required this.onSend,
    required this.onEditMessage,
    required this.onDeleteMessages,
    required this.onReactToMessage,
    required this.onSetMessagePinned,
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
  final VoidCallback? onBack;
  final Future<void> Function(String text) onSend;
  final Future<void> Function(ChatMessage message, String text) onEditMessage;
  final Future<void> Function(List<ChatMessage> messages) onDeleteMessages;
  final Future<void> Function(ChatMessage message, String reaction)
  onReactToMessage;
  final Future<void> Function(ChatMessage message, bool pinned)
  onSetMessagePinned;
  final Future<List<ChatMessage>> Function(String query) onSearchMessages;
  final Future<void> Function(int seconds) onSetAutoDeleteSeconds;
  final Future<void> Function(Uint8List bytes, int durationSeconds)
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
  DateTime? recordStartedAt;
  String? playingVoiceId;
  StreamSubscription<void>? playerCompleteSub;

  @override
  void initState() {
    super.initState();
    text.addListener(() {
      if (mounted) setState(() {});
    });
    playerCompleteSub = voicePlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playingVoiceId = null);
    });
  }

  @override
  void dispose() {
    text.dispose();
    search.dispose();
    scroll.dispose();
    playerCompleteSub?.cancel();
    voicePlayer.dispose();
    unawaited(voiceRecorder.dispose());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
      });
    }
  }

  Future<void> submit() async {
    final value = text.text;
    text.clear();
    final editing = editingMessage;
    if (editing == null) {
      await widget.onSend(value);
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
    if (message.senderId != widget.user.id || message.voiceUrl != null) return;
    setState(() {
      editingMessage = message;
      text.text = message.text;
      selectedIds.clear();
    });
  }

  Future<void> pickReaction(ChatMessage message) async {
    final reaction = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: ['👍', '❤️', '😂', '😮', '😢', '🔥']
              .map(
                (emoji) => IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(emoji),
                  icon: Text(emoji, style: const TextStyle(fontSize: 24)),
                  tooltip: emoji,
                ),
              )
              .toList(),
        ),
      ),
    );
    if (reaction != null) await widget.onReactToMessage(message, reaction);
  }

  Future<void> showMessageMenu(ChatMessage message, Offset position) async {
    final mine = message.senderId == widget.user.id;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        if (message.text.trim().isNotEmpty)
          const PopupMenuItem(
            value: 'copy',
            child: ListTile(
              leading: Icon(Icons.copy),
              title: Text('Copy'),
              dense: true,
            ),
          ),
        const PopupMenuItem(
          value: 'react',
          child: ListTile(
            leading: Icon(Icons.add_reaction_outlined),
            title: Text('React'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'pin',
          child: ListTile(
            leading: Icon(
              message.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            title: Text(message.pinned ? 'Unpin' : 'Pin'),
            dense: true,
          ),
        ),
        if (mine && message.voiceUrl == null)
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit'),
              dense: true,
            ),
          ),
        const PopupMenuItem(
          value: 'select',
          child: ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Select'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
            dense: true,
          ),
        ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'copy':
        await copyMessage(message);
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
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timer_off_outlined),
              title: const Text('Off'),
              onTap: () => Navigator.of(context).pop(0),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('24 hours'),
              onTap: () => Navigator.of(context).pop(86400),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('7 days'),
              onTap: () => Navigator.of(context).pop(604800),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('30 days'),
              onTap: () => Navigator.of(context).pop(2592000),
            ),
          ],
        ),
      ),
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
    if (send && started != null && path != null) {
      final duration = DateTime.now()
          .difference(started)
          .inSeconds
          .clamp(1, 3600);
      final bytes = await XFile(path).readAsBytes();
      await widget.onSendVoiceMessage(bytes, duration);
    }
  }

  Future<void> toggleVoicePlayback(ChatMessage message) async {
    if (playingVoiceId == message.id) {
      await voicePlayer.stop();
      setState(() => playingVoiceId = null);
      return;
    }
    final url = mediaUrl(widget.apiBaseUrl, message.voiceUrl);
    if (url.isEmpty) return;
    await voicePlayer.stop();
    final response = await http.get(Uri.parse(url));
    if (response.statusCode >= 400 || response.bodyBytes.isEmpty) return;
    await voicePlayer.play(BytesSource(response.bodyBytes));
    setState(() => playingVoiceId = message.id);
  }

  Widget buildVoiceMessage(
    BuildContext context,
    ChatMessage message,
    bool mine,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final accent = mine ? Colors.white : const Color(0xFF54B7F3);
    final playing = playingVoiceId == message.id;
    final duration = message.voiceDurationSeconds ?? 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 330),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            onPressed: () => toggleVoicePlayback(message),
            style: IconButton.styleFrom(
              backgroundColor: mine
                  ? Colors.white.withValues(alpha: 0.22)
                  : const Color(0xFF54B7F3),
              foregroundColor: mine ? Colors.white : Colors.white,
            ),
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            tooltip: 'Play voice message',
          ),
          const SizedBox(width: 10),
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
                        ? Colors.white.withValues(alpha: 0.82)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_tab,
            size: 18,
            color: accent.withValues(alpha: 0.75),
          ),
        ],
      ),
    );
  }

  Widget messageMeta(BuildContext context, ChatMessage message, bool mine) {
    final scheme = Theme.of(context).colorScheme;
    final color = mine
        ? Colors.white.withValues(alpha: 0.82)
        : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.editedAt != null) ...[
          Text(
            'edited',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          messageClock(message.createdAt),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
        if (mine) ...[
          const SizedBox(width: 3),
          Icon(
            message.readByPeer ? Icons.done_all : Icons.done,
            size: 16,
            color: message.readByPeer ? const Color(0xFF7AD7FF) : color,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final s = widget.strings;
    if (chat == null) return Center(child: Text(s.selectChat));
    final scheme = Theme.of(context).colorScheme;
    final selected = selectedMessages();
    final pinned = widget.messages
        .where((message) => message.pinned)
        .take(3)
        .toList();
    final selectedMine =
        selected.length == 1 && selected.first.senderId == widget.user.id;
    final hasText = text.text.trim().isNotEmpty;
    final sendTextMode = hasText || editingMessage != null;
    return Column(
      children: [
        Container(
          color: scheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              if (selectedIds.isNotEmpty)
                IconButton(
                  onPressed: clearSelection,
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel',
                )
              else if (widget.onBack != null)
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
              if (selectedIds.isNotEmpty) ...[
                Expanded(
                  child: Text(
                    '${selectedIds.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: copySelected,
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy',
                ),
                IconButton(
                  onPressed: selectAll,
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Select all',
                ),
                if (selectedMine)
                  IconButton(
                    onPressed: () => startEdit(selected.first),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                  ),
                IconButton(
                  onPressed: deleteSelected,
                  icon: const Icon(Icons.delete_outline),
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        peerStatus(chat),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: chat.peerOnline
                              ? const Color(0xFF229ED9)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => searchOpen = !searchOpen),
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                ),
                IconButton(
                  onPressed: showAutoDeleteSettings,
                  icon: const Icon(Icons.timer_outlined),
                  tooltip: 'Auto-delete',
                ),
                IconButton.filledTonal(
                  onPressed: () => widget.onStartVoiceCall(chat),
                  icon: const Icon(Icons.call),
                  tooltip: s.call,
                ),
              ],
            ],
          ),
        ),
        if (searchOpen)
          Container(
            color: scheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: search,
                    onSubmitted: (_) => runMessageSearch(),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search in chat',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: searching ? null : runMessageSearch,
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Search',
                ),
              ],
            ),
          ),
        if (pinned.isNotEmpty)
          Container(
            width: double.infinity,
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF229ED9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.push_pin, size: 18),
                const SizedBox(width: 8),
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
                                color: const Color(0xFF229ED9),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          pinned.first.voiceUrl != null
                              ? 'Voice message'
                              : pinned.first.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      widget.onSetMessagePinned(pinned.first, false),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Unpin',
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.all(18),
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              final message = widget.messages[index];
              final mine = message.senderId == widget.user.id;
              final isSelected = selectedIds.contains(message.id);
              final isHighlighted = highlightedIds.contains(message.id);
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: GestureDetector(
                  onLongPressStart: (details) =>
                      showMessageMenu(message, details.globalPosition),
                  onSecondaryTapDown: (details) =>
                      showMessageMenu(message, details.globalPosition),
                  onTap: selectedIds.isEmpty
                      ? null
                      : () => toggleSelection(message),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.secondaryContainer
                          : isHighlighted
                          ? scheme.tertiaryContainer.withValues(alpha: 0.7)
                          : mine
                          ? const Color(0xFF2D83BD)
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(mine ? 18 : 5),
                        bottomRight: Radius.circular(mine ? 5 : 18),
                      ),
                      border: Border.all(
                        color: isSelected ? scheme.primary : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.voiceUrl != null)
                          buildVoiceMessage(context, message, mine)
                        else
                          Text(
                            message.text,
                            style: TextStyle(
                              color: mine ? Colors.white : scheme.onSurface,
                            ),
                          ),
                        if (message.reactions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 4,
                              children: message.reactions.entries
                                  .map(
                                    (entry) => Chip(
                                      label: Text(
                                        '${entry.key} ${entry.value}',
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: messageMeta(context, message, mine),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (editingMessage != null)
          Container(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.edit_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    editingMessage!.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => editingMessage = null),
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel edit',
                ),
              ],
            ),
          ),
        Container(
          color: scheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              if (recordingVoice) ...[
                IconButton.filledTonal(
                  onPressed: () => stopVoiceRecord(send: false),
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel voice message',
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: recordingVoice
                    ? Text(
                        'Recording voice message...',
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    : TextField(
                        controller: text,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => submit(),
                        decoration: InputDecoration(
                          hintText: editingMessage == null
                              ? s.message
                              : 'Edit message',
                          border: const OutlineInputBorder(),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
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
                tooltip: recordingVoice
                    ? 'Send voice message'
                    : sendTextMode
                    ? s.send
                    : 'Record voice message',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
