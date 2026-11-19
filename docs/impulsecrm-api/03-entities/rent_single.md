# Разовая аренда — сущность `rent_single`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Разовая аренда зала.

> **Проверено на демо-контуре 2026-11-19.** Для создания нужны `payBox`, `shift`, `pays`. Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `rentSingle`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/rent_single/load/{id}` | Получить разовую аренду по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/rent_single/list` | Получить список разовых аренд |
| [Создать](#create) | `POST` | `/api/public/rent_single/update` | Создать разовую аренду |
| [Обновить](#update) | `POST` | `/api/public/rent_single/update` | Обновить разовую аренду |
| [Удалить](#delete) | `POST` | `/api/public/rent_single/delete` | Удалить разовые аренды |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/rent_single/load/{id}`

_Получить разовую аренду по идентификатору_

Возвращает информацию о разовой аренде по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор разовой аренды | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `id` | `number` | Идентификатор разовой аренды |
| `entity` | `string` | Тип сущности, для разовой аренды — rentSingle |
| `visitDate` | `number` | Дата посещения / дата аренды (UTC) |
| `free` | `boolean` | Признак бесплатной аренды; может быть null |
| `typeName` | `string` | Название типа из прайса |
| `typeColor` | `string` | Цвет типа из прайса |
| `cost` | `number` | Стоимость аренды |
| `discount` | `number` | Скидка |
| `discountCurrency` | `boolean` | Скидка в валюте, иначе в процентах |
| `client` | `object` | Объект клиента-покупателя |
| `hall` | `object` | Объект арендуемого зала |
| `annotation` | `string` | Примечание |
| `device` | `array` | Устройства СКУД (массив идентификаторов устройств); может быть null |
| `minutesBegin` | `number` | Время начала в минутах; может быть null |
| `minutesEnd` | `number` | Время окончания в минутах; может быть null |
| `duration` | `number` | Длительность в минутах; может быть null |
| `total` | `number` | Итоговая сумма к оплате |
| `paid` | `number` | Оплаченная сумма |
| `debt` | `number` | Сумма долга |
| `refund` | `number` | Сумма возврата |
| `payBox` | `object` | Объект кассы, на которой проведена продажа |
| `shift` | `object` | Объект смены, в рамках которой проведена продажа |
| `clientOrder` | `object` | Объект интернет-заказа клиента |
| `updated` | `number` | Время последнего обновления (Unix timestamp) |
| `updater` | `object` | Объект пользователя, внесшего последнее изменение; может быть null |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `creator` | `object` | Объект пользователя, создавшего запись |
| `branch` | `object` | Объект филиала, в рамках которого проведена продажа |
| `deleted` | `boolean` | Признак удаления; может быть null |
| `archived` | `boolean` | Признак архивирования; может быть null |
| `service` | `number` | Идентификатор услуги |
| `target` | `object` | Целевой объект аренды (обычно зал) |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/rent_single/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/rent_single/list`

_Получить список разовых аренд_

Возвращает массив разовых аренд из CRM.

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
| `total` | `number` | Общее количество разовых аренд в выборке |
| `items` | `array` | Массив с описанием разовых аренд (описание зависит от параметров fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/rent_single/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/rent_single/update`

_Создать разовую аренду_

Создает новую разовую аренду в CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | да | Тип сущности, для разовой аренды — rentSingle | `"rentSingle"` |
| `visitDate` | `number` | да | Дата посещения / дата аренды (UTC) | `1616371200` |
| `free` | `boolean` | — | Признак бесплатной аренды | `false` |
| `typeName` | `string` | да | Название типа из прайса | `"Выходной день"` |
| `typeColor` | `string` | да | Цвет типа из прайса | `"D1D1D1"` |
| `cost` | `number` | да | Стоимость аренды | `500` |
| `discount` | `number` | да | Скидка | `0` |
| `discountCurrency` | `boolean` | да | Скидка в валюте, иначе в процентах | `false` |
| `client` | `object` | — | Клиент-покупатель. Обязательность поля зависит от настроек в CRM (объект, можно передать только id) | `{"id": 9}` |
| `hall` | `object` | да | Зал для аренды (объект, можно передать только id) | `{"id": 1}` |
| `annotation` | `string` | — | Примечание | `null` |
| `payBox` | `object` | — | Объект кассы, на которой проведена продажа (можно передать только id) | `{"id": 1}` |
| `shift` | `object` | — | Объект смены, в рамках которой проведена продажа (можно передать только id) | `{"id": 126}` |
| `pays` | `array` | — | Массив оплат по продаже | `[{"sum": 500, "payment": 1, "date": null}]` |
| `paid` | `number` | — | Оплаченная сумма | `500` |
| `debt` | `number` | — | Сумма долга | `0` |

Пример тела запроса:

```json
{
  "entity": "rentSingle",
  "visitDate": 1616371200,
  "free": false,
  "typeName": "Выходной день",
  "typeColor": "D1D1D1",
  "cost": 500,
  "discount": 0,
  "discountCurrency": false,
  "client": {
    "id": 9
  },
  "hall": {
    "id": 1
  },
  "payBox": {
    "id": 1
  },
  "shift": {
    "id": 126
  },
  "pays": [
    {
      "sum": 500,
      "payment": 1,
      "date": null
    }
  ],
  "paid": 500,
  "debt": 0
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `kkt` | `object` | Объект чека (если подключена касса) |
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданной разовой аренды |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/rent_single/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "rentSingle", "visitDate": 1616371200, "free": false, "typeName": "Выходной день", "typeColor": "D1D1D1", "cost": 500, "discount": 0, "discountCurrency": false, "client": {"id": 9}, "hall": {"id": 1}, "payBox": {"id": 1}, "shift": {"id": 126}, "pays": [{"sum": 500, "payment": 1, "date": null}], "paid": 500, "debt": 0}'
```

<a id="update"></a>
## Обновить

`POST /api/public/rent_single/update`

_Обновить разовую аренду_

Обновляет информацию о разовой аренде в CRM.

Обратите внимание, что endpoint такой же, как и при создании разовой аренды, но для обновления необходимо передать в теле идентификатор существующей разовой аренды (id)

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор разовой аренды | `1` |
| `entity` | `string` | да | Тип сущности, для разовой аренды — rentSingle | `"rentSingle"` |
| `visitDate` | `number` | да | Дата посещения / дата аренды (UTC) | `1616371200` |
| `free` | `boolean` | — | Признак бесплатной аренды | `false` |
| `typeName` | `string` | да | Название типа из прайса | `"Выходной день"` |
| `typeColor` | `string` | да | Цвет типа из прайса | `"D1D1D1"` |
| `cost` | `number` | да | Стоимость аренды | `500` |
| `discount` | `number` | да | Скидка | `0` |
| `discountCurrency` | `boolean` | да | Скидка в валюте, иначе в процентах | `false` |
| `client` | `object` | — | Клиент-покупатель. Обязательность поля зависит от настроек в CRM (объект, можно передать только id) | `{"id": 9}` |
| `hall` | `object` | да | Зал для аренды (объект, можно передать только id) | `{"id": 1}` |
| `annotation` | `string` | — | Примечание | `null` |
| `payBox` | `object` | — | Объект кассы, на которой проведена продажа (можно передать только id) | `{"id": 1}` |
| `shift` | `object` | — | Объект смены, в рамках которой проведена продажа (можно передать только id) | `{"id": 126}` |
| `pays` | `array` | — | Массив оплат по продаже | `[{"sum": 500, "payment": 1, "date": null}]` |
| `paid` | `number` | — | Оплаченная сумма | `500` |
| `debt` | `number` | — | Сумма долга | `0` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "rentSingle",
  "visitDate": 1616371200,
  "free": false,
  "typeName": "Выходной день",
  "typeColor": "D1D1D1",
  "cost": 500,
  "discount": 0,
  "discountCurrency": false,
  "client": {
    "id": 9
  },
  "hall": {
    "id": 1
  },
  "payBox": {
    "id": 1
  },
  "shift": {
    "id": 126
  },
  "pays": [
    {
      "sum": 500,
      "payment": 1,
      "date": null
    }
  ],
  "paid": 500,
  "debt": 0
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданной разовой аренды |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/rent_single/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "rentSingle", "visitDate": 1616371200, "free": false, "typeName": "Выходной день", "typeColor": "D1D1D1", "cost": 500, "discount": 0, "discountCurrency": false, "client": {"id": 9}, "hall": {"id": 1}, "payBox": {"id": 1}, "shift": {"id": 126}, "pays": [{"sum": 500, "payment": 1, "date": null}], "paid": 500, "debt": 0}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/rent_single/delete`

_Удалить разовые аренды_

Удаляет разовые аренды в CRM.

Позволяет удалить как одну разовую аренду, так и несколько.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор разовой аренды в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/rent_single/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
