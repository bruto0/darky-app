# D'arky — мобильное приложение клиента D'arky Dance

**Статус:** Foundation, Auth и MVP-разделы готовы: профиль/абонементы, расписание, посещения, покупки, записи. Вход нативный (D15), восстановление — в браузере (D16). Проверено на **AVD API 37** с живым API (тестовый клиент): 4 таба, два абонемента, заморозка «Профи», 20 занятий дня, 90 посещений, 9 операций, 1 запись, QR-баркод. 181 тест, debug APK.

| Что | Где |
|---|---|
| Код приложения | [app/](app/) · [app/README.md](app/README.md) |
| Эскизы 2×, иконка, борд | [design/README.md](design/README.md) |
| Дизайн, темы, FAB, маппинг данных, auth | [design/DESIGN.md](design/DESIGN.md) |
| WebView: скорость, вид, autofill, ограничения | [design/WEBVIEW-NOTES.md](design/WEBVIEW-NOTES.md) |
| Проверенные факты живого кабинета | [design/LIVE-FINDINGS.md](design/LIVE-FINDINGS.md) |
| Этапы, параллельная работа субагентов, промпты | [PLAN.md](PLAN.md) |
| Окружение сборки (JDK 21, Android SDK, Flutter) | [BUILD-ENV.md](BUILD-ENV.md) |
| Локальный Git-сервер и синхронизация | [GIT-SERVER.md](GIT-SERVER.md) |
| Принятые решения | [design/APPROVAL.md](design/APPROVAL.md) |
| Документация API и авторизации | [docs/](docs/) |

## Быстрый просмотр

![Эскизы D'arky](design/board.png)

Борд — исторические эскизы; актуальный экран входа — нативный,
[design/mockups/01-auth.png](design/mockups/01-auth.png).

## Что предлагается

- **Flutter**, Android 15+ (minSdk 35), архитектура готова к iOS.
- **Нативный вход** (D15): телефон и пароль в Flutter-полях, `AutofillGroup`, запросы `phone_info` → `check_password` → `search`; после входа приложение забирает `client_id` и `secret`. Пароль не хранится и не логируется.
- **Восстановление пароля** (D16): ссылка открывает `/widget/2` во внешнем браузере; восстановление — модалка вендора (Telegram / MAX / звонок).
- **4 раздела:** Абонемент (профиль + абонементы + расписание), Посещения, Покупки, Записи.
- **Профиль и абонементы:** два реальных абонемента, счётчики пакетов, QR, выход, меню `⋮` справа от выхода. «Заморозить» — full width только у «Профи» (21/21 день), у «Стандарт» — пояснение; «Оплатить» отсутствует.
- **4 темы** — Светлая, Тёмная, Розовая, Системная; выбор в диалоге из меню `⋮` справа от выхода. Фон расписания следует теме.
- **Расписание без вложенного скролла:** весь день выкладывается в общий скролл экрана.
- **FAB обновления:** круглая кнопка в правом нижнем углу; перетаскивается, но всегда целиком остаётся в safe area.
- **Индивидуальные занятия (`type = 1`):** чужое — только «индив» и зал; своё — имя клиента и преподаватель (если есть).
- **Приватность:** чужие ФИО, депозиты и преподаватели не показываются и не логируются.
- **Без оплаты:** кнопка «Оплатить» убрана. «Заморозить» — full width в карточке «Профи», где она доступна; у «Стандарт» заморозки нет — пояснение. BFF не планируется.
- **HTTP (L2):** нативный клиент мимикрирует под мобильный Chrome, **версия — с телефона** (Chrome → WebView → default): UA, `Accept`, device `Accept-Language`, `Origin`/`Referer`, `Sec-Fetch-*`, low-entropy `Sec-CH-UA*`, `Priority`, `gzip/deflate/br/zstd`; cookie-less. API это не требует, но так решено.
- **Иконка:** жирная `D` сине-фиолетовым градиентом на чёрном фоне; adaptive + monochrome, 2048/1024.

## Код: Foundation + Auth + MVP-разделы

```powershell
. .\tools\env.ps1
cd app
flutter analyze   # 0 issues
flutter test      # 181 test
flutter build apk --debug
```

Готово: 4 темы с сохранением, 4 таба, `ApiClient` с L2-профилем и Brotli/Zstd, `ChromeVersionProvider` + `<queries>`, `SessionStore`, `BranchClock`, `JsonCache`, логирование с redaction, контракты/fakes, фикстуры, иконка/adaptive/splash. Auth: нативные поля, `phone_info`/`check_password`, `widget_client_lk/search`, сессия в Keystore. Данные: `widget_client_lk/accounts`, `widget_schedule/list` + stickers/changes, `visits`, `deposits`, `widget_client_lk/schedule`, `barcode`; UI-разделы и тесты расписания/истории/записей/аккаунта. Проверено на AVD API 37 с живым API.

`compileSdk 36` (требование `flutter_secure_storage`/`shared_preferences_android`), `minSdk/targetSdk 35`; WebView из auth удалён. Все ограничения и варианты кастомизации WebView — в [design/WEBVIEW-NOTES.md](design/WEBVIEW-NOTES.md).

## Проверено на живом кабинете

У клиента **два активных абонемента**: «Профи» (19/24 на момент проверки; 21/21 день заморозки — кнопка доступна) и «Стандарт» (3/5; заморозка недоступна). Живые данные: 20 занятий дня, 90 посещений, 9 операций, 1 запись, QR-баркод. Подробности — [design/LIVE-FINDINGS.md §3](design/LIVE-FINDINGS.md#3-абонементы-и-заморозка-перепроверено-19112026).

## Что принято

Решения D1–D16 зафиксированы в [DESIGN.md §10](design/DESIGN.md) и [APPROVAL.md](design/APPROVAL.md).

Дизайн утверждён, Foundation и Auth проверены. Дальше — расписание, абонементы, история, записи.
