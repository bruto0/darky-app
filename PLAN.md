# D'arky — план разработки и разбиение на субагентов

**Версия:** 1.1 · **Дата:** 20.11.2026
**Статус:** дизайн утверждён, Foundation/Auth и MVP-разделы реализованы; Auth и фичи проверены на AVD API 37 с живым API. Следующий этап — интеграционный QA/RC.

Документы:

- [design/DESIGN.md](design/DESIGN.md) — дизайн, правила, маппинг данных;
- [design/README.md](design/README.md) — эскизы, иконка, борд;
- [design/LIVE-FINDINGS.md](design/LIVE-FINDINGS.md) — проверенные факты живого кабинета;
- [docs/mobile-auth/](docs/mobile-auth/README.md) — протокол виджета, безопасность;
- [docs/impulsecrm-api/](docs/impulsecrm-api/README.md) — справочник документированного API (для контекста).

---

## 1. Ворота: дизайн согласован, код ещё не начат

Решения D1–D16 **приняты 19–20.11.2026**, дизайн утверждён. Foundation, Auth и MVP-разделы реализованы и проверены на AVD API 37 с живым API; 183 теста. Следующий шаг — интеграционный QA/RC.

Принято:

1. **Темы:** четыре — Светлая, Тёмная, Розовая, Системная; выбор в диалоге из меню `⋮` справа от выхода.
2. **Навигация:** нижние 4 таба.
3. **Расписание:** внутри «Абонемента», один скролл; FAB обновления с drag + clamp.
4. **Чужая аренда:** «аренда» + зал, без имени.
5. **Действия:** оплата убрана; «Заморозить» — full width в карточке абонемента, где заморозка доступна (у «Стандарт» её нет — пояснение).
6. **Отмена записи:** этап 6 после спайка.
7. **QR:** в MVP.
8. **Package id:** `ru.darky.dance`.
9. **BFF:** не будет.
10. **HTTP-профиль:** мимикрия под мобильный Chrome, версия с устройства (Chrome → WebView → default): UA, `Accept`, `Accept-Language`, `Origin`/`Referer`, `Sec-Fetch-*`; cookie-less.
11. **Авторизация (D15):** нативный логин телефон + пароль, `phone_info` → `check_password` → `search`; WebView из auth убран. **Восстановление (D16):** ссылка открывает `/widget/2` во внешнем браузере.
12. **Уровень мимикрии L2 (D14):** low-entropy Client Hints, `gzip, deflate, br, zstd`, языки устройства, `Priority`; L3 — опция на случай WAF.

До команды продолжать — только документация и эскизы.

---

## 2. Что уже готово

| Артефакт | Состояние |
|---|---|
| Экраны в 2× (1560×3376) + FAB-схема + длинная главная | [design/mockups](design/mockups) |
| Борд 3290×5268 | [design/board.png](design/board.png) |
| Иконка 2048/1024 + adaptive/mono | [design/icon](design/icon) |
| Четыре темы, меню и диалог | [DESIGN.md §2.3](design/DESIGN.md#23-четыре-темы), [§4.9](design/DESIGN.md#49-меню-и-темы) |
| FAB: границы и поведение | [DESIGN.md §4.3](design/DESIGN.md#43-расписание), [12-fab-spec.png](design/mockups/12-fab-spec.png) |
| Дизайн-система (цвета, шрифт, компоненты) | [DESIGN.md §2](design/DESIGN.md#2-визуальный-язык) |
| Правило индивидуальных занятий | [DESIGN.md §5.3](design/DESIGN.md#53-правило-индивидуальных-занятий-ключевое) |
| Auth-хендофф native → client_id/secret | [DESIGN.md §5.1](design/DESIGN.md#51-авторизация-и-передача-сессии), [LIVE-FINDINGS §1](design/LIVE-FINDINGS.md#1-вход-в-виджет-что-реально-происходит) |
| Маппинг полей API → UI | [DESIGN.md §6](design/DESIGN.md#6-маппинг-данных) |
| Живые payload’ы и подводные камни | [LIVE-FINDINGS.md](design/LIVE-FINDINGS.md) |
| Проверка абонементов и заморозки | 2 активных; заморозка только у «Профи» (21 день); «Стандарт» — без заморозки |
| Окружение сборки | JDK 21, Android SDK 36, Flutter 3.50; [BUILD-ENV.md](BUILD-ENV.md) |
| План этапов и промпты субагентов | этот файл |

---

## 3. Целевая архитектура

### 3.1. Стек

| Слой | Решение | Почему |
|---|---|---|
| Язык / UI | Flutter (stable), Dart 3 | одна кодовая база Android/iOS |
| Состояние | Riverpod 2.x, `AsyncNotifier`, без codegen | меньше сборки, предсказуемые тесты |
| Роутинг | `go_router`, `StatefulShellRoute.indexedStack` | 4 таба с сохранением состояния |
| Сеть | `dio` + интерсепторы, ручные `fromJson` | без build_runner, меньше конфликтов |
| Нативный логин | Flutter TextField + AutofillGroup | без WebView; быстрый вход, стандартный autofill |
| Браузер | `url_launcher` | восстановление пароля во внешнем браузере (D16) |
| Секреты | `flutter_secure_storage` (Keystore/Keychain) | не хранить пароль/secret в открытом виде |
| Настройки | `shared_preferences` | тема, фильтры, последняя вкладка |
| Кэш | JSON-файлы в `path_provider` + TTL | без БД на MVP |
| Даты | `intl` + фиксированное смещение клуба | не зависим от часового пояса устройства |
| Тесты | `flutter_test`, `mocktail`, `http_mock_adapter`, `integration_test` | покрытие без внешних сервисов |
| Логи | `logger` + redaction | без ПДн и секретов |
| Сборка | JDK 21 (Temurin), Android SDK 36, Flutter 3.50 | проверено; см. [BUILD-ENV.md](BUILD-ENV.md) |

### 3.2. Структура репозитория

```
app/
  lib/
    main.dart
    app/
      app.dart            # MaterialApp, тема, локаль
      router.dart         # go_router, 4 таба
      shell.dart          # нижняя навигация
      config.dart         # baseUrl, widgetId, branchId, tz, feature flags
    core/
      ui/                 # tokens, 4 темы, кнопки, чипы, карточки, skeleton, empty/error
      theme/              # ThemeController (light/dark/pink/system), persistence
      network/            # ApiClient, ApiFailure, interceptors
      storage/            # SecureStore, Prefs, JsonCache
      auth/               # Session, SessionStore, SessionController
      time/               # BranchClock, formatters
      logging/            # redaction
    features/
      auth/
      schedule/
      account/
      visits/
      purchases/
      bookings/
  test/
    fixtures/             # санитизированные JSON
    core/
    features/
  integration_test/
  android/
  ios/
```

Каждая фича:

```
features/<name>/
  data/        # dto, api, repository_impl
  domain/      # модели, repository interface, view models
  presentation/# экраны, виджеты, контроллеры
  <name>_feature.dart  # routes + providers (единственная точка входа)
```

### 3.3. Поток данных

```
Native login phone + password → phone_info → check_password → widget_client_lk/search → Session(clientId, secret, profile)
        ↓
SessionStore (Keystore) → ApiClient (client_id + secret в body) → репозитории фич → Riverpod → UI
```

`ApiClient` не знает про `secret`: его подставляет `SessionInterceptor` из `SessionStore` только для клиентских методов. Логи редактируют `secret`, телефон, ФИО.

`ApiClient` — cookie-less Dio/OkHttp с **Chrome-профилем L2**: `User-Agent` Chrome mobile с major с устройства (Chrome → WebView → `defaultChromeMajor`), `Accept: application/json, text/plain, */*`, `Accept-Language` из локалей устройства, `Content-Type: application/json`, `Origin`/`Referer` из `baseUrl`, `Sec-Fetch-Site/Mode/Dest`, low-entropy `Sec-CH-UA` / `Sec-CH-UA-Mobile: ?1` / `Sec-CH-UA-Platform: "Android"`, `Priority: u=1, i`, `Accept-Encoding: gzip, deflate, br, zstd` (с Brotli/Zstd-декодерами). **Без** `Cookie`, `X-Requested-With`, `Authorization`, high-entropy hints. API это не требует (проверено), но профиль выбран продуктово.

### 3.4. Конфиг

| Ключ | Значение MVP |
|---|---|
| `baseUrl` | `https://4621c03198bd6735334088.impulsemini.ru` |
| `widgetId` | `2` |
| `branchId` | `1` |
| `branchTimezoneOffset` | `420` (UTC+7, из `branch.options`) |
| `browserProfile` | Chrome mobile **L2**, версия динамическая: `com.android.chrome` → WebView → `defaultChromeMajor`; UA, `Accept`, device `Accept-Language`, `Sec-Fetch-*`, low-entropy `Sec-CH-UA*`, `Priority`; `Origin`/`Referer` из `baseUrl`; cookie-less |
| `compression` | `gzip, deflate, br, zstd`; обязательны Brotli/Zstd-декодеры и тест по `Content-Encoding` |
| `defaultChromeMajor` | `156` — fallback, если Chrome/WebView недоступны; обновлять с релизами |
| `appPackage` | `ru.darky.dance` |
| `enableBarcode` | `true` |
| `enableFreeze` | `true` (веб-сценарий клуба) |
| `enableCancel` | `true` (после спайка) |
| `defaultTheme` | `light` |
| `availableThemes` | `light`, `dark`, `pink`, `system` |
| `draggableFab` | `true` (clamp в safe area) |
| `enablePayment` | `false` — оплата убрана (D5) |

Никаких API-ключей и паролей в конфиге/репозитории. `client_id`/`secret` — только в secure storage после входа.

### 3.5. Окружение сборки

Зафиксировано в [BUILD-ENV.md](BUILD-ENV.md), скрипт — [tools/env.ps1](tools/env.ps1):

- JDK 21: `D:\distrib\devel\java\jdk-21.0.13+9` (Temurin);
- Android SDK: `C:\Users\kir\AppData\Local\Android\Sdk`, platform `android-35`, build-tools `35.0.0`;
- Flutter stable 3.50: `D:\distrib\devel\flutter`;
- Gradle cache: `J:\.gradle`;
- AVD: `Medium_Phone_API_37.0`; для Android 15 создать `DARKY_API_35` (инструкция в BUILD-ENV).

Перед любой сборкой/тестом:

```powershell
. .\tools\env.ps1
```

---

## 4. Контракты (замораживаются до параллельной работы)

### 4.1. Интерфейсы

| Контракт | Методы | Вход | Выход | Ошибки |
|---|---|---|---|---|
| `AuthRepository` | `restore`, `completeLogin`, `completeNativeLogin`, `logout` | телефон + пароль | `Session` | `AuthFailure`, `ApiFailure` |
| `SessionStore` | `read`, `write`, `clear` | — | `Session?` | `StorageFailure` |
| `ThemeController` | `load`, `setMode`, `mode` | `light/dark/pink/system` | `AppThemeMode` | `StorageFailure` (не критично) |
| `ChromeVersionProvider` | `chromeMajor`, `source` | — | `int`, `chrome/webview/default` | — |
| `ApiClient` | `post`, `get` | path, body | `Map/String` | `ApiFailure` |
| `ScheduleRepository` | `loadDay`, `loadStickers`, `loadChanges`, `invalidate` | дата, фильтры | `DaySchedule` | `ApiFailure` |
| `AccountRepository` | `loadAccounts`, `loadSummary`, `loadBarcode` | — | модели | `ApiFailure` |
| `VisitsRepository` | `loadPage`, `refresh` | page | `Page<Visit>` | `ApiFailure` |
| `PurchasesRepository` | `loadPage`, `refresh` | page | `Page<Deposit>` | `ApiFailure` |
| `BookingsRepository` | `loadUpcoming`, `cancel` | id, дата | `List<Booking>` | `ApiFailure` |
| `BranchClock` | `now`, `dayStart`, `formatDay`, `formatTime`, `weekday` | — | даты/строки | — |

### 4.2. Модели (минимум полей)

| Модель | Поля |
|---|---|
| `Session` | `clientId:int`, `secret:String`, `profile:ClientProfile`, `createdAt` |
| `ClientProfile` | `id`, `lastName`, `name`, `middleName`, `branchName`, `photoUrl?`, `bonus` |
| `Account` | `id`, `entity`, `typeName`, `typeColor`, `active`, `closed`, `freeze`, `freezeDaysLeft`, `freezeAvailable`, `trainingsLeft/Total`, `packets`, `endDate`, `cost`, `paid` |
| `AccountPacket` | `name`, `count`, `used`, `unit`, `days?`, `value?` |
| `ScheduleItem` | `id`, `type`, `minutesBegin/End`, `color`, `hall`, `group`, `style`, `teacher`, `client`, `regular`, `date`, `dateBegin`, `dateEnd`, `day` |
| `LessonVm` | `time`, `duration`, `kind`, `title`, `subtitle`, `hall`, `color`, `stickers`, `substitution`, `isOwn` |
| `Visit` | `id`, `visitDate`, `styleName`, `level`, `teachers`, `branchName`, `accountNumber?`, `byAccount`, `minutesBegin/End` |
| `Deposit` | `id`, `created`, `typeText`, `sum`, `paymentText`, `accountNumber?` |
| `Booking` | `id`, `type`, `occurrenceAt`, `minutesBegin/End`, `hallName`, `branchName`, `cancellable` |
| `Page<T>` | `items`, `total`, `page`, `hasMore` |

### 4.3. Ошибки

`ApiFailure` — sealed:

- `NetworkFailure` — нет сети/DNS/TLS;
- `TimeoutFailure` — 15–20 с;
- `UnauthorizedFailure` — 401 / `LogicException` доступа;
- `VendorFailure` — 4xx/5xx с человеческим `message`;
- `ParseFailure` — неожиданный JSON/обфускация;
- `UnknownFailure`.

UI-маппинг — таблица в [DESIGN.md §5.7](design/DESIGN.md#57-ошибки).

### 4.4. Общие виджеты (создаёт Foundation)

`AppScaffold`, `BottomNavShell`, `SectionHeader`, `FilterPill`, `WeekStrip` (базовая), `PrimaryButton`, `SecondaryButton`, `StatusChip`, `StickerChip`, `SheetScaffold`, `SkeletonBox`, `EmptyState`, `ErrorState`, `MoneyText`, `TimeText`, `Avatar`.

Фичи не редактируют `core/ui`, а добавляют свои виджеты в `features/<name>/presentation`.

### 4.5. Роуты

```
/splash
/auth
/home            (таб 0: Абонемент + расписание)
/visits          (таб 1)
/purchases       (таб 2)
/bookings        (таб 3)
/barcode         (modal, из профиля)
```

### 4.6. Фикстуры (Foundation)

Санитизированные JSON в `app/test/fixtures/`:

- `search_decoded.json` — профиль без реальных ФИО/телефона/secret;
- `accounts.json` — 2 активных: «Профи» с 21 днём заморозки и «Стандарт» без дней; плюс закрытый для edge-case;
- `schedule_day.json` — 20 занятий: группы, свои «индив», чужие «индив», аренды, null-teacher;
- `schedule_empty.json`;
- `visits_page_1/2.json`;
- `deposits_page_1/2.json`;
- `bookings.json`;
- `errors.json` — 401, 500, timeout.

Фикстуры — единственный источник для unit/golden-тестов; живые ПДн не коммитим.

### 4.7. Протокол изменения контрактов

Любое изменение интерфейса/модели/роута — отдельный PR в `foundation` с записью в `CONTRACT-CHANGELOG.md`, уведомление всех агентов. Фичи не меняют `core/*` и `pubspec.yaml`; зависимости запрашиваются у интегратора.

---

## 5. Этапы

### Сводная таблица

| Этап | Что | Зависит от | Параллельно с | Оценка |
|---|---|---|---|---|
| 0 | Утверждение дизайна и решений D1–D16 | — | — | готово |
| 1 | Foundation: каркас, 4 темы, контракты, фикстуры, иконка | 0 | — | готово |
| 2 | Auth: нативный логин, хендофф, сессия | 1 | 3, 4, 5, 6 | готово; проверено на AVD API 35 |
| 3 | Schedule: расписание, фильтры, карточки, FAB | 1 | 2, 4, 5, 6 | готово; stickers/changes, privacy, FAB |
| 4 | Account: профиль, меню, темы, заморозка, QR, выход | 1 (+3) | 2, 3, 5, 6 | готово; заморозка через кабинет |
| 5 | History: посещения и покупки | 1 | 2, 3, 4, 6 | готово; пагинация/группы |
| 6 | Bookings: записи, отмена/спайк | 1 | 2, 3, 4, 5 | готово; отмена через кабинет |
| 7 | Интеграция, QA, RC | 2–6 | — | в работе |
| 8 | Действия: нативная заморозка, запись, push | 7 | — | 4–6 дней |
| 9 | Hardening и iOS (без BFF) | 7 | 8 | 5–8 дней |

Календарь при 5 параллельных агентах: **~14–16 рабочих дней до RC** (3 foundation + 5 параллельных + 5 интеграции), плюс 2–3 дня на устройство/релиз. Последовательно те же этапы — ~28 дней.

### Этап 0 — утверждение (выполнено)

- Просмотр [board.png](design/board.png), [DESIGN.md](design/DESIGN.md), этого плана.
- Решения D1–D16 приняты 19–20.11.2026, зафиксированы в `DESIGN.md §10` и [APPROVAL.md](design/APPROVAL.md).
- Дизайн утверждён; этап 1 реализован 19.11.2026. Git-репозиторий инициализируется на этапе 1.

### Этап 1 — Foundation (выполнено 19.11.2026)

**Цель:** запускаемое приложение-каркас, в которое пять агентов независимо вставляют фичи.

**Результат:** `app/` собирается и запускается на Android 15; `flutter analyze` — 0, `flutter test` — 30 тестов, debug APK собран. Проверены 4 темы, 4 таба, сохранение темы после перезапуска, Chrome 124 на тестовом AVD (hints не отправляются, т.к. major 124 не в таблице GREASE).

**Deliverables:**

- `app/` с Flutter-проектом, `flutter analyze` = 0, `flutter test` зелёный.
- Тема из токенов DESIGN.md: **четыре темы** (light/dark/pink/system), `ThemeController` + `shared_preferences`, шрифт Manrope (OFL), иконка/adaptive/splash.
- 4-табовый shell с заглушками и сохранением состояния.
- `ApiClient`, `ApiFailure`, `SessionStore`, `BranchClock`, `JsonCache`, `AppConfig`, логирование с redaction.
- `ChromeVersionProvider`: platform channel в `MainActivity` + `<queries>` для `com.android.chrome`/WebView; версия Chrome → WebView → `defaultChromeMajor`; `browserProfile` собирается из major.
- `ChromeHints`: low-entropy `Sec-CH-UA`/`Mobile`/`Platform`; GREASE-бренд из таблицы известных major (156 — `Not:A-Brand` v8); если major неизвестен — **не отправлять** `Sec-CH-UA`, чтобы не подделывать неверный бренд.
- `ApiClient` headers: Chrome mobile **L2** с версией с устройства (UA, Accept, device Accept-Language, Origin/Referer, Sec-Fetch, low-entropy Sec-CH-UA*, Priority), cookie-less; без `X-Requested-With`/high-entropy hints; тест точных заголовков, fallback и отсутствия cookie jar.
- `Accept-Encoding: gzip, deflate, br, zstd` + Brotli/Zstd-декодеры; тест ответов с каждым `Content-Encoding`. **Spike:** выбрать декодеры (pure Dart/FFI/native); если надёжного нет — остановиться и доложить, не откатывать L2 молча.
- Контракты из §4 и fake-реализации; фикстуры.
- CI-скрипт: analyze, test, build debug APK.
- README запуска.

**Файлы:** `app/pubspec.yaml`, `app/lib/app/**`, `app/lib/core/**` (включая `core/browser`), `app/lib/main.dart`, `app/android/**` (включая `AndroidManifest.xml` и `MainActivity`), `app/ios/Runner/**` (минимально), `app/test/core/**`, `app/test/fixtures/**`, `app/README.md`.

**Критерии:**

- `flutter run` на Android 15 emulator: 4 таба, четыре темы (переключение), иконка в лаунчере, splash.
- `ChromeVersionProvider` возвращает major установленного Chrome; при его отсутствии — WebView/default; UA в `ApiClient` содержит этот major.
- `flutter analyze` 0; `flutter test` зелёный.
- `git grep` не находит телефонов, паролей и `secret` (проверка по шаблонам в CI).
- Токены совпадают с DESIGN.md (unit-тест значений).
- Edge-to-edge и SafeArea на Android 15.

### Этап 2 — Auth (агент A)

**Цель:** нативный вход (D15) и надёжная передача сессии; WebView больше не используется.

**Deliverables:**

- `WidgetCodec`: encodePhone/decodePayload + векторы из `docs/mobile-auth/samples/phone-encode.md`.
- Нативный экран: телефон + пароль, `AutofillGroup`/`AutofillHints`, eye-toggle, тема, ошибки, loading.
- `phone_info` → `check_password` → `widget_client_lk/search`; `Session` (client_id, secret, профиль) в Keystore/Keychain.
- Восстановление (D16): ссылка открывает `/widget/2` во внешнем браузере (`url_launcher`); отдельного recovery-URL у вендора нет.
- `SessionStore`, восстановление при старте, 401 → auth, logout без cookies/WebView.
- `FLAG_SECURE` на auth (Android; на iOS — по возможности).
- Ошибки: телефон не найден, пароль не задан, неверный пароль, нет сети, 5xx.
- Пароль не хранится и не логируется; после успеха `TextInput.finishAutofillContext(shouldSave: true)`.

**Файлы:** `app/lib/features/auth/**`, `app/lib/core/auth/**`, `app/test/core/auth_repository_test.dart`.

**Критерии:**

- Валидный тестовый вход → home; неверный пароль → сообщение; recovery открывает браузер.
- Перезапуск приложения → сессия восстановлена; logout → чистое состояние.
- В логах нет пароля/secret/телефона; `FLAG_SECURE` в release.
- Unit: codec, session store, native auth (phone_info/check_password/search, wrong password); ручной сценарий на AVD.

### Этап 3 — Schedule (агент B)

**Цель:** расписание на день полной высоты, все типы, правило приватности.

**Deliverables:**

- DTO/репозиторий `widget_schedule/list` (from=to=начало дня в поясе клуба), `stickers`, `changes`.
- `ScheduleSection` как sliver для `CustomScrollView` (не вложенный `ListView`).
- Неделя, переключение дня, фильтры зал/преподаватель (клиентская фильтрация по загруженному дню; опции из несфильтрованных данных).
- Карточки: группа, своё «индив», чужое «индив» (компакт), своя/чужая аренда (D4), стикеры, замены.
- **FAB обновления 52 dp**: тап — перезагрузка дня, drag — перемещение; clamp в safe area (круг целиком, даже частично за край нельзя), позиция в prefs, TalkBack custom action, спиннер при загрузке.
- Состояния: loading skeleton, empty, error, кэш 5 мин.
- Тесты: маппер/приватность, golden 4 вариантов, «ровно один Scrollable», 30+ элементов, FAB clamp при всех drag-делтах, tap vs drag.

**Файлы:** `app/lib/features/schedule/**`, `app/test/features/schedule/**`.

**Критерии:**

- 20 занятий дня видны полностью, без внутреннего скролла; последний элемент доступен.
- У чужого «индив» нет ФИО/преподавателя/депозита; у своего есть имя + преподаватель (если есть) + зал.
- Фильтры работают; пустой день/ошибка не ломают неделю.
- FAB после любого drag остаётся целиком в safe area; позиция восстанавливается; тап обновляет только расписание.
- Нет `shrinkWrap: true` внутри `SingleChildScrollView`.

### Этап 4 — Account / Header / Themes (агент C)

**Цель:** профиль, абонемент(ы), меню, четыре темы, заморозка, QR, выход.

**Deliverables:**

- `AccountRepository`, маппинг пакетов (проверить на фикстурах).
- Профиль: аватар/инициалы, имя, бонус во второй строке, QR, выход, **меню `⋮` справа от выхода**.
- Меню: поповер «Тема оформления» + «О приложении».
- **Диалог четырёх тем** (Светлая/Тёмная/Розовая/Системная) 2×2 с превью, активной галочкой, «Готово»; применяет `ThemeController` сразу и сохраняет выбор; фон расписания следует теме (D11).
- Карточки абонентов: отдельная на каждого, тип/цвет/статус, счётчики, срок; у «Профи» — 5 счётчиков, у «Стандарт» — только занятия и срок.
- **Заморозка per-account**: full-width кнопка только в карточке, где `freezeEnable && active && !closed && !freeze && freezeDaysLeft > 0`; у «Стандарт» — пояснение «Заморозка не предусмотрена тарифом». Кнопка открывает веб-сценарий клуба в модальном WebView (у клиента один freezeable-абонемент, выбор однозначен). Кнопки «Оплатить» нет.
- QR-лист: base64 PNG, обновление, яркость, FLAG_SECURE.
- Выход: подтверждение, очистка, переход на auth.
- Встраивание `ScheduleSection` из этапа 3 (если готов; иначе — контрактная заглушка).
- Тесты: маппинг пакетов, `freezeAvailable` для обоих абонементов, golden тем/меню/диалога, QR decode, logout, отсутствие «Оплатить».

**Файлы:** `app/lib/features/account/**`, `app/lib/features/profile/**` (если выделяется), `app/test/features/account/**`.

**Критерии:**

- Значения совпадают с вебом на тестовом клиенте: «Профи» 20/24 + 21/21 заморозки; «Стандарт» 3/5 без заморозки; закрытые не ломают экран.
- Меню открывается справа от выхода; диалог показывает четыре темы; смена применяется сразу и сохраняется после перезапуска.
- В розовой теме расписание — розовый блок, в тёмной — тёмный фон, в светлой — фон страницы.
- «Заморозить» — full width только у «Профи»; у «Стандарт» кнопки нет, есть пояснение; «Оплатить» отсутствует.
- QR открывается, читается сканером, скриншот запрещён.
- Выход очищает все следы; повторный вход работает.

### Этап 5 — History (агент D)

**Цель:** посещения и покупки с пагинацией.

**Deliverables:**

- `VisitsRepository` с обязательным `sort.visit_date`; `PurchasesRepository` с `type:[11,12,13]`.
- Экраны: карточки посещений, месячные группы покупок, бесконечный скролл по 20, pull-to-refresh.
- Состояния: empty, error, кэш 5 мин.
- Тесты: DTO, пагинация без дублей, golden.

**Файлы:** `app/lib/features/visits/**`, `app/lib/features/purchases/**`, `app/test/features/visits/**`, `app/test/features/purchases/**`.

**Критерии:**

- 89 посещений листаются страницами; нет 500 из-за сортировки.
- Покупки группируются по месяцам; суммы зелёные; нет дублей на стыке страниц.
- Пустые состояния и ошибки.

### Этап 6 — Bookings (агент E)

**Цель:** свои записи и (если подтверждено) отмена.

**Deliverables:**

- `BookingsRepository` на `widget_client_lk/schedule`.
- Разворачивание регулярных занятий до ближайшего наступления; фильтр «предстоящие»; сортировка.
- Карточка: дата, тип, зал, филиал, время, день недели, кнопка отмены.
- Спайк отмены: снять payload `unsubscribe` с бандла/тестовой записи; если подтверждено — confirmation sheet, вызов, optimistic update + rollback; иначе кнопка открывает WebView `/widget/2`.
- CTA «Хотите записаться?» → расписание.
- Тесты: разворачивание, сортировка, отмена/fallback.

**Файлы:** `app/lib/features/bookings/**`, `app/test/features/bookings/**`.

**Критерии:**

- Аренда 23 ноября отображается корректно; прошедшие скрыты.
- Отмена либо работает и подтверждается, либо честно ведёт в кабинет клуба; данные не теряются.
- Нет ложных «предстоящих» для завершённых регулярных.

### Этап 7 — Integration & QA (агент Q, после 2–6)

**Цель:** собрать фичи в приложение, прогнать на живом контуре и устройстве, выпустить RC.

**Deliverables:**

- Проводка роутов/провайдеров, удаление заглушек, фичефлаги.
- Интеграционные тесты на mock-server (login → home → schedule → theme dialog → tabs → logout).
- Golden-матрица 360/390/412, font scale 1.0/1.3, **четыре темы**.
- Ручной чек-лист Android 15 (эмулятор + устройство), TalkBack, edge-to-edge, predictive back, FAB drag/clamp.
- Performance: 30+ занятий, 60 fps, время старта.
- Release build (AAB), internal track, инструкция.
- Обновление README/CHANGELOG.

**Критерии:**

- Все критерии этапов 2–6; нет P0/P1.
- Темы переключаются и сохраняются; «Оплатить» отсутствует; «Заморозить» full width только у абонемента с заморозкой.
- FAB не выходит за safe area даже после агрессивного drag.
- Холодный старт < 3 с на среднем устройстве; список не дёргается.
- 401/офлайн/пустые состояния проверены.
- AAB собирается, подпись, versionCode, targetSdk 35.

### Этап 8 — Действия (после MVP)

- Нативная заморозка: спайк API/веб-сценария, календарь дат, правила.
- Запись на групповые/индивидуальные, отмена, лист ожидания.
- Push-уведомления (если вендор даст контур).
- Оплата **не возвращается** — по решению D5 её нет в приложении.
Оценка 4–6 дней; требует отдельного согласования.

### Этап 9 — Hardening и iOS (без BFF)

- Аудит 152-ФЗ, политика, согласия, Data Safety в Play.
- iOS: WKWebView, Keychain, подпись, TestFlight, App Store review.
- Certificate pinning (осторожно с Let's Encrypt), обфускация, anti-tamper, Play Integrity (если применимо).
- BFF **не делаем** (D10); остаточный риск `secret` фиксируем в письменном виде для владельца клуба.
Оценка 5–8 дней.

---

## 6. Параллельная карта

```
День  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
0     [approved]
1     [Foundation ———]
2                          [Auth ——————]
3                          [Schedule ————————]
4                          [Account ——————]
5                          [History ————]
6                          [Bookings ————]
7                                        [Integration/QA ——————]
8                                                     [Actions (opt)]
9                                                     [iOS/hardening (opt)]
```

- **G1:** Foundation merged → стартуют A–E одновременно.
- **G2:** Auth + Schedule + Account merged → интегратор начинает сборку каркаса и e2e.
- **G3:** все пять фич merged → полный QA.
- **G4:** RC + internal track.
- History и Bookings могут догонять QA; главное — не менять контракты после G2 без changelog.

---

## 7. Промпты для субагентов (отдельные сессии)

> Использовать **после команды продолжать**. Каждый промпт самодостаточен: агент не видит этот чат.
> Вставьте промпт в новую сессию субагента; workspace — `J:\work\__dsh__\darky`.

### 7.0. Общая шапка (добавлять к каждому промпту)

```
Ты — субагент проекта D'arky (Flutter, Android 15+, клиентский кабинет D'arky Dance).
Workspace: J:\work\__dsh__\darky.
Перед кодом прочитай:
- design/DESIGN.md (дизайн и правила),
- design/LIVE-FINDINGS.md (живые факты API),
- PLAN.md (этот план, контракты и критерии),
- docs/mobile-auth/README.md, widget-auth.md, architecture.md,
- docs/mobile-auth/samples/phone-encode.md (для auth).
Дизайн утверждён; решения D1–D16 приняты и зафиксированы в DESIGN.md §10.
Работай только в своей ветке и только в файлах своей зоны (см. этап).
Перед сборкой/тестами: `. .\tools\env.ps1` (JDK 21, Android SDK 36, Flutter 3.50; см. BUILD-ENV.md).
Не меняй core/*, pubspec.yaml, router.dart без согласования с интегратором.
Не коммить пароли, телефоны, secret, реальные ФИО. Фикстуры — только санитизированные.
Код и тексты — русский UI, английские имена в коде.
В конце: список файлов, что протестировано, риски, что осталось.
```

### 7.1. Foundation

```
[общая шапка]
Этап 1 — Foundation. Создай app/ с Flutter-проектом и каркасом.
Сделай: токены и **четыре темы** DESIGN.md (light/dark/pink/system), ThemeController + shared_preferences,
Manrope, 4-табовый shell (Абонемент/Посещения/Покупки/Записи) с заглушками,
ApiClient (dio), ApiFailure, SessionStore, BranchClock (UTC+7), JsonCache, AppConfig, logging с redaction,
ChromeVersionProvider: PackageManager com.android.chrome -> WebView -> defaultChromeMajor; <queries> в манифесте; browserProfile динамический,
ChromeHints: low-entropy Sec-CH-UA/Mobile/Platform, GREASE из таблицы; неизвестный major -> без Sec-CH-UA,
headers ApiClient L2: Chrome mobile с major с устройства (UA, Accept, device Accept-Language, Origin/Referer, Sec-Fetch, low-entropy Sec-CH-UA*, Priority), Accept-Encoding gzip/deflate/br/zstd + декодеры; cookie-less, без X-Requested-With/high-entropy hints;
контракты и fake-реализации из PLAN.md §4, санитизированные фикстуры, CI-скрипт, README.
Иконка: design/icon/icon-2048.png → adaptive foreground/background/monochrome, splash.
Android: minSdk/target 35, compile 36 (требование flutter_secure_storage/shared_preferences_android), edge-to-edge, predictive back, portrait, package ru.darky.dance.
Сборка/тесты: `. .\tools\env.ps1`; JDK 21, Android SDK 36, Flutter 3.50 (BUILD-ENV.md).
Критерии: flutter analyze 0, flutter test зелёный, запуск на Android 15 emulator, переключение четырёх тем, иконка и 4 таба видны.
Не реализуй фичи — только каркас, темы и контракты.
```

### 7.2. Auth

```
[общая шапка]
Этап 2 — Auth. Реализуй нативный вход (D15) и передачу сессии.
Сделай: WidgetCodec (encodePhone, decodePayload) с тестами на векторах; экран входа по DESIGN.md §4.1;
телефон + пароль в AutofillGroup, phone_info → check_password → widget_client_lk/search, декод, Session;
SessionStore (Keystore/Keychain), restore при старте, 401 → auth, logout без WebView;
восстановление (D16) — url_launcher открывает /widget/2 во внешнем браузере;
FLAG_SECURE на auth; ошибки входа/сети/5xx; никаких паролей/secret в логах.
Критерии: валидный вход → home; неверный пароль → сообщение; recovery открывает браузер;
перезапуск восстанавливает сессию; logout чист; unit-тесты codec/session/native auth.
Не делай home/расписание — только auth и переход.
```

### 7.3. Schedule

```
[общая шапка]
Этап 3 — Schedule. Реализуй расписание на день по DESIGN.md §4.3 и §5.3.
Сделай: DTO/репозиторий widget_schedule/list (range from=to=начало дня в UTC+7), stickers/changes;
ScheduleSection как sliver для CustomScrollView, без вложенного ListView/SingleChildScrollView;
неделя, переключение дня, фильтры зал/преподаватель (клиентская фильтрация по загруженному дню);
карточки: группа, своё «индив» (имя клиента + teacher + зал), чужое «индив» (только «индив» + зал),
своя/чужая аренда (D4), стикеры, замены; loading/empty/error; кэш 5 мин.
FAB обновления 52 dp: тап — reload дня, drag — перемещение с clamp в safe area (круг целиком, без частичного выхода),
позиция в shared_preferences, спиннер, semantic label, custom action для TalkBack.
Критерии: 20 занятий видны полностью, последний элемент доступен, ровно один Scrollable;
у чужого «индив» нет ФИО/преподавателя; golden 4 вариантов; FAB clamp-тесты; маппер-тесты.
Работай с фикстурами; живые ПДн не коммить.
```

### 7.4. Account

```
[общая шапка]
Этап 4 — Account/Header/Themes. Реализуй главную: профиль, меню, четыре темы, абонементы, заморозку, QR, выход.
Сделай: AccountRepository, маппинг пакетов (fixtures), шапку профиля с QR, выходом и **меню ⋮ справа от выхода**,
поповер «Тема оформления» + «О приложении», **диалог четырёх тем** (Светлая/Тёмная/Розовая/Системная) 2×2
с превью и мгновенным применением через ThemeController; фон расписания следует теме (D11);
карточки абонентов: «Профи» 20/24 + 21/21 заморозки, «Стандарт» 3/5 без заморозки; несколько/закрытые;
**«Заморозить» full width только у «Профи»**, у «Стандарт» — пояснение «Заморозка не предусмотрена тарифом», «Оплатить» отсутствует;
QR-лист (barcode base64, обновление, FLAG_SECURE); выход с очисткой.
Встрой ScheduleSection из этапа 3 по контракту; если его нет — заглушка, не дублируй расписание.
Критерии: значения совпадают с вебом; меню и диалог работают; темы сохраняются после перезапуска; QR читается;
«Заморозить» только у «Профи» (full width), у «Стандарт» пояснения; «Оплатить» нет; выход чист; golden тем/меню/диалога; тесты маппинга и freezeAvailable.
```

### 7.5. History

```
[общая шапка]
Этап 5 — History. Реализуй «Посещения» и «Покупки» по DESIGN.md §4.4–4.5.
Сделай: VisitsRepository (sort.visit_date обязателен), PurchasesRepository (type [11,12,13]),
карточки посещений, месячные группы покупок, пагинацию по 20 без дублей, pull-to-refresh,
loading/empty/error, кэш 5 мин, golden.
Критерии: 89 посещений листаются, 500 из-за сортировки нет; суммы и месяцы корректны; нет дублей.
```

### 7.6. Bookings

```
[общая шапка]
Этап 6 — Bookings. Реализуй «Записи» по DESIGN.md §4.6.
Сделай: BookingsRepository на widget_client_lk/schedule; разворачивание регулярных до ближайшего наступления;
фильтр предстоящих; карточку (дата, тип, зал, филиал, время, день), CTA в расписание, empty/error.
Спайк отмены: сними payload unsubscribe с бандла/тестовой записи; если подтверждено — confirmation sheet,
вызов, optimistic update + rollback; иначе кнопка открывает WebView /widget/2 с честным текстом.
Критерии: аренда 23 ноября корректна; прошедшие скрыты; отмена работает или честно ведёт в веб; тесты.
```

### 7.7. Integration & QA

```
[общая шапка]
Этап 7 — Integration & QA. Собери все фичи в приложение и доведи до RC.
Проверь роуты/провайдеры/фичефлаги, убери заглушки, прогони analyze/test, добавь e2e на mock-server
(login → home → schedule → theme dialog → tabs → logout), golden 360/390/412 и font scale 1.3,
ручной чек-лист Android 15 (эмулятор + устройство), TalkBack, edge-to-edge, predictive back,
смена и сохранение четырёх тем, FAB drag/clamp, performance 30+ занятий, 401/офлайн/пустые, AAB с подписью.
Сборка: `. .\tools\env.ps1`; JDK 21, Android SDK 36, Flutter 3.50 (BUILD-ENV.md).
Критерии: все критерии этапов 2–6, нет P0/P1, холодный старт < 3 c, RC готов.
```

---

## 8. Правила параллельной работы

### 8.1. Ветки и merge

- `main` — только через PR; foundation мержится первым, тег `foundation-v1`.
- Фичи: `feat/auth`, `feat/schedule`, `feat/account`, `feat/history`, `feat/bookings` — от `foundation-v1`.
- Ежедневный rebase на `main`; PR ≤ 400 строк по возможности.
- Конфликты в `pubspec.yaml`, `router.dart`, `app.dart` решает интегратор; фичи их не трогают.
- Каждая фича добавляет один `feature.dart` и один тест-файл; интегратор подключает.

### 8.2. Зоны ответственности

| Агент | Пишет | Не трогает |
|---|---|---|
| Foundation | `app/lib/core/**` (включая `core/ui`, `core/theme`), `app/lib/app/**`, `main.dart`, `android/**`, `pubspec.yaml`, `fixtures`, CI | `features/**` (кроме заглушек) |
| Auth | `features/auth/**`, `test/features/auth/**` | core, router, pubspec |
| Schedule | `features/schedule/**` (FAB) | core, account, router |
| Account | `features/account/**`, `features/profile/**`, меню и диалог тем в `features/account/**` | core, schedule (только использует) |
| History | `features/visits/**`, `features/purchases/**` | core, router |
| Bookings | `features/bookings/**` | core, router |
| QA | `integration_test/**`, `test/golden/**`, `tool/**`, релизные настройки | фичи (только багфиксы через PR) |

### 8.3. Definition of Done для каждой фичи

- Код в своей зоне, `flutter analyze` 0, unit/widget-тесты зелёные.
- Golden хотя бы для ключевого состояния.
- Нет реальных ПДн/секретов; логи redacted.
- Обработаны loading/empty/error/401.
- Работает на 360 и 390 ширине, font scale 1.3, во всех четырёх темах.
- README фичи: как запустить, какие фикстуры, что не сделано.
- Скриншот/короткое видео экрана в PR.

---

## 9. Тест-план

### 9.1. Уровни

| Уровень | Что | Инструмент |
|---|---|---|
| Unit | codec, маппинг, приватность, время, пагинация, пакеты, темы | `flutter_test` |
| Widget | карточки, фильтры, empty/error, «один Scrollable», диалог тем, FAB clamp | `flutter_test`, `matchesGoldenFile` |
| Golden | 4 варианта карточек, 4 темы, экраны, 360/390/412, font 1.3 | `matchesGoldenFile` |
| Integration | login → home → schedule → theme dialog → tabs → logout на mock-server | `integration_test`, Dio mock |
| Manual | Нативный вход, QR, отмена, темы, FAB drag, Android 15, TalkBack | чек-лист |
| Live smoke | реальный контур, тестовый клиент, env-креды | ручной, не в CI |

### 9.2. Ключевые проверки

- **Приватность:** в дереве виджетов чужого «индив» нет `client.lastName`, `teacher`, `deposit`; в логах нет телефона/secret.
- **Полная высота:** 30 занятий, последний элемент доступен, `find.byType(Scrollable)` = 1 на главной.
- **Своё «индив»:** имя клиента и преподаватель отображаются, если `teacher != null`; без преподавателя — не падает.
- **Заморозка:** у «Профи» кнопка есть и открывает сценарий; у «Стандарт» кнопки нет, только пояснение; `freezeAvailable` считается по пакету дней, а не по глобальному флагу.
- **Chrome-профиль L2:** `User-Agent` содержит major установленного Chrome (`PackageManager`), без `wv`; при отсутствии Chrome — major WebView, затем `defaultChromeMajor`; `<queries>` не ломает видимость; `Origin`/`Referer`/`Sec-Fetch`/`Sec-CH-UA*`/`Priority` точные; `Accept-Language` из локалей; cookie-less.
- **Сжатие:** ответы с `Content-Encoding: gzip`, `deflate`, `br`, `zstd` декодируются; при неизвестном кодировании — понятная ошибка, не «битый JSON».
- **Время:** 19.11.2026 00:00 UTC+7 → правильный день; переход через полночь/границу месяца.
- **Пагинация:** нет дублей на стыке страниц, `hasMore` корректен.
- **Сессия:** 401 → auth; logout → нет secret в storage; повторный вход.
- **Темы:** каждая из четырёх применяется сразу, сохраняется после перезапуска; в розовой расписание розовое, в тёмной — тёмное; контраст текста проверен.
- **FAB:** после любых drag-делт круг целиком в safe area (включая правый/нижний край); тап не срабатывает после drag; позиция восстанавливается; TalkBack-действие доступно.
- **Android 15:** edge-to-edge, inset, predictive back, 16 KB page size, themed icon.

### 9.3. Ручной чек-лист (сокращённо)

1. Чистая установка → splash → вход.
2. Неверный пароль → сообщение; восстановление → страница вендора.
3. Успешный вход → главная, **два абонемента**: «Профи» с заморозкой, «Стандарт» без.
4. Заморозка: кнопка только у «Профи»; у «Стандарт» пояснение; клик по «Стандарт» не запускает заморозку.
5. Прокрутка главной до конца: последнее занятие видно, внутреннего скролла нет.
6. Посещения: 89, подгрузка, пусто/ошибка.
7. Покупки: месяцы, суммы, подгрузка.
8. Записи: аренда, отмена/fallback.
9. QR: читается сканером, скриншот запрещён.
10. Меню ⋮ → диалог четырёх тем; переключение и сохранение после перезапуска.
11. FAB: тап обновляет, drag двигает, за край не уходит.
12. Выход → вход; перезапуск → сессия.
13. Офлайн → кэш/плашка; 401 → auth.
14. TalkBack, font scale 1.3, 360 px.

---

## 10. Релизный чек-лист (Android 15)

- [ ] `targetSdk 35`, `minSdk 35`, `compileSdk 36`; 16 KB page size проверен.
- [ ] Edge-to-edge, insets, predictive back, portrait.
- [ ] Adaptive icon (foreground/background/monochrome), splash.
- [ ] `android:allowBackup="false"`, `usesCleartextTraffic=false`, network security config.
- [ ] `FLAG_SECURE` в release; пароль не в логах; домен API allowlist.
- [ ] FLAG_SECURE на auth/QR.
- [ ] Четыре темы проверены на контраст; «Оплатить» отсутствует; «Заморозить» только у абонемента с днями заморозки.
- [ ] R8/obfuscate, split debug info, mapping сохранён.
- [ ] AAB подписан, versionCode/versionName, internal track.
- [ ] Privacy policy URL, Data Safety, 152-ФЗ, согласия.
- [ ] Нет секретов/ПДн в репозитории и логах.
- [ ] Crash/ANR: базовый мониторинг (Sentry/Firebase — по решению).
- [ ] Инструкция поддержки: сменился пароль/secret, вход не работает.

---

## 11. Риски и меры

| Риск | Вероятность | Влияние | Мера |
|---|---|---|---|
| Вендор меняет внутренний API | средняя | высокий | контрактные тесты на фикстурах, мониторинг 500, ручной smoke |
| `localStorage` ключи меняются | средняя | высокий | fallback-перехват `search`, таймаут, ручной сценарий |
| `secret` — не секрет | высокая | высокий | честно проговорить; Keystore; не логировать; BFF не будет — остаточный риск |
| ПДн в публичном расписании | высокая | высокий | скрывать чужие «индив»/аренду; не кэшировать имена |
| 500 у `visits` без сортировки | высокая | средний | обязательный `sort.visit_date`, тест |
| Заморозка/отмена не подтверждены | средняя | средний | этап 8, fallback в WebView |
| Brotli/Zstd-декодеры в Flutter | средняя | средний | spike в Foundation; при отсутствии надёжного — стоп и доклад, не молчаливый откат L2 |
| FAB выходит за край/перекрывает навигацию | средняя | средний | clamp-тест по всем дельтам; safe area + nav inset |
| Темы ломают контраст/вёрстку | средняя | средний | golden всех четырёх тем, контраст-чек |
| Android 15 edge-to-edge/16 KB | средняя | средний | ранняя проверка в Foundation/QA |
| App Store 4.2 (обёртка сайта) | средняя | средний | нативный UI и функции, не только WebView |
| 152-ФЗ/оператор ПДн | средняя | высокий | политика, согласия, договор с клубом |
| Часовой пояс/переходы дат | низкая | средний | BranchClock + тесты границ |
| Несколько клиентов на телефон | низкая | средний | экран выбора/ошибка, этап 8 |

---

## 12. Открытые вопросы к владельцу продукта

1. Команда продолжать (дизайн уже утверждён).
2. Кто оператор ПДн и где лежит политика конфиденциальности?
3. Есть ли у клуба свой домен/брендирование для приложения?
4. Нужны ли push-уведомления в MVP?
5. Есть ли доступ к тестовому клиенту для CI/ручных прогонов (не в репозитории)?
6. Согласен ли вендор на использование внутренних методов `widget_*`?
7. Подтвердить, что у «Стандарт» заморозка не предусмотрена тарифом; если нужна — включить в CRM, приложение подхватит `freezeAvailable`.

---

## 13. Итог

- Решения D1–D16 приняты; дизайн обновлён под них; код не начат.
- План даёт **5 параллельных фич** после 3 дней foundation и **5 дней интеграции**; ориентир — ~14–16 рабочих дней до RC.
- Самые рискованные места — auth-хендофф, приватность расписания и FAB-границы; все вынесены в отдельные этапы с тестами.
- После команды продолжать можно запускать этап 1 и параллельные сессии субагентов по промптам §7.

