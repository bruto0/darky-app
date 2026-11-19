# Архитектура Android-приложения

Документ отвечает на вопрос «как строить приложение дальше», опираясь на факты из
[findings.json](findings.json). Контур: тенант impulseCRM, `https://<tenant>.impulsemini.ru`.

## 1. Развилка: для кого приложение

| | **Клиентское** (ЛК клуба) | **Сотрудничье** (рабочее место) |
|---|---|---|
| Вход | телефон + пароль клиента, `/widget/2` | телефон + пароль сотрудника, `/login` |
| Токен | `client_id` + `secret` | PHP-сессия (`?PHPSESSID=`) |
| Данные | свои абонементы, посещения, депозиты, расписание | клиенты, расписание, продажи, отчёты |
| API | `widget_client_lk/*`, `widget_client_mobile/*`, `widget_schedule/*` | документированный `/api/public/<entity>/*` + `?PHPSESSID=` |
| Периметр | недокументированный | частично документированный |

Дальше всё описано для **клиентского** приложения (по данным задачи это оно), отличия для
сотрудничьего — в [android-auth.md](android-auth.md) и в §7.

## 2. Чего делать нельзя

1. **Класть в APK API-ключ клиента** — он даёт доступ ко всей CRM и извлекается из apk.
2. **Класть в APK клиентский `secret`** — он выдаётся по одному телефону
   (`widget_client_lk/search`), то есть любой, кто знает номер, получит доступ к ЛК.
3. **Хранить пароль на устройстве** «чтобы не логиниться».
4. **Доверять клиентской проверке пароля** — `check_password` возвращает `{success}`, но
   данные всё равно отдаются по `secret`, который можно получить без пароля.
5. **Парсить HTML страницы** — это SPA, HTML пустой.

## 3. Целевая схема: BFF

```
┌──────────────┐   HTTPS + JWT    ┌──────────────┐   client_id+secret   ┌──────────────┐
│ Android app  │ ───────────────► │  Ваш BFF     │ ───────────────────► │ impulseCRM   │
│ (Kotlin)     │ ◄─────────────── │ (любой язык) │ ◄─────────────────── │ widget API   │
└──────────────┘                  └──────────────┘                      └──────────────┘
        │                                 │
        └── EncryptedSharedPreferences    └── Redis: client_id+secret по сессии
```

**Что делает BFF:**

1. `POST /auth/login {phone, password}` — вызывает `widget_schedule/check_password`;
   при успехе берёт `secret` (`widget_client_lk/search`) и кладёт в Redis по своему
   session-id; приложению отдаёт короткоживущий access-JWT + refresh.
2. `GET /schedule?from&to` — проксирует `widget_schedule/list` (он публичный, можно
   кэшировать).
3. `GET /me/accounts`, `/me/visits`, ... — проксирует `widget_client_lk/*`, подставляя
   `client_id`/`secret` из сессии.
4. `POST /auth/refresh`, `POST /auth/logout` — ротация и отзыв.

**Почему так:** `secret` и пароль не попадают на устройство; можно добавить SMS-код,
лимиты попыток, аудит, кэш, скрыть ПДн других клиентов из публичного расписания; при
изменении внутреннего API правится только сервер.

**MVP без BFF:** WebView с `/widget/2` — быстро, безопаснее нативного «secret в APK»,
но UX хуже. См. §5.

## 4. Модульная структура (Gradle)

```
:app
:core:design        — тема, компоненты
:core:network       — OkHttp/Retrofit, интерсепторы, сериализация
:core:auth          — AuthRepository, TokenStore, Authenticator
:core:storage       — EncryptedSharedPreferences, Keystore
:feature:auth       — экран входа (телефон → пароль / SMS)
:feature:schedule   — сетка занятий (публичный метод)
:feature:profile    — абонементы, посещения, депозиты
:feature:payments   — оплата/продление (если включат вендор)
```

Ключевая абстракция — один интерфейс на все варианты входа:

```kotlin
interface AuthRepository {
    suspend fun login(phone: String, password: String): Session
    suspend fun loginWithSms(phone: String, code: String): Session
    suspend fun refresh(): Session
    suspend fun logout()
}

class Session(val accessToken: String, val expiresAt: Instant, val client: ClientProfile)
```

Реализации: `BffAuthRepository` (прод), `WebViewAuthRepository` (MVP/фолбэк),
`NativeWidgetAuthRepository` (прототип, только для тестов — см. §6).

## 5. MVP: WebView с виджетом

```kotlin
webView.settings.apply {
    javaScriptEnabled = true
    domStorageEnabled = true      // без этого не работает localStorage виджета
    allowFileAccess = false
    allowContentAccess = false
}
webView.webViewClient = object : WebViewClient() {
    override fun shouldOverrideUrlLoading(v: WebView, req: WebResourceRequest): Boolean =
        !req.url.toString().startsWith(baseUrl)           // не выпускать за пределы тенанта
}
webView.loadUrl("$baseUrl/widget/2")
```

Дальше два пути:

- **Всё в WebView** — минимум кода, все функции ЛК работают сразу. Плюс: не храните
  `secret` вообще. Минус: UX и вёрстка вендора.
- **Гибрид** — после входа вытащить состояние (`impulsecrm_active`, `impulsecrm_verified`
  в `localStorage`) и перейти на нативные вызовы. Не рекомендуется: вы всё равно получите
  `secret`, который не является секретом.

## 6. Нативный протокол виджета (для справки и тестов)

Если всё же нужен нативный клиент без BFF, вот точный контракт (проверено):

```kotlin
object WidgetCodec {
    private const val XOR_KEY = "x7K2mQ9pL4"                  // reverse("4Lp9Qm2K7x")
    private const val SPLIT = "2RnZGYNCmdmZGdkZg0KZ2ZkDQpn"   // reverse("pQDkZ2ZK0gZkdGZmdmCNYGZnR2n") rotated

    fun encodePhone(phone: String): String {
        val n = phone.filter { it.isDigit() }.toLong() + 49_680_531
        val b36 = n.toString(36)
        return Base64.encodeToString(b36.reversed().toByteArray(Charsets.US_ASCII), Base64.NO_WRAP)
    }

    fun decode(payload: String): String {                     // ответы авторизации
        val reversed = payload.reversed()
        val xored = reversed.mapIndexed { i, c ->
            (c.code xor XOR_KEY[i % XOR_KEY.length].code).toChar()
        }.joinToString("")
        val parts = xored.split(SPLIT)
        require(parts.size >= 2) { "unexpected payload" }
        return String(Base64.decode((parts[0] + parts[1]).reversed(), Base64.DEFAULT))
    }

    /** Тело запроса — дважды закодированный JSON: снаружи строка, внутри объект. */
    fun body(json: String): String = "\"" + json.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
}
```

Порядок входа:

1. `POST widget_schedule/phone_info` `{phone}` → `{count, ids, hasPassword}`.
2. `POST widget_schedule/check_password` `{phone, password}` → `{success}`.
3. `POST widget_client_lk/search` `{phone, socialPage:null}` → профиль + `client_id` + `secret`.
4. Данные: `POST widget_client_lk/<method>` `{filters:{client_id, secret}}` — **обычный JSON**,
   дешифровать не нужно.

⚠️ Пункт 3 не требует пароля, поэтому такая схема не защищает данные: любой, кто знает
телефон, повторит шаги 3–4. Использовать только для прототипа/тестов.

## 7. Если приложение для сотрудников

- Вход: `POST /api/public/user/login` (`username`/`password`, form-urlencoded) →
  `{success, session}`; далее каждый запрос с `?PHPSESSID=<session>`.
- Проверка сессии: `GET /api/public/user/current` (`401` → на экран входа).
- BFF-вариант: сервер хранит API key и сессию, приложению выдаёт JWT.
- Подробности, код и риски — [android-auth.md](android-auth.md).

## 8. Сеть и хранение

- OkHttp + kotlinx.serialization; один `Interceptor`, добавляющий авторизацию
  (`Authorization: Bearer` для BFF, `PHPSESSID`/`secret` — только в отладочных сборках).
- Таймауты 15–20 с, retry только для идемпотентных GET.
- `EncryptedSharedPreferences` (Jetpack Security) или Keystore; `android:allowBackup="false"`.
- Пароль — не хранить. Для «быстрого входа» — biometric unlock поверх refresh-токена.
- Certificate pinning — по желанию; учитывать ротацию Let's Encrypt.
- Логи: тела запросов авторизации не логировать, `secret` маскировать.

## 9. Тестирование

- `MockWebServer` + фикстуры из [findings.json](findings.json): успешный логин, `403` с
  `message`, таймаут, истёкшая сессия.
- Контрактные тесты BFF ↔ CRM на стенде (отдельный тестовый клиент!).
- UI-тест: истёкший токен → экран входа; смена пароля в вебе → разлогин.

## 10. Порядок работ

1. Выбрать контур (клиент/сотрудник) и вариант (W1/W3 или A/D) — см. §1.
2. Поднять BFF-заглушку с фикстурами, зафиксировать контракт.
3. Экран входа + TokenStore + AuthRepository.
4. Расписание (публичный метод, кэш), профиль, абонементы.
5. Отправка [vendor-report.md](vendor-report.md), запрос официального API у вендора.
6. Закрыть пункты [open-questions.md](open-questions.md).
