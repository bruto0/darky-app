# Живые находки: клиентский кабинет D'arky

Дата проверки: **19–20.11.2026**, контур `https://4621c03198bd6735334088.impulsemini.ru`, виджет 2.
Всё ниже получено на тестовом клиенте. **Пароль, телефон, `client_id`, `secret` и ФИО в документ не переносятся** — только структуры и правила.

## 1. Вход в виджет (что реально происходит)

Страница `/widget/2`:

1. Приветствие: кнопка «Войти в личный кабинет» и два обязательных согласия (политика ПДн, оферта).
2. Модалка «Вход в систему»: телефон с маской `+7 (___) ___ ____`, кнопка «Войти».
3. После телефона появляется поле пароля, кнопка «Продолжить» и ссылка «восстановить пароль».
4. После успешного входа в `localStorage` появляются:
   - `impulsecrm_active` = base64 от JSON-строки телефона;
   - `impulsecrm_verified` = base64 от JSON-массива телефонов.
   До входа оба ключа отсутствуют.
5. Сеть: `widget_schedule/phone_info` → `widget_schedule/check_password` → `widget_client_lk/search` (ответ `{total, items:[client]}`; профиль и `secret` в `items[0]`).

**Вывод для приложения (актуально, D15):** те же три запроса можно вызвать
нативно, без WebView. Приложение получает телефон и пароль в нативных полях,
вызывает `phone_info` → `check_password` → `widget_client_lk/search`, декодирует
ответ и забирает `items[0].id` + `items[0].secret`. Пароль не сохраняется и не
логируется. WebView-путь (localStorage) оставлен здесь как история и для будущих
web-сценариев; в auth он больше не используется.

### 1.2. Нативный вход и восстановление (проверено 20.11.2026)

- `POST /api/public/widget_schedule/phone_info` `{phone: encoded}` →
  `{count, ids, hasPassword}`. `count=0` — телефона нет; `hasPassword=0` —
  пароль не задан.
- `POST /api/public/widget_schedule/check_password`
  `{phone: encoded, password}` → `{success: true}`; неверный пароль —
  `success: false`.
- `POST /api/public/widget_client_lk/search` — как выше, `items[0]`.
- Восстановление: отдельного URL нет; кнопка «восстановить пароль» в `/widget/2`
  открывает модалку «Как подтвердить номер телефона?» с вариантами
  Telegram / MAX / входящий звонок. Приложение открывает `/widget/2` во внешнем
  браузере.
- Проверено на AVD API 35: нативный вход тестовым клиентом → home; ссылка
  восстановления открывает Chrome. Пароль/телефон/секрет в документ не
  переносятся.

### 1.3. Нативный data-layer и экраны (проверено 20.11.2026)

Тот же тестовый клиент, нативный вход, запросы через `WidgetLkRepository`:

- `accounts` — 2 абонемента; «Профи» с packet `days=21` → `freezeAvailable=true`,
  «Стандарт» → `false`;
- `widget_schedule/list` на 19.11.2026 — 20 занятий, типы 0/1/2, фильтры
  зал/преподаватель; `stickers`/`changes` отдают `{total, items}`;
- `visits` — 90 записей, `sort.visit_date` обязателен; `target.style.name`
  и `service.number` — реальные поля;
- `deposits` — 9 операций, `sum`/`sumWithSign`/`typeText`/`target.number`;
- `widget_client_lk/schedule` — 1 аренда (23 ноября, 19:00–20:00);
- `barcode` — 391 байт PNG (raw/JSON envelope).
- На AVD API 37 проверены 4 таба, карточки, заморозка, расписание, история,
  покупки и записи; на AVD API 35 сеть/System UI нестабильны (эмулятор), не
  код приложения.

### 1.1. HTTP-идентификаторы (проверено)

`widget_client_lk/accounts` принимает запросы **без User-Agent, без Referer/Origin, без cookies** — `200`, те же 2 абонемента. Проверены варианты: native-UA, Chrome-UA + `Origin`/`Referer` + `Sec-Fetch-*`, только `Content-Type`, совсем без UA. Все — `200`, то есть вендор не требует браузерных заголовков.

Продуктовое решение — **мимикрия под мобильный Chrome, уровень L2**. Профиль заголовков снят с живой сессии Chrome 156 mobile; версия в UA **динамическая**: major берётся из установленного Chrome на телефоне (`156.0.8078.80` → `156`), fallback — версия системного WebView, затем `defaultChromeMajor`. Пример для Chrome 156:

- `User-Agent: Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Mobile Safari/537.36`
- `Accept: application/json, text/plain, */*`, `Content-Type: application/json`
- `Accept-Language` из локалей устройства, например `ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7`
- `Referer: https://<tenant>/widget/2`, `Origin: https://<tenant>`
- `Sec-Fetch-Site: same-origin`, `Sec-Fetch-Mode: cors`, `Sec-Fetch-Dest: empty`
- `Sec-CH-UA: "Not:A-Brand";v="8", "Chromium";v="156", "Google Chrome";v="156"`, `Sec-CH-UA-Mobile: ?1`, `Sec-CH-UA-Platform: "Android"`
- `Priority: u=1, i`, `Accept-Encoding: gzip, deflate, br, zstd`
- cookie в снятом запросе не было; `X-Requested-With` не было. `Sec-CH-UA*` в CDP-снимке отсутствовали из-за подмены UA; в L2 они добавляются как low-entropy hints.

Точный набор и ограничения (TLS-отпечаток остаётся нативным) — [DESIGN.md §5.9](DESIGN.md#59-http-клиент-профиль-мобильного-chrome).

## 2. Вкладки кабинета (что внутри)

| Вкладка | Что показывает | Метод API |
|---|---|---|
| Абонемент | профиль, бонусы, карточка абонемента, счётчики, срок, «Оплатить»/«Заморозить», встроенное расписание | `accounts`, `client_summary`, `widget_schedule/list` |
| Посещения | история визитов: дата, занятие, преподаватели, филиал, абонемент/разовое | `widget_client_lk/visits` |
| Покупки | оплаты и пополнения по датам, суммы зелёным | `widget_client_lk/deposits` |
| Записи | свои занятия/аренды, дата, время, зал, «Отменить запись» | `widget_client_lk/schedule` |

Важно: вкладка «Записи» — это **не** `widget_client_lk/reservations` (там было 0), а персональное расписание `widget_client_lk/schedule`. У тестового клиента в нём одна запись — аренда зала.

## 3. Абонементы и заморозка (перепроверено 19.11.2026)

`widget_client_lk/accounts` (в том числе с `closedAccountsShown:true`) → **два активных абонемента, закрытых нет**:

| Абонемент | Остаток | Срок | Заморозка |
|---|---|---|---|
| «Профи» (`groupAccount`) | 20 / 24 занятий | 7 февраля 2027 | **доступна**: 21 / 21 день, пакет `{value:5, days:21, min:"1"}`; кнопка «Заморозить» открывает период «от 1 дня» |
| «Стандарт» (`individualAccount`) | 3 / 5 занятий | 2 декабря | **недоступна**: `packets: []`, нет дней заморозки; в карточке веба нет строки заморозки, в модалке абонемента нет действия |

В вебе кнопка «Заморозить» **одна на весь кабинет** и стоит после карточек; в модалке периода нет выбора абонемента. По данным и карточкам видно, что заморозка относится только к «Профи». Поэтому в приложении действие делаем **per-account**: кнопка только в карточке, где есть дни заморозки; у «Стандарт» — пояснение без кнопки. Это осознанное отклонение от веба, чтобы не заморозить не тот абонемент.

Поля: `typeName`, `entity` (`groupAccount`/`individualAccount`), `trainingsLeft/Total`, `endDate`, `active`, `freeze`, `freezeDays`, `packets[]` (`{value, count, used, type, days, min}`), `typeColor`.


## 4. Расписание

### 4.1. Запрос дня

`POST widget_schedule/list`:

```json
{
  "branch_id": 1,
  "range": {"from": 1795046400, "to": 1795046400},
  "filters": {
    "branch_id": 1, "groups": true, "individuals": true, "rents": true,
    "hall_id": null, "style_id": null, "teacher_id": null, "age": null, "scale": "day"
  }
}
```

При `from == to` (начало дня) API отдаёт занятия **этого дня**, включая регулярные. За день 19.11.2026 получено 20 записей: 5 групп, 8 индивидуальных, 7 аренд. При диапазоне 14 дней — 95 записей, типы 0/1/2 = 35/42/18. Для экрана дня используем запрос на день.

### 4.2. Поля записи

`id`, `type` (0 группа / 1 индив / 2 аренда), `typeTitle`, `minutesBegin`, `minutesEnd`, `color`, `day`, `date`, `dateBegin`, `dateEnd`, `regular`, `hall`, `group`, `style`, `teacher`, `teacher1`, `teacher2`, `client`, `note`, `payment`, `wage`.

Для индивидуального занятия:

```json
{
  "type": 1, "minutesBegin": 960, "minutesEnd": 1020,
  "hall": {"name": "Средний"},
  "teacher": {"id": 13, "lastName": "Чистяков", "name": "Андрей", "middleName": null},
  "client": {"id": 104, "lastName": "...", "name": "...", "middleName": "..."},
  "style": {"name": "Бачата"}, "group": null
}
```

Отдельного `client_id` нет — только `client.id`. Для своего занятия сравниваем `item.client.id` с `session.clientId`.

### 4.3. Встроенный виджет расписания

Веб монтирует iframe `/widget/4` с конфигом:

- `groupEnable: true`, `individualEnable: false`, `rentEnable: true` — **индивидуальные в вебе выключены**;
- `showFilterHall: true`, `showFilterTeacher: true`, `showScaleButton: true`, `showSubstitute: true`;
- `backgroundColor: "c27ba0"` — розовый фон блока;
- `showHeader: true`, `showCancel: true`, `showTransfer: true`.

Отсюда требование задачи: в приложении включить `individuals: true` и показать тип 1 по правилу приватности.

### 4.4. Стикеры и замены

- `widget_schedule/stickers` → массив стикеров с `schedule.id`, `name`, `color`; в вебе «САМПО» жёлтый и «ИНДИВ» фиолетовый.
- `widget_schedule/changes` → замены преподавателей; в вебе строка «Замена Семьянов В. С.» красным.
- В карточке дня стикеры и замены лучше запрашивать параллельно с расписанием; ошибка этих методов не должна ломать список.

## 5. Посещения

`widget_client_lk/visits` с телом:

```json
{
  "limit": 10, "page": 1,
  "sort": {"visit_date": "desc", "created": "desc"},
  "filters": {"client_id": 0, "secret": "..."}
}
```

**Без `sort.visit_date` метод отвечает 500** (`Attempted to call an undefined method "isdate"`). Это важно: в приложении сортировка обязательна. Запись содержит `visitDate`, `target` (группа/стиль/преподаватели), `service` (номер абонемента), `byAccount`, `branch`, `minutesBegin/End`, `duration`.

## 6. Покупки

`widget_client_lk/deposits`:

```json
{
  "limit": 10, "page": 1, "sort": {"created": "desc"},
  "filters": {"client_id": 0, "type": [11, 12, 13], "secret": "..."}
}
```

Поля: `typeText` («оплата группового абонемента», «пополнение счета»), `sum`, `sumWithSign`, `paymentText`, `created`, `target.number` (номер абонемента).

## 7. Записи

`widget_client_lk/schedule`:

```json
{
  "filters": {"client_id": 0, "secret": "..."},
  "sort": {"regular": "desc", "dateBegin": "desc", "date": "desc", "minutesBegin": "desc"}
}
```

У тестового клиента — одна аренда: зал «Средний», филиал «Главный», 19:00–20:00, 23 ноября (понедельник), тип 2. В вебе карточка показывает зал, филиал, время, дату и кнопку «Отменить запись». Метод отмены (`unsubscribe`) в руки не брали, чтобы не менять данные; payload нужно снять с бандла/тестового занятия на этапе 6.

## 8. Профиль и QR

- Профиль: `widget_client_lk/search` (ФИО, `branch`, `fotoThumbUrl`, `bonus`, `secret`).
- Бонусы: `widget_client_lk/client_summary` → `{hasBonusItem}`.
- Штрихкод: `widget_client_lk/barcode` с `{client_id, secret, type:2, seconds:5}` → PNG в base64.
- Новости/сторис в тестовом тенанте пустые; в MVP не выводим.

## 9. Безопасность (кратко)

- `widget_client_lk/search` отдаёт `secret` по одному телефону, без пароля. Пароль в схеме декоративный.
- В ответе `search` приходит bcrypt-хеш пароля — приложение не должно его сохранять, логировать или показывать.
- Публичное расписание отдаёт ФИО/депозиты клиентов в индивидуальных занятиях и аренде. Приложение обязано скрывать чужие данные (правило §5.3 дизайна).
- BFF **не планируется** (решение D10). Остаточный риск `secret` фиксируем письменно для владельца клуба; компенсации в MVP — WebView + Keystore + запрет логов и скриншотов чувствительных экранов.

## 10. Что ещё проверить перед реализацией

1. Точный payload отмены записи (`unsubscribe`) и правила отмены для аренды/индивидуальных.
2. Формат `widget_schedule/places` (свободные места) — нужен только для записи, не для MVP.
3. Семантика нескольких клиентов на один телефон (`ids` в `phone_info`).
4. TTL `secret` и поведение при смене пароля.
5. Нужен ли `Referer`/`Origin` для запросов из нативного клиента.
6. Есть ли официальный мобильный контур у вендора (`widget_client_mobile/*`).
