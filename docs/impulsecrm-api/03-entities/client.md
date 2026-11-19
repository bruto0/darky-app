# Клиент — сущность `client`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Клиент CRM: контакты, документ, статус в воронке, депозит и бонусы, метки, комментарии, задачи, родители, ответственный пользователь.

> **Проверено на демо-контуре 2026-11-19.** Для создания на демо обязательны `deposit` и `bonus`; `email`, `socialPage`, `address` — массивы строк, не строки; `update` частичный; `delete` логический. Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `client`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/client/load/{id}` | Получить клиента по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/client/list` | Получить список клиентов |
| [Создать](#create) | `POST` | `/api/public/client/update` | Создать клиента |
| [Обновить](#update) | `POST` | `/api/public/client/update` | Обновить клиента |
| [Удалить](#delete) | `POST` | `/api/public/client/delete` | Удалить клиентов |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/client/load/{id}`

_Получить клиента по идентификатору_

Возвращает информацию о клиенте по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор клиента | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `id` | `number` | Идентификатор клиента |
| `entity` | `string` | Тип сущности, для клиента — client |
| `lastName` | `string` | Фамилия |
| `name` | `string` | Имя |
| `middleName` | `string` | Отчество |
| `birthDate` | `number` | Дата рождения (Unix timestamp, UTC) |
| `man` | `boolean` | Пол: true — муж., false — жен. |
| `age` | `number` | Возраст |
| `phone` | `array` | Массив строк с телефонами |
| `email` | `string` | Электронная почта (строка с разделителем) |
| `socialPage` | `string` | Страница соц. сети (строка с разделителем) |
| `address` | `string` | Адрес проживания (строка с разделителем) |
| `deposit` | `number` | Текущий баланс депозита |
| `bonus` | `number` | Текущий баланс бонусного счета |
| `agreementNumber` | `string` | Номер договора |
| `agreementAccepted` | `number` | Время подтверждения согласия клиента с договором (Unix timestamp) |
| `discount` | `number` | Постоянная скидка (в процентах или валюте) |
| `discountCurrency` | `boolean` | Постоянная скидка в валюте, иначе — в процентах |
| `blacklist` | `boolean` | Клиент в чёрном списке |
| `denyMessage` | `boolean` | Исключить клиента из рассылки |
| `widgetType` | `number` | Тип виджета, из которого создан клиент |
| `widgetTypeDesc` | `string` | Описание виджета |
| `utm` | `string` | UTM-метки |
| `chatType` | `string` | Основной тип чата (whatsapp, telegram, instagram, vk) |
| `chatId` | `string` | Идентификатор основного чата (аккаунт контакта в мессенджере) |
| `chatAnswered` | `number` | Время последнего ответа клиенту в мессенджере (Unix timestamp) |
| `pushToken` | `string` | Токен устройства для уведомлений (строка с разделителем) |
| `rfm` | `number` | RFM-статус |
| `ltv` | `number` | LTV |
| `settings` | `object` | Объект настроек клиента |
| `channels` | `array` | Каналы для связи с клиентом |
| `tag` | `array` | Массив меток клиента |
| `comment` | `array` | Массив комментариев по клиенту |
| `task` | `array` | Массив задач по клиенту |
| `document` | `object` | Документ клиента (сущность document) |
| `card` | `object` | Карта клиента |
| `informer` | `object` | Источник (откуда узнал) |
| `friend` | `object` | Действующий клиент-рекомендатель |
| `parent1` | `object` | Первый родитель |
| `parent2` | `object` | Второй родитель |
| `status` | `object` | Статус в воронке (в т.ч. вложенный pipeline) |
| `level` | `object` | Уровень клиента |
| `user` | `object` | Ответственный пользователь (user) |
| `branch` | `object` | Филиал клиента |
| `creator` | `object` | Пользователь, создавший запись (user) |
| `updater` | `object` | Пользователь последнего изменения (user) |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `updated` | `number` | Время последнего обновления (Unix timestamp) |
| `deleted` | `boolean` | Признак удаления |
| `archived` | `boolean` | Признак архивирования |
| `annotation` | `string` | Примечание |
| `fotoFileName` | `string` | Имя файла фотографии |
| `fotoUrl` | `string` | URL фото клиента |
| `fotoThumbUrl` | `string` | URL превью фото клиента |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/client/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/client/list`

_Получить список клиентов_

Возвращет массив клиентов из CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `fields` | `array` | — | Какие колонки выгружать. Если не указать, то все записи выгрузятся. | `["id", "name", "branch"]` |
| `limit` | `number` | — | Сколько записей выгружать. Если не указать, то все записи выгрузятся | `10` |
| `page` | `number` | — | Какую страницу выборки выгружать | `1` |
| `sort` | `object` | — | По какой колонке сортировать | `{"created": "desc"}` |
| `filters` | `object` | — | Фильтрация по свойствам | `{"branch": {"id": 1}}` |
| `columns` | `object` | — | Фильтрация значению (например по периоду создания) | `{"created": {"from": 1767214800, "to": 1798750800}}` |

Пример тела запроса:

```json
{
  "limit": 10,
  "page": 1,
  "sort": {
    "created": "desc"
  }
}
```

Полный набор параметров выборки (`fields`, `limit`, `page`, `sort`, `filters`, `columns`) и правила фильтрации — в разделе [«Действие list»](../02-actions.md#list).

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `total` | `number` | Общее количество клиентов в выборке |
| `items` | `array` | Массив с описанием клиентов (описание зависит от параметров fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/client/update`

_Создать клиента_

Создаёт нового клиента в CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | — | Тип сущности, для клиента — client | `"client"` |
| `lastName` | `string` | — | Фамилия | `"Тествый"` |
| `name` | `string` | да | Имя | `"Клиент"` |
| `middleName` | `string` | — | Отчество | `null` |
| `phone` | `array` | — | Телефон (масиив строк) | `["1233123312312"]` |
| `birthDate` | `number` | — | Дата рождения (UTC) | `1442876400` |
| `man` | `boolean` | — | Пол: true — муж., false — жен. | `null` |
| `email` | `string` | — | Электронная почта (строка с разделителем) | `null` |
| `socialPage` | `string` | — | Страница соц. сети (строка с разделителем) | `null` |
| `address` | `array` | — | Массив адресов | `null` |
| `document` | `object` | — | Документ клиента (паспорт, свидетельство о рождении) | `null` |
| `informer` | `object` | — | Источник (откуда узнал) | `null` |
| `level` | `object` | — | Уровень клиента | `null` |
| `friend` | `object` | — | Действующий клиент, от которого пришел текущий клиент | `null` |
| `tag` | `array` | — | Массив меток клиента | `null` |
| `comment` | `array` | — | Массив комментариев по клиенту | `null` |
| `task` | `array` | — | Массив задач по клиенту | `[]` |
| `parent1` | `object` | — | Первый родитель | `null` |
| `parent2` | `object` | — | Второй родитель | `null` |
| `status` | `object` | — | Статус клиента | `null` |
| `user` | `object` | — | Ответственный пользователь | `null` |
| `agreementNumber` | `string` | — | Номер договора | `1966` |
| `agreementAccepted` | `number` | — | Время подтверждения согласия клиента с договором (Unix timestamp) | `null` |
| `card` | `object` | — | Номер карты клиента | `null` |
| `fotoUrl` | `string` | — | URL фото клиента | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `discount` | `number` | — | Постоянная скидка (в процентах или валюте) | `null` |
| `discountCurrency` | `boolean` | — | Постоянная скидка в валюте, в противном случае - в процентах | `null` |
| `blacklist` | `boolean` | — | Клиент в черном списке | `null` |
| `denyMessage` | `boolean` | — | Исключить клиента из рассылки | `null` |
| `deposit` | `number` | — | Текущий баланс депозита | `0` |
| `bonus` | `number` | — | Текущий баланс бонусного счета | `0` |
| `annotation` | `string` | — | Примечание | `null` |

Пример тела запроса:

```json
{
  "entity": "client",
  "lastName": "Тествый",
  "name": "Клиент",
  "phone": [
    "1233123312312"
  ],
  "birthDate": 1442876400,
  "task": [],
  "agreementNumber": 1966,
  "deposit": 0,
  "bonus": 0
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного клиента |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "client", "lastName": "Тествый", "name": "Клиент", "phone": ["1233123312312"], "birthDate": 1442876400, "task": [], "agreementNumber": 1966, "deposit": 0, "bonus": 0}'
```

<a id="update"></a>
## Обновить

`POST /api/public/client/update`

_Обновить клиента_

Обновляет информацию о клиенте в CRM.

Обратите внимание, что endpoint такой же, как и при создании клиента, но для обновления необходимо передать в теле идентификатор существующего клиента (id)

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор клиента | `1` |
| `entity` | `string` | — | Тип сущности, для клиента — client | `"client"` |
| `lastName` | `string` | — | Фамилия | `"Тествый"` |
| `name` | `string` | да | Имя | `"Клиент"` |
| `middleName` | `string` | — | Отчество | `null` |
| `phone` | `array` | — | Телефон (масиив строк) | `["1233123312312"]` |
| `birthDate` | `number` | — | Дата рождения (UTC) | `1442876400` |
| `man` | `boolean` | — | Пол: true — муж., false — жен. | `null` |
| `email` | `string` | — | Электронная почта (строка с разделителем) | `null` |
| `socialPage` | `string` | — | Страница соц. сети (строка с разделителем) | `null` |
| `address` | `array` | — | Массив адресов | `null` |
| `document` | `object` | — | Документ клиента (паспорт, свидетельство о рождении) | `null` |
| `informer` | `object` | — | Источник (откуда узнал) | `null` |
| `level` | `object` | — | Уровень клиента | `null` |
| `friend` | `object` | — | Действующий клиент, от которого пришел текущий клиент | `null` |
| `tag` | `array` | — | Массив меток клиента | `null` |
| `comment` | `array` | — | Массив комментариев по клиенту | `null` |
| `task` | `array` | — | Массив задач по клиенту | `[]` |
| `parent1` | `object` | — | Первый родитель | `null` |
| `parent2` | `object` | — | Второй родитель | `null` |
| `status` | `object` | — | Статус клиента | `null` |
| `user` | `object` | — | Ответственный пользователь | `null` |
| `agreementNumber` | `string` | — | Номер договора | `1966` |
| `agreementAccepted` | `number` | — | Время подтверждения согласия клиента с договором (Unix timestamp) | `null` |
| `card` | `object` | — | Номер карты клиента | `null` |
| `fotoUrl` | `string` | — | URL фото клиента | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `discount` | `number` | — | Постоянная скидка (в процентах или валюте) | `null` |
| `discountCurrency` | `boolean` | — | Постоянная скидка в валюте, в противном случае - в процентах | `null` |
| `blacklist` | `boolean` | — | Клиент в черном списке | `null` |
| `denyMessage` | `boolean` | — | Исключить клиента из рассылки | `null` |
| `deposit` | `number` | — | Текущий баланс депозита | `0` |
| `bonus` | `number` | — | Текущий баланс бонусного счета | `0` |
| `annotation` | `string` | — | Примечание | `null` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "client",
  "lastName": "Тествый",
  "name": "Клиент",
  "phone": [
    "1233123312312"
  ],
  "birthDate": 1442876400,
  "task": [],
  "agreementNumber": 1966,
  "deposit": 0,
  "bonus": 0
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного клиента |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "client", "lastName": "Тествый", "name": "Клиент", "phone": ["1233123312312"], "birthDate": 1442876400, "task": [], "agreementNumber": 1966, "deposit": 0, "bonus": 0}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/client/delete`

_Удалить клиентов_

Удаляет клиентов в CRM.

Позволяет удалить как одного клиента, так и несколько.

### Тело запроса

Тело — JSON-массив идентификаторов: Массив идентификаторов клиентов для удаления. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
