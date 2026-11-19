# Направление — сущность `style`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Направление (вид занятий): название, описание, фото.

> **Проверено на демо-контуре 2026-11-19.** Самое простое тело создания: `entity` + `name`. Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `style`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/style/load/{id}` | Получить направление по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/style/list` | Получить список направлений |
| [Создать](#create) | `POST` | `/api/public/style/update` | Создать направление |
| [Обновить](#update) | `POST` | `/api/public/style/update` | Обновить направление |
| [Удалить](#delete) | `POST` | `/api/public/style/delete` | Удалить направления |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/style/load/{id}`

_Получить направление по идентификатору_

Возвращает информацию о направлении по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор направления | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `id` | `number` | Идентификатор направления |
| `entity` | `string` | Тип сущности, для направления — style |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `deleted` | `boolean` | Признак удаления направления (или null) |
| `archived` | `boolean` | Признак архивирования направления (или null) |
| `name` | `string` | Название направления |
| `fotoFileName` | `string` | Имя файла фотографии направления |
| `fotoUrl` | `string` | URL фото направления |
| `fotoThumbUrl` | `string` | URL превью фото направления |
| `description` | `string` | Описание направления (или null) |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/style/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/style/list`

_Получить список направлений_

Возвращает массив направлений из CRM.

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
| `total` | `number` | Общее количество направлений в выборке |
| `items` | `array` | Массив с описанием направлений (описание зависит от параметров fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/style/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/style/update`

_Создать направление_

Создает новое направление в CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | да | Тип сущности, для направления — style | `"style"` |
| `name` | `string` | да | Название направления | `"Тестовое направление"` |
| `description` | `string` | — | Описание направления | `null` |
| `fotoUrl` | `string` | — | URL фото направления | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |

Пример тела запроса:

```json
{
  "entity": "style",
  "name": "Тестовое направление"
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного направления |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/style/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "style", "name": "Тестовое направление"}'
```

<a id="update"></a>
## Обновить

`POST /api/public/style/update`

_Обновить направление_

Обновляет информацию о направлении в CRM.

Обратите внимание, что endpoint такой же, как и при создании направления, но для обновления необходимо передать в теле идентификатор существующего направления (id)

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор направления | `1` |
| `entity` | `string` | да | Тип сущности, для направления — style | `"style"` |
| `name` | `string` | да | Название направления | `"Тестовое направление"` |
| `description` | `string` | — | Описание направления | `null` |
| `fotoUrl` | `string` | — | URL фото направления | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "style",
  "name": "Тестовое направление"
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного направления |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/style/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "style", "name": "Тестовое направление"}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/style/delete`

_Удалить направления_

Удаляет направления в CRM.

Позволяет удалить как одно направление, так и несколько.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор направления в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/style/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
