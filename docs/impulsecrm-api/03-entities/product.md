# Товар — сущность `product`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Продажа товара: позиции, касса, смена, оплаты.

> **Проверено на демо-контуре 2026-11-19.** `id` в ответе на создание приходит **массивом** (`"id": [3]`); `load` — по элементу массива. Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `product`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/product/load/{id}` | Получить продажу товара по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/product/list` | Получить список продаж товаров |
| [Создать](#create) | `POST` | `/api/public/product/update` | Создать запись продажи товара |
| [Обновить](#update) | `POST` | `/api/public/product/update` | Обновить запись продажи товара |
| [Удалить](#delete) | `POST` | `/api/public/product/delete` | Удалить записи продажи товаров |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/product/load/{id}`

_Получить продажу товара по идентификатору_

Возвращает одну запись продажи товара по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор записи продажи товара | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `id` | `number` | Идентификатор записи товара |
| `entity` | `string` | Тип сущности — product |
| `count` | `number` | Количество единиц по записи |
| `type` | `object` | Объект типа товара |
| `section` | `object` | Раздел товара |
| `markingCode` | `string` | Код маркировки |
| `markingCheckInfo` | `object` | Результаты проверки маркировки |
| `certNumber` | `string` | Номер сертификата |
| `certMonths` | `number` | Срок сертификата в месяцах |
| `certEndDate` | `number` | Окончание действия сертификата (Unix timestamp) |
| `certActivatedSum` | `number` | Активированная по сертификату сумма |
| `certAvailableSum` | `number` | Доступный остаток по сертификату |
| `given` | `number` | Время выдачи / проведения продажи (Unix timestamp) |
| `total` | `number` | Итоговая сумма по строке |
| `cost` | `number` | Стоимость (цена продажи) |
| `discount` | `number` | Скидка |
| `discountCurrency` | `boolean` | Скидка в валюте, иначе в процентах |
| `paid` | `number` | Оплачено |
| `debt` | `number` | Долг |
| `refund` | `number` | Сумма возврата |
| `refundCount` | `number` | Количество единиц возврата товара на склад |
| `refundTime` | `number` | Время возврата (Unix timestamp) |
| `client` | `object` | Клиент |
| `payBox` | `object` | Касса (payBox): имя, смена, поля ККТ |
| `shift` | `object` | Смена |
| `clientOrder` | `object` | Объект интернет-заказа клиента |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `creator` | `object` | Пользователь, создавший запись (user) |
| `updated` | `number` | Время последнего обновления |
| `updater` | `object` | Пользователь последнего изменения |
| `branch` | `object` | Филиал |
| `deleted` | `boolean` | Признак удаления |
| `archived` | `boolean` | Признак архивирования |
| `annotation` | `string` | Примечание |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/product/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/product/list`

_Получить список продаж товаров_

Возвращает массив записей продаж товаров из CRM. Структура элементов при полной выгрузке совпадает с ответом load.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `fields` | `array` | — | Какие колонки выгружать. Если не указать, то все записи выгрузятся. | `["id", "type", "branch", "count"]` |
| `limit` | `number` | — | Сколько записей выгружать. Если не указать, то все записи выгрузятся | `10` |
| `page` | `number` | — | Какую страницу выборки выгружать | `1` |
| `sort` | `object` | — | По какой колонке сортировать | `{"created": "desc"}` |
| `filters` | `object` | — | Фильтрация по свойствам | `{"branch": {"id": 1}}` |
| `columns` | `object` | — | Фильтрация по значению (например по периоду создания) | `{"created": {"from": 1767214800, "to": 1798750800}}` |

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
| `total` | `number` | Общее количество записей в выборке |
| `items` | `array` | Массив записей товара (структура зависит от параметра fields; при полной выгрузке — как в ответе load) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/product/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/product/update`

_Создать запись продажи товара_

Создаёт новую запись продажи товара в CRM. Поля тела — в таблице ниже. При создании не передаётся id.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | да | Тип сущности — product | `"product"` |
| `count` | `number` | — | Количество единиц | `null` |
| `cost` | `number` | — | Стоимость | `null` |
| `discount` | `number` | — | Скидка | `null` |
| `discountCurrency` | `boolean` | — | Скидка в валюте, иначе в процентах | `false` |
| `type` | `object` | — | Тип продажи | `null` |
| `client` | `object` | — | Клиент (объект, можно передать только id) | `null` |
| `markingCode` | `string` | — | Код маркировки | `null` |
| `annotation` | `string` | — | Примечание | `null` |
| `items` | `array` | да | Позиции товара (каждый элемент: count, type, certMonths, cost, discount, discountCurrency, total) | `[{"count": 1, "type": {"id": 1}, "certMonths": null, "cost": 70, "discount": null, "dis…` |
| `payBox` | `object` | да | Касса (объект, можно передать только id) | `{"id": 1}` |
| `shift` | `object` | да | Смена (объект, можно передать только id) | `{"id": 149}` |
| `pays` | `array` | да | Оплаты (массив объектов: sum, payment, date) | `[{"sum": 70, "payment": 1, "date": null}]` |
| `paid` | `number` | да | Оплаченная сумма | `70` |
| `given` | `number` | — | Дата/время проведения (Unix timestamp) | `1775546240` |
| `debt` | `number` | — | Долг | `null` |

Пример тела запроса:

```json
{
  "entity": "product",
  "discountCurrency": false,
  "items": [
    {
      "count": 1,
      "type": {
        "id": 1
      },
      "certMonths": null,
      "cost": 70,
      "discount": null,
      "discountCurrency": null,
      "total": 70
    }
  ],
  "payBox": {
    "id": 1
  },
  "shift": {
    "id": 149
  },
  "pays": [
    {
      "sum": 70,
      "payment": 1,
      "date": null
    }
  ],
  "paid": 70,
  "given": 1775546240
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `kkt` | `object` | Объект чека (если подключена касса) |
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `array` | Массив идентификаторов созданных записей товара |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/product/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "product", "discountCurrency": false, "items": [{"count": 1, "type": {"id": 1}, "certMonths": null, "cost": 70, "discount": null, "discountCurrency": null, "total": 70}], "payBox": {"id": 1}, "shift": {"id": 149}, "pays": [{"sum": 70, "payment": 1, "date": null}], "paid": 70, "given": 1775546240}'
```

<a id="update"></a>
## Обновить

`POST /api/public/product/update`

_Обновить запись продажи товара_

Обновляет запись продажи товара в CRM.

Endpoint такой же, как при создании. В теле передаётся id существующей записи и поля, которые нужно изменить.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор записи товара | `1` |
| `entity` | `string` | да | Тип сущности — product | `"product"` |
| `count` | `number` | — | Количество единиц | `null` |
| `cost` | `number` | — | Стоимость | `null` |
| `discount` | `number` | — | Скидка | `null` |
| `discountCurrency` | `boolean` | — | Скидка в валюте, иначе в процентах | `false` |
| `type` | `object` | — | Тип продажи | `null` |
| `client` | `object` | — | Клиент (объект, можно передать только id) | `null` |
| `markingCode` | `string` | — | Код маркировки | `null` |
| `annotation` | `string` | — | Примечание | `null` |
| `items` | `array` | да | Позиции товара (каждый элемент: count, type, certMonths, cost, discount, discountCurrency, total) | `[{"count": 1, "type": {"id": 1}, "certMonths": null, "cost": 70, "discount": null, "dis…` |
| `payBox` | `object` | да | Касса (объект, можно передать только id) | `{"id": 1}` |
| `shift` | `object` | да | Смена (объект, можно передать только id) | `{"id": 149}` |
| `pays` | `array` | да | Оплаты (массив объектов: sum, payment, date) | `[{"sum": 70, "payment": 1, "date": null}]` |
| `paid` | `number` | да | Оплаченная сумма | `70` |
| `given` | `number` | — | Дата/время проведения (Unix timestamp) | `1775546240` |
| `debt` | `number` | — | Долг | `null` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "product",
  "discountCurrency": false,
  "items": [
    {
      "count": 1,
      "type": {
        "id": 1
      },
      "certMonths": null,
      "cost": 70,
      "discount": null,
      "discountCurrency": null,
      "total": 70
    }
  ],
  "payBox": {
    "id": 1
  },
  "shift": {
    "id": 149
  },
  "pays": [
    {
      "sum": 70,
      "payment": 1,
      "date": null
    }
  ],
  "paid": 70,
  "given": 1775546240
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `array` | Массив идентификаторов созданных записей товара |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/product/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "product", "discountCurrency": false, "items": [{"count": 1, "type": {"id": 1}, "certMonths": null, "cost": 70, "discount": null, "discountCurrency": null, "total": 70}], "payBox": {"id": 1}, "shift": {"id": 149}, "pays": [{"sum": 70, "payment": 1, "date": null}], "paid": 70, "given": 1775546240}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/product/delete`

_Удалить записи продажи товаров_

Удаляет одну или несколько записей товаров в CRM.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор записи продажи товара в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/product/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
