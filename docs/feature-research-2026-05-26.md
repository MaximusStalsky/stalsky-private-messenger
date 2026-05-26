# My Messenger: текущее состояние и фичи для развития

Дата исследования: 2026-05-26

Цель: зафиксировать, что уже умеет My Messenger, и выбрать следующие функции не для публичной социальной сети, а для частного семейного 1-на-1 мессенджера без групп, каналов, рекламы и бизнес-функций.

## Что сейчас уже есть

### Платформы и доставка

- Flutter-клиент для Android и Web.
- Node.js/TypeScript backend на Fastify.
- SQLite как основная база.
- WebSocket для real-time событий.
- Docker/VPS деплой.
- HTTPS production endpoint: `https://max.stalsky.org/`.
- GitHub releases с APK для установки через GitHub Store.

### Аккаунты

- Регистрация по username/password без обязательного invite.
- Optional invite-код всё ещё поддерживается.
- Login по username/password.
- Токен авторизации.
- Сохранение авторизации в приложении после первого входа.
- Удаление своего аккаунта.
- Профиль с display name и avatarUrl.

### Контакты и чаты

- Поиск пользователя по username.
- Ручное добавление контакта.
- Автоматическое создание direct chat для пары пользователей.
- Защита от чтения чужого чата.
- Список чатов и контактов.
- Online/last seen отображение.
- Аватарки и online ring вокруг аватарки.

### Сообщения

- Текстовые сообщения.
- История сообщений хранится на сервере.
- Realtime доставка через WebSocket.
- Часы отправки внутри bubble.
- Статусы доставки/прочтения: одна/две галочки, read state.
- Reply на сообщение.
- Swipe-to-reply на мобильном.
- Контекстное меню по long press и right click.
- Copy текста сообщения.
- Select/delete выбранных сообщений.
- Edit своих сообщений.
- Delete for everyone через серверную синхронизацию.
- Поиск по сообщениям внутри чата.
- Pinned messages, лимит до 3 закрепов на чат.
- Unpin/clear pins через сервер.
- Emoji reactions с синхронизацией.
- Auto-delete setting на чат.

### Голосовые и звонки

- Голосовые сообщения.
- Загрузка voice на сервер.
- Локальное проигрывание свежезаписанного voice до и после серверной синхронизации.
- UI голосовых сообщений в Telegram-like направлении.
- 1-на-1 WebRTC voice call signaling через WebSocket.
- Fullscreen call screen.
- Incoming/outgoing/active call states.
- Ringtone для входящего звонка на Android.
- Управление аудио маршрутом: speaker/Bluetooth preference там, где доступно.
- Очистка WebRTC connection/audio tracks при завершении.

### Push и Android

- Android notification permission.
- Notification channel `messages`.
- FCM token отправляется на backend после login.
- Backend хранит push tokens.
- Backend умеет отправлять FCM v1 notifications, если заданы Firebase credentials.
- Tap по notification открывает приложение и выбирает нужный чат.
- Есть локальные Android notifications для входящих WebSocket сообщений, когда приложение работает.

### UI/UX

- Telegram-like мобильная навигация: список чатов -> чат -> back.
- Двухпанельный layout для wide web/desktop.
- Header чата: back, avatar, name, online/last seen, call.
- Composer меняет кнопку voice/send в зависимости от наличия текста.
- Settings sheet.
- Две style families: `Blue Premium` и `CoffeeWood Premium`.
- У каждой style family есть light/dark mode.
- Премиальные visual tokens и дизайн-мокапы в `design/`.
- Responsive web/mobile layout.

### Тесты и эксплуатация

- Backend tests покрывают auth, contacts, chats, messages, avatars, reactions, pins, auto-delete, voice upload, WebSocket events, call signaling, push token storage.
- Flutter analyze/test используются перед релизами.
- Release APK split по ABI; текущий arm64 release около 30 MB.

## Что важно из Telegram и WhatsApp

### Telegram

Telegram делает упор на cloud sync между устройствами, username-based discovery, файлы любого типа, голосовые/видеозвонки, usernames, cloud storage и низкое потребление места на устройстве. Это хорошо ложится на наш проект, потому что у нас тоже server-side history и private family use case.

Особенно релевантные функции:

- seamless sync между несколькими устройствами;
- username вместо телефонной книги;
- файлы, фото, видео и документы;
- cache management;
- replies, точное цитирование части сообщения и rich link previews;
- multiple pinned messages в 1-на-1 чатах;
- reactions;
- chat folders/archive/pinned chats;
- in-chat search filters;
- live location alerts;
- Saved Messages как личное хранилище/закладки.

### WhatsApp

WhatsApp полезен как ориентир по бытовым сценариям: приватность конкретных чатов, простые голосовые, понятные read receipts, disappearing messages, редактирование сообщений и управление уведомлениями.

Особенно релевантные функции:

- edit sent messages;
- chat lock через пароль/биометрию устройства;
- hiding locked chat contents in notifications;
- disappearing messages with selectable durations;
- voice message UX: pause/resume recording, waveform, out-of-chat playback;
- view-once voice/media для чувствительной информации;
- silence unknown callers;
- privacy checkup/settings consolidation.

### Что пишут пользователи и open-source проекты

По Reddit и GitHub recurring themes такие:

- Saved Messages со временем превращаются в свалку, поэтому нужны tags/folders/search/bookmarks, а не просто один личный чат.
- Людям нужна отдельная bookmark/star функция, потому что pinned messages решают другую задачу.
- Delete/edit поведение должно быть предсказуемым и хорошо синхронизироваться между устройствами.
- В open-source chat SDK и Tinode как базовый набор часто входят typing indicator, read receipts, last online, audio messages, file messages, pinned messages, push notifications, user blocking и contact book integration.

## Топ-10 фич для My Messenger

### 1. Фото, файлы и media attachments

Что сделать:

- отправка фото, документов и небольших видео;
- preview thumbnail в чате;
- compression/resize фото на клиенте;
- серверное хранение в `uploads`;
- лимиты размера файла;
- download/open UI на Android/Web.

Почему это важно:

Для семейного мессенджера это почти обязательная функция: чеки, документы, фото, скриншоты, инструкции. Telegram/WhatsApp оба держат media sharing как базовую возможность.

Сложность: средняя.

Приоритет: очень высокий.

### 2. Starred/Bookmarked messages и личные заметки

Что сделать:

- отдельное действие `Star`/`Save`;
- экран `Saved`;
- фильтры: links, voice, files, photos, text;
- простые tags, например `важно`, `документы`, `покупки`;
- возможность сохранить сообщение из любого 1-на-1 чата без закрепления для второго человека.

Почему это важно:

Pinned messages нужны для общего контекста чата, а bookmarks нужны лично пользователю. Reddit-пользователи Telegram регулярно жалуются, что Saved Messages без нормальной организации превращаются в хаос. Для семьи это полезно под адреса, рецепты, документы, номера заказов.

Сложность: средняя.

Приоритет: очень высокий.

### 3. Chat Lock и приватные уведомления

Что сделать:

- lock конкретного чата;
- unlock через Android biometric/device credential;
- скрывать preview текста в системных уведомлениях для locked chats;
- настройка: показывать sender only / показывать "new message" / показывать полный текст.

Почему это важно:

WhatsApp Chat Lock закрывает личные переписки за биометрией и прячет содержимое уведомлений. Для семейного приватного мессенджера это практичнее, чем добавлять сложное end-to-end encryption прямо сейчас.

Сложность: средняя на Android, выше для Web.

Приоритет: высокий.

### 4. Typing / recording / uploading indicators

Что сделать:

- `typing...` в header и chat list;
- `recording voice...`;
- `uploading photo...`;
- debounce и auto-timeout через WebSocket.

Почему это важно:

Это маленькая по объему, но сильно "оживляющая" функция. Telegram показывает typing/recording/uploading состояния в 1-на-1 чатах. Для нашего UI это даст ощущение настоящего мессенджера.

Сложность: низкая-средняя.

Приоритет: высокий.

### 5. Улучшенные voice messages

Что сделать:

- pause/resume recording;
- lock recording свайпом вверх;
- waveform/progress, seek по записи;
- playback speed 1x/1.5x/2x;
- out-of-chat playback mini-player;
- draft preview before send;
- optional voice transcription позже.

Почему это важно:

WhatsApp отдельно развивал voice UX: pause/resume, waveform, playback outside chat. У нас voice уже есть, поэтому улучшение даст большой эффект без полной новой подсистемы.

Сложность: средняя.

Приоритет: высокий.

### 6. Per-chat notification settings и ringtone settings

Что сделать:

- mute chat на 1 час/8 часов/навсегда;
- custom notification sound per chat;
- отдельный ringtone channel для calls;
- quiet hours;
- badge/unread counters;
- настройка preview текста.

Почему это важно:

Для семьи у каждого контакта разный уровень срочности. Плюс Android уже умеет notification channels, и это хорошо использовать системно: сообщения отдельно, звонки отдельно.

Сложность: средняя.

Приоритет: высокий.

### 7. Pinned chats, archive и компактная организация списка

Что сделать:

- pin chat вверху списка;
- archive chat;
- unread filter;
- simple folders: `Family`, `Important`, `All`;
- сортировка по last message/unread/pinned.

Почему это важно:

Группы нам не нужны, но порядок в списке нужен. Telegram folders/archive/pinned chats решают именно навигацию и уменьшают шум.

Сложность: средняя.

Приоритет: средне-высокий.

### 8. Offline queue, retries и честные статусы доставки

Что сделать:

- локальная очередь исходящих сообщений;
- retry upload для текста, voice, media;
- состояния: sending, sent to server, delivered to peer device, read;
- понятные ошибки и resend button;
- сохранение draft при закрытии приложения.

Почему это важно:

Это не "красивая фича", а надежность. Пользователь не должен терять голосовое/фото из-за слабого интернета. Reddit-жалобы на исчезающие/несинхронизированные сообщения показывают, что предсказуемость важнее эффектов.

Сложность: высокая.

Приоритет: высокий.

### 9. Rich link previews и базовое форматирование текста

Что сделать:

- preview для URL: title, domain, description, thumbnail;
- возможность отключить preview перед отправкой;
- bold/italic/code/quote;
- quote selected text в reply;
- collapsible long quote позже.

Почему это важно:

В семейных чатах часто кидают ссылки на товары, документы, карты, видео. Telegram развивал adjustable link previews и точное цитирование как everyday features.

Сложность: средняя.

Приоритет: средний.

### 10. Location sharing для встреч

Что сделать:

- отправить текущую геопозицию;
- открыть в Google Maps/Yandex Maps;
- live location на 15/60 минут позже;
- proximity alert как optional future step.

Почему это важно:

Для родственников это практично: "я здесь", "где тебя забрать", "доехал ли". Telegram развивал live location alerts, но нам можно начать со static location.

Сложность: средняя для static, высокая для live.

Приоритет: средний.

## Что пока не стоит добавлять

- Группы и каналы: не соответствуют текущему use case.
- Реклама, монетизация, публичные discovery-функции.
- Боты и mini apps: мощно, но уводит проект в платформу.
- Stories/status: не критично для семейного 1-на-1.
- Видео-звонки: заметно сложнее voice calls, нагрузка и UX выше.
- Полное end-to-end encryption: полезно, но это отдельный большой security-проект; сначала лучше стабилизировать reliability, backup, privacy UI и доступ к устройству.
- AI features: можно позже как локальный helper, но сейчас не базовая потребность.

## Предлагаемый порядок реализации

### Этап 1: максимум пользы за короткое время

1. Typing/recording indicators.
2. Star/bookmark messages.
3. Улучшить voice messages: pause/resume, seek, playback speed.
4. Per-chat mute и notification preview settings.

### Этап 2: бытовая полноценность

5. Фото/файлы/media attachments.
6. Rich link previews.
7. Pinned chats/archive/unread filters.

### Этап 3: надежность и приватность

8. Offline queue/retries/drafts.
9. Chat Lock/biometric/privacy notifications.
10. Static location sharing, потом live location.

## Использованные источники

- Telegram FAQ: https://www.telegram.org/faq
- Telegram replies/link previews: https://www.telegram.org/blog/reply-revolution
- Telegram pinned messages/live locations/playlists: https://telegram.org/blog/pinned-messages-locations-playlists
- Telegram reactions/spoilers/translations/QR: https://telegram.org/blog/Reactions-spoilers-Translations%20?setln=en
- Telegram folders/archive: https://telegram.org/blog/folders?setln=en
- WhatsApp edit messages: https://about.fb.com/news/2023/05/edit-whatsapp-messages/
- WhatsApp Chat Lock: https://about.fb.com/news/2023/05/whatsapp-chat-lock/
- WhatsApp voice message features: https://about.fb.com/news/2022/03/new-voice-message-features-on-whatsapp/
- WhatsApp disappearing messages durations: https://about.fb.com/news/2021/12/whatsapp-default-disappearing-messages-multiple-durations/
- Chat SDK Android feature list: https://github.com/chat-sdk/chat-sdk-android
- Tinode chat feature list: https://github.com/tinode/chat
- Reddit: Saved Messages organization problem: https://www.reddit.com/r/Telegram/comments/1s8hllo/how_do_you_stop_telegram_saved_messages_from/
- Reddit: bookmark feature wish: https://www.reddit.com/r/Telegram/comments/1qiytev/i_wish_there_were_a_bookmark_feature_in_telegram/
- Reddit: WhatsApp delete-for-everyone frustration: https://www.reddit.com/r/whatsapp/comments/1d05sqw/frustration_with_whatsapps_delete_for_everyone/
