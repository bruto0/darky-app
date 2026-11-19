# Филиал — сущность `branch`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Филиал (студия/клуб).

> **Проверено на демо-контуре 2026-11-19.** Для создания нужен `options` (иначе NOT NULL → 500). Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `branch`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/branch/load/{id}` | Получить филиал по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/branch/list` | Получить список филиалов |
| [Создать](#create) | `POST` | `/api/public/branch/update` | Создать филиал |
| [Обновить](#update) | `POST` | `/api/public/branch/update` | Обновить филиал |
| [Удалить](#delete) | `POST` | `/api/public/branch/delete` | Удалить филиалы |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/branch/load/{id}`

_Получить филиал по идентификатору_

Возвращает информацию о филиале по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор филиала | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `number` | `number` | Внутренний номер филиала |
| `site` | `string` | Сайт филиала |
| `phone` | `string` | Телефон филиала |
| `messenger` | `string` | Ссылка на мессенджер филиала |
| `separateClients` | `boolean` | К филиалу относятся только клиенты этого филиала |
| `separateEmployees` | `boolean` | К филиалу относятся только преподаватели этого филиала |
| `options` | `object` | Объект настроек филиала |
| `timezoneOffset` | `number` | Смещение часового пояса в минутах |
| `id` | `number` | Идентификатор филиала |
| `entity` | `string` | Тип сущности, для филиала — branch |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `deleted` | `boolean` | Признак удаления филиала |
| `archived` | `boolean` | Признак архивирования филиала |
| `name` | `string` | Название филиала |
| `fotoFileName` | `string` | Имя файла фотографии филиала |
| `fotoUrl` | `string` | URL фото филиала |
| `fotoThumbUrl` | `string` | URL превью фото филиала |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/branch/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/branch/list`

_Получить список филиалов_

Возвращает массив филиалов из CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `fields` | `array` | — | Какие колонки выгружать. Если не указать, то все записи выгрузятся. | `["name", "id"]` |
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
| `total` | `number` | Общее количество филиалов в выборке |
| `items` | `array` | Массив с описанием филиалов (описание зависит от параметров fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/branch/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/branch/update`

_Создать филиал_

Создает новый филиал в CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | да | Тип сущности, для филиала — branch | `"branch"` |
| `name` | `string` | да | Название филиала | `"тестовый"` |
| `number` | `number` | да | Внутренний номер филиала | `4` |
| `site` | `string` | — | Сайт филиала | `null` |
| `phone` | `string` | — | Телефон филиала | `null` |
| `messenger` | `string` | — | Ссылка на мессенджер филиала | `null` |
| `separateClients` | `boolean` | — | К филиалу относятся только клиенты этого филиала | `null` |
| `separateEmployees` | `boolean` | — | К филиалу относятся только преподаватели этого филиала | `null` |
| `fotoUrl` | `string` | — | URL фото филиала | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `options` | `array` | — | Массив настроек филиала | `[]` |

Пример тела запроса:

```json
{
  "entity": "branch",
  "name": "тестовый",
  "number": 4,
  "options": []
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного филиала |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/branch/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "branch", "name": "тестовый", "number": 4, "options": []}'
```

<a id="update"></a>
## Обновить

`POST /api/public/branch/update`

_Обновить филиал_

Обновляет информацию о филиале в CRM.

Обратите внимание, что endpoint такой же, как и при создании филиала, но для обновления необходимо передать в теле идентификатор существующего филиала (id)

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор филиала | `1` |
| `entity` | `string` | да | Тип сущности, для филиала — branch | `"branch"` |
| `name` | `string` | да | Название филиала | `"тестовый"` |
| `number` | `number` | да | Внутренний номер филиала | `4` |
| `site` | `string` | — | Сайт филиала | `null` |
| `phone` | `string` | — | Телефон филиала | `null` |
| `messenger` | `string` | — | Ссылка на мессенджер филиала | `null` |
| `separateClients` | `boolean` | — | К филиалу относятся только клиенты этого филиала | `null` |
| `separateEmployees` | `boolean` | — | К филиалу относятся только преподаватели этого филиала | `null` |
| `fotoUrl` | `string` | — | URL фото филиала | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `options` | `array` | — | Массив настроек филиала | `[]` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "branch",
  "name": "тестовый",
  "number": 4,
  "options": []
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного филиала |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/branch/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "branch", "name": "тестовый", "number": 4, "options": []}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/branch/delete`

_Удалить филиалы_

Удаляет филиалы в CRM.

Позволяет удалить как один филиал, так и несколько.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор филиала в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/branch/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
