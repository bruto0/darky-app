# Разовое групповое занятие — сущность `group_single`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Разовое групповое занятие (продажа/посещение без абонемента).

> **Проверено на демо-контуре 2026-11-19.** Для создания нужны `payBox`, `shift`, `pays`. Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `groupSingle`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/group_single/load/{id}` | Получить разовое групповое занятие по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/group_single/list` | Получить список разовых групповых занятий |
| [Создать](#create) | `POST` | `/api/public/group_single/update` | Создать разовое групповое занятие |
| [Обновить](#update) | `POST` | `/api/public/group_single/update` | Обновить разовое групповое занятие |
| [Удалить](#delete) | `POST` | `/api/public/group_single/delete` | Удалить разовые групповые занятия |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/group_single/load/{id}`

_Получить разовое групповое занятие по идентификатору_

Возвращает информацию о разовом групповом занятии по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор разового группового занятия | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `group` | `object` | Объект группы, для которой оформлено разовое занятие |
| `hall` | `object` | Объект зала, в котором проводится занятие |
| `service` | `number` | Идентификатор услуги |
| `target` | `object` | Целевой объект занятия (обычно группа) |
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
| `id` | `number` | Идентификатор разового группового занятия |
| `entity` | `string` | Тип сущности, для разового группового занятия — groupSingle |
| `deleted` | `boolean` | Признак удаления разового группового занятия |
| `archived` | `boolean` | Признак архивирования разового группового занятия |
| `annotation` | `string` | Примечание |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/group_single/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/group_single/list`

_Получить список разовых групповых занятий_

Возвращает массив разовых групповых занятий из CRM.

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
| `total` | `number` | Общее количество разовых групповых занятий в выборке |
| `items` | `array` | Массив с описанием разовых групповых занятий (описание зависит от параметров fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/group_single/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/group_single/update`

_Создать разовое групповое занятие_

Создает новое разовое групповое занятие в CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | да | Тип сущности, для разового группового занятия — groupSingle | `"groupSingle"` |
| `visitDate` | `number` | да | Дата посещения (UTC) | `1775001600` |
| `free` | `boolean` | — | Признак пробного занятия | `false` |
| `typeName` | `string` | да | Название типа занятия из прайса | `"Детское"` |
| `typeColor` | `string` | да | Цвет типа занятия из прайса | `"D1D1D1"` |
| `cost` | `number` | да | Стоимость занятия | `250` |
| `discount` | `number` | да | Скидка | `0` |
| `discountCurrency` | `boolean` | да | Скидка в валюте, иначе в процентах | `false` |
| `client` | `object` | — | Клиент-покупатель. Обязательность поля зависит от настроек в CRM (объект, можно передать только id) | `{"id": 3}` |
| `group` | `object` | да | Группа для разового занятия (объект, можно передать только id) | `{"id": 17}` |
| `annotation` | `string` | — | Примечание | `null` |
| `payBox` | `object` | — | Объект кассы, на которой проведена продажа (можно передать только id) | `{"id": 1}` |
| `shift` | `object` | — | Объект смены, в рамках которой проведена продажа (можно передать только id) | `{"id": 149}` |
| `pays` | `array` | — | Массив оплат по продаже | `[{"sum": 250, "payment": 1, "date": null}]` |
| `paid` | `number` | — | Оплаченная сумма | `250` |
| `debt` | `number` | — | Сумма долга | `null` |

Пример тела запроса:

```json
{
  "entity": "groupSingle",
  "visitDate": 1775001600,
  "free": false,
  "typeName": "Детское",
  "typeColor": "D1D1D1",
  "cost": 250,
  "discount": 0,
  "discountCurrency": false,
  "client": {
    "id": 3
  },
  "group": {
    "id": 17
  },
  "payBox": {
    "id": 1
  },
  "shift": {
    "id": 149
  },
  "pays": [
    {
      "sum": 250,
      "payment": 1,
      "date": null
    }
  ],
  "paid": 250
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `kkt` | `object` | Объект чека (если подключена касса) |
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного разового группового занятия |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/group_single/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "groupSingle", "visitDate": 1775001600, "free": false, "typeName": "Детское", "typeColor": "D1D1D1", "cost": 250, "discount": 0, "discountCurrency": false, "client": {"id": 3}, "group": {"id": 17}, "payBox": {"id": 1}, "shift": {"id": 149}, "pays": [{"sum": 250, "payment": 1, "date": null}], "paid": 250}'
```

<a id="update"></a>
## Обновить

`POST /api/public/group_single/update`

_Обновить разовое групповое занятие_

Обновляет информацию о разовом групповом занятии в CRM.

Обратите внимание, что endpoint такой же, как и при создании разового группового занятия, но для обновления необходимо передать в теле идентификатор существующего разового группового занятия (id)

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор разового группового занятия | `1` |
| `entity` | `string` | да | Тип сущности, для разового группового занятия — groupSingle | `"groupSingle"` |
| `visitDate` | `number` | да | Дата посещения (UTC) | `1775001600` |
| `free` | `boolean` | — | Признак пробного занятия | `false` |
| `typeName` | `string` | да | Название типа занятия из прайса | `"Детское"` |
| `typeColor` | `string` | да | Цвет типа занятия из прайса | `"D1D1D1"` |
| `cost` | `number` | да | Стоимость занятия | `250` |
| `discount` | `number` | да | Скидка | `0` |
| `discountCurrency` | `boolean` | да | Скидка в валюте, иначе в процентах | `false` |
| `client` | `object` | — | Клиент-покупатель. Обязательность поля зависит от настроек в CRM (объект, можно передать только id) | `{"id": 3}` |
| `group` | `object` | да | Группа для разового занятия (объект, можно передать только id) | `{"id": 17}` |
| `annotation` | `string` | — | Примечание | `null` |
| `payBox` | `object` | — | Объект кассы, на которой проведена продажа (можно передать только id) | `{"id": 1}` |
| `shift` | `object` | — | Объект смены, в рамках которой проведена продажа (можно передать только id) | `{"id": 149}` |
| `pays` | `array` | — | Массив оплат по продаже | `[{"sum": 250, "payment": 1, "date": null}]` |
| `paid` | `number` | — | Оплаченная сумма | `250` |
| `debt` | `number` | — | Сумма долга | `null` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "groupSingle",
  "visitDate": 1775001600,
  "free": false,
  "typeName": "Детское",
  "typeColor": "D1D1D1",
  "cost": 250,
  "discount": 0,
  "discountCurrency": false,
  "client": {
    "id": 3
  },
  "group": {
    "id": 17
  },
  "payBox": {
    "id": 1
  },
  "shift": {
    "id": 149
  },
  "pays": [
    {
      "sum": 250,
      "payment": 1,
      "date": null
    }
  ],
  "paid": 250
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного разового группового занятия |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/group_single/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "groupSingle", "visitDate": 1775001600, "free": false, "typeName": "Детское", "typeColor": "D1D1D1", "cost": 250, "discount": 0, "discountCurrency": false, "client": {"id": 3}, "group": {"id": 17}, "payBox": {"id": 1}, "shift": {"id": 149}, "pays": [{"sum": 250, "payment": 1, "date": null}], "paid": 250}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/group_single/delete`

_Удалить разовые групповые занятия_

Удаляет разовые групповые занятия в CRM.

Позволяет удалить как одно разовое групповое занятие, так и несколько.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор разового группового занятия в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/group_single/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
