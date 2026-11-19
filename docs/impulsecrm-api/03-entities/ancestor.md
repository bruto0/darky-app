# Родитель — сущность `ancestor`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Родитель (законный представитель) клиента. Связан с клиентом через поля `parent1` / `parent2` сущности `client`.

> **Проверено на демо-контуре 2026-11-19.** Проверено: create/load/update/delete работают. Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `ancestor`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/ancestor/load/{id}` | Получить родителя по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/ancestor/list` | Получить список родителей |
| [Создать](#create) | `POST` | `/api/public/ancestor/update` | Создать родителя |
| [Обновить](#update) | `POST` | `/api/public/ancestor/update` | Обновить родителя |
| [Удалить](#delete) | `POST` | `/api/public/ancestor/delete` | Удалить родителей |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/ancestor/load/{id}`

_Получить родителя по идентификатору_

Возвращает информацию о родителе по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор родителя | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `id` | `number` | Идентификатор родителя |
| `entity` | `string` | Тип сущности — ancestor |
| `lastName` | `string` | Фамилия |
| `name` | `string` | Имя |
| `middleName` | `string` | Отчество |
| `birthDate` | `number` | Дата рождения (Unix timestamp, UTC) |
| `man` | `boolean` | Пол: true — муж., false — жен. |
| `age` | `number` | Возраст |
| `phone` | `array` | Массив строк с телефонами |
| `email` | `string` | Электронная почта |
| `socialPage` | `string` | Страница соц. сети |
| `address` | `string` | Адрес проживания |
| `card` | `string` | Номер карты родителя |
| `branch` | `object` | Филиал |
| `creator` | `object` | Пользователь, создавший запись (user) |
| `updater` | `object` | Пользователь последнего изменения (user) |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `updated` | `number` | Время последнего обновления (Unix timestamp) |
| `deleted` | `boolean` | Признак удаления |
| `archived` | `boolean` | Признак архивирования |
| `annotation` | `string` | Примечание |
| `fotoFileName` | `string` | Имя файла фотографии |
| `fotoUrl` | `string` | URL фотографии |
| `fotoThumbUrl` | `string` | URL превью фотографии |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/ancestor/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/ancestor/list`

_Получить список родителей_

Возвращает массив родителей из CRM.

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
| `total` | `number` | Общее количество родителей в выборке |
| `items` | `array` | Массив родителей (структура зависит от параметра fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/ancestor/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/ancestor/update`

_Создать родителя_

Создаёт нового родителя в CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | да | Тип сущности — ancestor | `"ancestor"` |
| `lastName` | `string` | да | Фамилия | `"Тестовый"` |
| `name` | `string` | да | Имя | `"Тест"` |
| `middleName` | `string` | — | Отчество | `null` |
| `birthDate` | `number` | — | Дата рождения (Unix timestamp, UTC) | `null` |
| `man` | `boolean` | — | Пол: true — муж., false — жен. | `null` |
| `phone` | `array` | — | Телефоны (массив строк) | `["+71123123123"]` |
| `email` | `string` | — | Электронная почта | `null` |
| `socialPage` | `string` | — | Страница соц. сети | `null` |
| `address` | `string` | — | Адрес | `null` |
| `card` | `string` | — | Номер карты | `null` |
| `fotoUrl` | `string` | — | URL фотографии | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `annotation` | `string` | — | Примечание | `null` |

Пример тела запроса:

```json
{
  "entity": "ancestor",
  "lastName": "Тестовый",
  "name": "Тест",
  "phone": [
    "+71123123123"
  ]
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного родителя |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/ancestor/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "ancestor", "lastName": "Тестовый", "name": "Тест", "phone": ["+71123123123"]}'
```

<a id="update"></a>
## Обновить

`POST /api/public/ancestor/update`

_Обновить родителя_

Обновляет информацию о родителе в CRM.

Обратите внимание, что endpoint такой же, как и при создании, но для обновления необходимо передать в теле идентификатор существующего родителя (id)

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор родителя | `1` |
| `entity` | `string` | да | Тип сущности — ancestor | `"ancestor"` |
| `lastName` | `string` | да | Фамилия | `"Тестовый"` |
| `name` | `string` | да | Имя | `"Тест"` |
| `middleName` | `string` | — | Отчество | `null` |
| `birthDate` | `number` | — | Дата рождения (Unix timestamp, UTC) | `null` |
| `man` | `boolean` | — | Пол: true — муж., false — жен. | `null` |
| `phone` | `array` | — | Телефоны (массив строк) | `["+71123123123"]` |
| `email` | `string` | — | Электронная почта | `null` |
| `socialPage` | `string` | — | Страница соц. сети | `null` |
| `address` | `string` | — | Адрес | `null` |
| `card` | `string` | — | Номер карты | `null` |
| `fotoUrl` | `string` | — | URL фотографии | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `annotation` | `string` | — | Примечание | `null` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "ancestor",
  "lastName": "Тестовый",
  "name": "Тест",
  "phone": [
    "+71123123123"
  ]
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного родителя |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/ancestor/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "ancestor", "lastName": "Тестовый", "name": "Тест", "phone": ["+71123123123"]}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/ancestor/delete`

_Удалить родителей_

Удаляет одного или нескольких родителей в CRM.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор родителя в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/ancestor/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
