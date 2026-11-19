# Разовое самостоятельное занятие — сущность `self_single`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Разовое самостоятельное занятие.

> **Проверено на демо-контуре 2026-11-19.** Для создания нужны `payBox`, `shift`, `pays`. Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `selfSingle`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/self_single/load/{id}` | Получить разовое самостоятельное занятие по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/self_single/list` | Получить список разовых самостоятельных занятий |
| [Создать](#create) | `POST` | `/api/public/self_single/update` | Создать разовое самостоятельное занятие |
| [Обновить](#update) | `POST` | `/api/public/self_single/update` | Обновить разовое самостоятельное занятие |
| [Удалить](#delete) | `POST` | `/api/public/self_single/delete` | Удалить разовые самостоятельные занятия |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/self_single/load/{id}`

_Получить разовое самостоятельное занятие по идентификатору_

Возвращает информацию о разовом самостоятельном занятии по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор разового самостоятельного занятия | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `visitDate` | `number` | Дата посещения (UTC) |
| `device` | `array` | Устройства СКУД (массив идентификаторов устройств) |
| `free` | `boolean` | Признак бесплатного занятия |
| `minutesBegin` | `number` | Время начала занятия в минутах |
| `minutesEnd` | `number` | Время окончания занятия в минутах |
| `duration` | `number` | Длительность занятия в минутах |
| `typeName` | `string` | Название типа занятия из прайса |
| `typeColor` | `string` | Цвет типа занятия из прайса |
| `cost` | `number` | Стоимость занятия |
| `discount` | `number` | Скидка |
| `discountCurrency` | `boolean` | Скидка в валюте, иначе в процентах |
| `total` | `number` | Итоговая сумма к оплате |
| `paid` | `number` | Оплаченная сумма |
| `debt` | `number` | Сумма долга |
| `refund` | `number` | Сумма возврата |
| `client` | `object` | Объект клиента-покупателя |
| `payBox` | `object` | Объект кассы, на которой проведена продажа |
| `shift` | `object` | Объект смены, в рамках которой проведена продажа |
| `clientOrder` | `object` | Объект интернет-заказа клиента |
| `updated` | `number` | Время последнего обновления (Unix timestamp) |
| `updater` | `object` | Объект пользователя, внесшего последнее изменение |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `creator` | `object` | Объект пользователя, создавшего запись |
| `branch` | `object` | Объект филиала, в рамках которого проведена продажа |
| `id` | `number` | Идентификатор разового самостоятельного занятия |
| `entity` | `string` | Тип сущности, для разового самостоятельного занятия — selfSingle |
| `deleted` | `boolean` | Признак удаления разового самостоятельного занятия |
| `archived` | `boolean` | Признак архивирования разового самостоятельного занятия |
| `annotation` | `string` | Примечание |
| `hall` | `object` | Объект зала, в котором проводится занятие |
| `service` | `number` | Идентификатор услуги |
| `target` | `object` | Целевой объект занятия (обычно зал) |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/self_single/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/self_single/list`

_Получить список разовых самостоятельных занятий_

Возвращает массив разовых самостоятельных занятий из CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `fields` | `array` | — | Какие колонки выгружать. Если не указать, то все записи выгрузятся. | `["id", "entity", "client"]` |
| `limit` | `number` | — | Сколько записей выгружать. Если не указать, то все записи выгрузятся | `10` |
| `page` | `number` | — | Какую страницу выборки выгружать | `1` |
| `sort` | `object` | — | По какой колонке сортировать | `{"created": "desc"}` |
| `filters` | `object` | — | Фильтрация по свойствам | `[]` |
| `columns` | `object` | — | Фильтрация значению (например по периоду создания) | `[]` |

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
| `total` | `number` | Общее количество разовых самостоятельных занятий в выборке |
| `items` | `array` | Массив с описанием разовых самостоятельных занятий (описание зависит от параметров fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/self_single/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/self_single/update`

_Создать разовое самостоятельное занятие_

Создает новое разовое самостоятельное занятие в CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | да | Тип сущности, для разового самостоятельного занятия — selfSingle | `"selfSingle"` |
| `visitDate` | `number` | да | Дата посещения (UTC) | `1775001600` |
| `free` | `boolean` | — | Признак бесплатного занятия | `false` |
| `typeName` | `string` | да | Название типа занятия из прайса | `"Выходной день"` |
| `typeColor` | `string` | да | Цвет типа занятия из прайса | `"D1D1D1"` |
| `cost` | `number` | да | Стоимость занятия | `400` |
| `discount` | `number` | да | Скидка | `0` |
| `discountCurrency` | `boolean` | да | Скидка в валюте, иначе в процентах | `false` |
| `client` | `object` | — | Клиент-покупатель. Обязательность поля зависит от настроек в CRM (объект, можно передать только id) | `null` |
| `hall` | `object` | да | Зал для разового занятия (объект, можно передать только id) | `{"id": 1}` |
| `annotation` | `string` | — | Примечание | `null` |
| `payBox` | `object` | — | Объект кассы, на которой проведена продажа (можно передать только id) | `{"id": 1}` |
| `shift` | `object` | — | Объект смены, в рамках которой проведена продажа (можно передать только id) | `{"id": 149}` |
| `pays` | `array` | — | Массив оплат по продаже | `[{"sum": 400, "payment": 1, "date": null}]` |
| `paid` | `number` | — | Оплаченная сумма | `400` |
| `debt` | `number` | — | Сумма долга | `null` |

Пример тела запроса:

```json
{
  "entity": "selfSingle",
  "visitDate": 1775001600,
  "free": false,
  "typeName": "Выходной день",
  "typeColor": "D1D1D1",
  "cost": 400,
  "discount": 0,
  "discountCurrency": false,
  "hall": {
    "id": 1
  },
  "payBox": {
    "id": 1
  },
  "shift": {
    "id": 149
  },
  "pays": [
    {
      "sum": 400,
      "payment": 1,
      "date": null
    }
  ],
  "paid": 400
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `kkt` | `object` | Объект чека (если подключена касса) |
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного разового самостоятельного занятия |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/self_single/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "selfSingle", "visitDate": 1775001600, "free": false, "typeName": "Выходной день", "typeColor": "D1D1D1", "cost": 400, "discount": 0, "discountCurrency": false, "hall": {"id": 1}, "payBox": {"id": 1}, "shift": {"id": 149}, "pays": [{"sum": 400, "payment": 1, "date": null}], "paid": 400}'
```

<a id="update"></a>
## Обновить

`POST /api/public/self_single/update`

_Обновить разовое самостоятельное занятие_

Обновляет информацию о разовом самостоятельном занятии в CRM.

Обратите внимание, что endpoint такой же, как и при создании разового самостоятельного занятия, но для обновления необходимо передать в теле идентификатор существующего разового самостоятельного занятия (id)

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор разового самостоятельного занятия | `1` |
| `entity` | `string` | да | Тип сущности, для разового самостоятельного занятия — selfSingle | `"selfSingle"` |
| `visitDate` | `number` | да | Дата посещения (UTC) | `1775001600` |
| `free` | `boolean` | — | Признак бесплатного занятия | `false` |
| `typeName` | `string` | да | Название типа занятия из прайса | `"Выходной день"` |
| `typeColor` | `string` | да | Цвет типа занятия из прайса | `"D1D1D1"` |
| `cost` | `number` | да | Стоимость занятия | `400` |
| `discount` | `number` | да | Скидка | `0` |
| `discountCurrency` | `boolean` | да | Скидка в валюте, иначе в процентах | `false` |
| `client` | `object` | — | Клиент-покупатель. Обязательность поля зависит от настроек в CRM (объект, можно передать только id) | `null` |
| `hall` | `object` | да | Зал для разового занятия (объект, можно передать только id) | `{"id": 1}` |
| `annotation` | `string` | — | Примечание | `null` |
| `payBox` | `object` | — | Объект кассы, на которой проведена продажа (можно передать только id) | `{"id": 1}` |
| `shift` | `object` | — | Объект смены, в рамках которой проведена продажа (можно передать только id) | `{"id": 149}` |
| `pays` | `array` | — | Массив оплат по продаже | `[{"sum": 400, "payment": 1, "date": null}]` |
| `paid` | `number` | — | Оплаченная сумма | `400` |
| `debt` | `number` | — | Сумма долга | `null` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "selfSingle",
  "visitDate": 1775001600,
  "free": false,
  "typeName": "Выходной день",
  "typeColor": "D1D1D1",
  "cost": 400,
  "discount": 0,
  "discountCurrency": false,
  "hall": {
    "id": 1
  },
  "payBox": {
    "id": 1
  },
  "shift": {
    "id": 149
  },
  "pays": [
    {
      "sum": 400,
      "payment": 1,
      "date": null
    }
  ],
  "paid": 400
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного разового самостоятельного занятия |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/self_single/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "selfSingle", "visitDate": 1775001600, "free": false, "typeName": "Выходной день", "typeColor": "D1D1D1", "cost": 400, "discount": 0, "discountCurrency": false, "hall": {"id": 1}, "payBox": {"id": 1}, "shift": {"id": 149}, "pays": [{"sum": 400, "payment": 1, "date": null}], "paid": 400}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/self_single/delete`

_Удалить разовые самостоятельные занятия_

Удаляет разовые самостоятельные занятия в CRM.

Позволяет удалить как одно разовое самостоятельное занятие, так и несколько.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор разового самостоятельного занятия в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/self_single/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
