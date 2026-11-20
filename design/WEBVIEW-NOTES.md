# WebView: что выяснено и что с ним можно сделать

Дата: 19–20.11.2026. Контур: `https://4621c03198bd6735334088.impulsemini.ru/widget/2`.
Документ фиксирует всё, что известно о вендорском login-WebView, его виде,
производительности и автозаполнении. После решения **D15** авторизация
переведена на нативный логин; WebView из auth убран. Эти знания остаются для
будущих web-сценариев (заморозка/оплата/QR), если они понадобятся.

## 1. Что это за страница

- SPA «impulse CRM» на Vue: HTML ~94 КБ, десятки/сотни JS- и CSS-чанков,
  `vk.bridge.min.js`, service worker, prefetch-ссылки.
- Первый рендер на реальном HONOR BVL-AN16 — несколько секунд; на эмуляторе
  (WebView 124/145, software/host GPU) — десятки секунд, вплоть до ANR
  System UI. Причина — не сеть, а объём JS и инициализация VK Bridge.
- Страница рассчитана на VK Mini App и мобильный WebView. В обычном desktop
  Chrome 156 она открывается и показывает форму входа.

## 2. User-Agent и VK-ветка

| UA | Поведение |
|---|---|
| Мобильный Android Chrome (`Android 10; K`, Chrome 124/156) | VK Bridge включает «мобильное приложение» и страница зависает на «загрузка»; форма не появляется |
| Desktop Chrome той же major | Открывается обычный веб-вход; форма появляется |
| Desktop UA + мобильный UA-CH (`Android WebView`) | Может зависнуть: JS видит несоответствие UA и Client Hints |
| Desktop UA + desktop UA-CH (инъекция) | Обычно страница грузится, но остаётся тяжёлой |

Вывод: для WebView приходилось подменять UA на desktop и, в идеале, spoof
`navigator.userAgentData`. `webview_flutter` не даёт document-start scripts;
инъекция после `onPageFinished` не гарантирует, что VK Bridge уже не выполнился.

## 3. Скорость и стабильность

- На эмуляторе страница может не дойти до формы за 3 минуты; таймаут polling
  3 минуты в старой auth-реализации срабатывал раньше, чем появлялся пароль.
- На реальном телефоне страница грузится, но всё равно тяжело: первый кадр
  WebView + сеть + VK Bridge.
- Кэш/service worker не гарантируют ускорения: при `pm clear`/первом запуске
  всё скачивается заново; vendor-чанки не наши, предзагрузка ограничена.
- Для логина это плохой UX. Нативный экран (D15) решает проблему радикально:
  два поля и один HTTPS-запрос вместо SPA.

## 4. Как приводили вид к желаемому

Что реально работает в `webview_flutter`:

- **Full-bleed**: убрать `ClipRRect`/карточку/`Container` вокруг `WebViewWidget`,
  оставить `Positioned.fill`.
- **Убрать браузерную строку**: не рисовать свой `Container` с замком, доменом
  и refresh; это был наш UI, а не страница.
- **Скрыть заголовок/рамку модалки вендора**: CSS-инъекция после загрузки:
  - `.modal-title`, `.dialog-title`, заголовки в `.modal-header` — `display:none`;
  - `.modal-header > :not(button):not(.close)` — скрыть текст, оставить крестик;
  - `.modal-content` — `border:0`, `box-shadow:none`, `border-radius:0`;
  - `.modal`, `.modal-dialog` — `width:100%`, `margin:0`, `max-width:100%`;
  - `.modal` — фон темы, чтобы не просвечивала страница согласий.
- **Тема**: CSS-переменные из `AppPalette` (`bg`, `surface`, `ink`, `ink2`,
  `muted`, `line`, `pinkDeep/pink`), стили `.btn-primary`,
  `.btn-outline-primary`, `.modal .btn`, `input`, `textarea`, `select`,
  `::placeholder`, `accent-color` для чекбоксов, `.btn-link`/`.gray-link` —
  прозрачные ссылки.
- **SPA re-render**: `MutationObserver` + периодический `setInterval` для
  повторной установки атрибутов; CSS применяется к новым узлам сам.
- **Ограничения CSS**: вендорские `!important` и специфичность
  (`.modal button:not(...)`), анимации `fade` (нужно ждать), разные классы
  (`modal-sm`, `modal-xl`, `modal-autowidth`), тени/фон backdrop. Полного
  контроля над внутренними состояниями Vue нет.
- **Что нельзя убрать**: нативные scrollbars/selection/context menu WebView,
  поведение клавиатуры, JS-ошибки вендора, VK Bridge, белый flash первого
  кадра, анимации модалки. Можно скрыть только DOM/CSS-слои.

## 5. Автозаполнение

Проверено на HONOR (Android 17, Google Autofill service включён):

- HTML `autocomplete="username"` на телефоне и `current-password` на пароле
  ставились; поле телефона иногда подставлялось, пароль — нестабильно.
- Поля вендора изначально **без `<form>`**, с `autocomplete=off`; добавляли
  скрытую форму и `form`-атрибуты — это улучшает распознавание, но не
  гарантирует подсказку.
- `AutofillManager.requestAutofill(WebView)` через native + отражение
  (`WebViewFlutterAndroidExternalApi`) можно вызвать, но:
  - нельзя гарантировать, что WebView отдаст `ViewStructure` с полями;
  - пароли сайта в Google Password Manager могут не предлагаться нативному
  приложению без Digital Asset Links (`assetlinks.json` на домене вендора);
  - подсказка зависит от клавиатуры/HONOR/Google и сохранённого credential.
- Native fallback: `AutofillGroup` + два `TextField` с `AutofillHints`
  (`username`, `password`) надёжнее показывает системный менеджер, но это уже
  не «автозаполнение внутри WebView».
- Итог: **стабильного автозаполнения именно в вендорском WebView получить не
  удалось**. Для нативного логина (D15) используем обычные Flutter-поля с
  `AutofillHints`; после успешного входа вызываем
  `TextInput.finishAutofillContext(shouldSave: true)`, чтобы Android предложил
  сохранить credential для приложения.

## 6. Что можно сделать, если WebView всё же нужен

1. **Chrome Custom Tabs** для входа: настоящий Chrome, нормальный autofill,
   но нельзя прочитать `localStorage`/`client_id`/`secret`; нужен deep link
   или серверный callback, которых у вендора нет.
2. **Нативный WebView + собственный document-start JS** (нужен плагин/патч,
   например `flutter_inappwebview` с `UserScript`): можно spoof UA-CH, скрыть
   рамку, поставить autofill-атрибуты до выполнения VK Bridge. Требует
   поддержки AGP 9 и сопровождения форка.
3. **Cronet/Chromium network stack**: ускорит сеть, но не уберёт SPA/VK Bridge
   и не даст document-start CSS.
4. **Свой BFF**: серверный логин и API, приложение не видит пароль; но BFF
   запрещён решением D10.
5. **Нативный логин (D15)** — выбранный путь: быстро, стабильно, autofill
   стандартный, пароль не хранится.

## 7. Нативный логин: контракт

Проверено на живом API (тестовый клиент):

1. `POST /api/public/widget_schedule/phone_info` `{phone: encoded}` →
   `{count, ids, hasPassword}`.
2. `POST /api/public/widget_schedule/check_password`
   `{phone: encoded, password}` → `{success: true}`.
3. `POST /api/public/widget_client_lk/search`
   `{phone: encoded, socialPage: null}` → `{total, items:[client]}`;
   `client_id`/`secret` в `items[0]`.
4. `secret` — Keystore/Keychain; пароль не сохраняется, не логируется,
   очищается после запроса; `FLAG_SECURE` в release.

## 8. Восстановление пароля

Отдельного URL у вендора нет: «восстановить пароль» открывает **модалку**
внутри `/widget/2` с вариантами «Через Telegram», «Через MAX», «Входящим
звонком». Поэтому кнопка в приложении открывает
`https://4621c03198bd6735334088.impulsemini.ru/widget/2` во внешнем браузере;
дальше пользователь нажимает «восстановить пароль» и выбирает способ.
Если вендор даст прямой recovery-URL, его нужно вынести в `AppConfig`.

## 9. Тесты

- AVD `Medium_Phone_API_37.0`: нативный вход тестовым клиентом → home;
  feature-прогон (2 абонемента, 20 занятий, 90 посещений, 9 операций, 1 запись,
  QR/баркод) — успешно; recovery-ссылка открывает внешний Chrome.
- HONOR BVL-AN16 (Android 17): проверялся старый WebView-вход (работал, но
  медленно); нативный экран и recovery на нём ещё не перепроверялись — по
  указанию дальше тестируем на AVD.
- `flutter analyze` — 0; `flutter test` — **187 тестов**.
