# Зал — сущность `hall`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Зал, в котором проводятся занятия.

> **Проверено на демо-контуре 2026-11-19.** Для создания нужен `options` (иначе NOT NULL → 500). Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `hall`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/hall/load/{id}` | Получить зал по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/hall/list` | Получить список залов |
| [Создать](#create) | `POST` | `/api/public/hall/update` | Создать зал |
| [Обновить](#update) | `POST` | `/api/public/hall/update` | Обновить зал |
| [Удалить](#delete) | `POST` | `/api/public/hall/delete` | Удалить залы |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/hall/load/{id}`

_Получить зал по идентификатору_

Возвращает информацию о зале по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор зала | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `id` | `number` | Идентификатор зала |
| `entity` | `string` | Тип сущности — hall |
| `name` | `string` | Название зала |
| `number` | `number` | Номер зала |
| `color` | `string` | Цвет в интерфейсе (hex без решётки, например 6aa84f) |
| `area` | `number` | Площадь |
| `placeCount` | `number` | Количество мест |
| `options` | `object` | Опции зала в ответе load (объект: widgetRent, widgetRentCost, widgetImages и др.) |
| `branch` | `object` | Филиал |
| `creator` | `object` | Пользователь, создавший запись (user) |
| `updater` | `object` | Пользователь последнего изменения (user) |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `updated` | `number` | Время последнего обновления (Unix timestamp) |
| `deleted` | `boolean` | Признак удаления |
| `archived` | `boolean` | Признак архивирования |
| `annotation` | `string` | Примечание |
| `fotoFileName` | `string` | Имя файла фотографии зала |
| `fotoUrl` | `string` | URL фото зала |
| `fotoThumbUrl` | `string` | URL превью фото зала |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/hall/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/hall/list`

_Получить список залов_

Возвращает массив залов из CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `fields` | `array` | — | Какие колонки выгружать. Если не указать, то все записи выгрузятся. | `["id", "name", "branch"]` |
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
| `total` | `number` | Общее количество залов в выборке |
| `items` | `array` | Массив залов (структура зависит от параметра fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/hall/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/hall/update`

_Создать зал_

Создаёт новый зал в CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | да | Тип сущности — hall | `"hall"` |
| `name` | `string` | да | Название зала | `"Тестовый"` |
| `color` | `string` | да | Цвет в интерфейсе (hex без решётки) | `"ffd966"` |
| `number` | `number` | — | Номер зала | `2` |
| `area` | `number` | — | Площадь | `null` |
| `placeCount` | `number` | — | Количество мест | `null` |
| `options` | `array` | — | Опции зала (массив; при отсутствии настроек — пустой массив) | `[]` |
| `fotoUrl` | `string` | — | URL фото зала | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `annotation` | `string` | — | Примечание | `null` |

Пример тела запроса:

```json
{
  "entity": "hall",
  "name": "Тестовый",
  "color": "ffd966",
  "number": 2,
  "options": []
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного зала |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/hall/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "hall", "name": "Тестовый", "color": "ffd966", "number": 2, "options": []}'
```

<a id="update"></a>
## Обновить

`POST /api/public/hall/update`

_Обновить зал_

Обновляет зал в CRM.

Endpoint такой же, как при создании; в теле обязательно передайте id существующего зала и поля, которые нужно изменить.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор зала | `1` |
| `entity` | `string` | да | Тип сущности — hall | `"hall"` |
| `name` | `string` | да | Название зала | `"Тестовый"` |
| `color` | `string` | да | Цвет в интерфейсе (hex без решётки) | `"ffd966"` |
| `number` | `number` | — | Номер зала | `2` |
| `area` | `number` | — | Площадь | `null` |
| `placeCount` | `number` | — | Количество мест | `null` |
| `options` | `array` | — | Опции зала (массив; при отсутствии настроек — пустой массив) | `[]` |
| `fotoUrl` | `string` | — | URL фото зала | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `annotation` | `string` | — | Примечание | `null` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "hall",
  "name": "Тестовый",
  "color": "ffd966",
  "number": 2,
  "options": []
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного зала |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/hall/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "hall", "name": "Тестовый", "color": "ffd966", "number": 2, "options": []}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/hall/delete`

_Удалить залы_

Удаляет один или несколько залов в CRM.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор зала в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/hall/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
