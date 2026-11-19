# Запись на занятие — сущность `reservation`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Запись клиента на занятие (в расписании).

> **Проверено на демо-контуре 2026-11-19.** Ответ на создание: `{"success": true, "count": N}`; слот должен существовать в расписании. Подробности — в [07-verification.md](../07-verification.md).

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/reservation/load/{id}` | Получить запись на занятие по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/reservation/list` | Получить список записей на занятия |
| [Создать](#create) | `POST` | `/api/public/reservation/update` | Создать запись на занятие |
| [Обновить](#update) | `POST` | `/api/public/reservation/update` | Обновить запись на занятие |
| [Удалить](#delete) | `POST` | `/api/public/reservation/delete` | Удалить записи на занятия |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/reservation/load/{id}`

_Получить запись на занятие по идентификатору_

Возвращает информацию о записи клиента на занятие по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор записи на занятие | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `id` | `number` | Идентификатор записи |
| `entity` | `string` | Тип сущности — reservation |
| `schedule` | `object` | Объект расписания (schedule) |
| `group` | `object` | Объект группового занятия (group), на которое оформлена запись |
| `hall` | `object` | Объект зала |
| `groupAccount` | `object` | Связанный групповой абонемент (groupAccount) |
| `target` | `object` | Целевой объект занятия (группа/преподаватель/зал) |
| `date` | `number` | Дата записи на занятие (Unix timestamp) |
| `minutes` | `number` | Время начала занятия в минутах от начала суток |
| `type` | `number` | Тип записи (0 - групповое, 1 - самостоятельное, 2 - набор в группу) |
| `source` | `number` | Код источника записи (0 - impulseCRM, 1 - виджет расписания, 2 - лист ожидания, 3 - мобильное приложение) |
| `sourceText` | `string` | Текстовое обозначение источника (например impulseCRM) |
| `clientUnsubscribe` | `boolean` | Признак отписки клиента от уведомлений |
| `burned` | `boolean` | Признак сгорания посещения в абонементе |
| `client` | `object` | Объект клиента, на которого оформлена запись |
| `updated` | `number` | Время последнего обновления (Unix timestamp) |
| `updater` | `object` | Пользователь, внёсший последнее изменение |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `creator` | `object` | Пользователь, создавший запись (user) |
| `branch` | `object` | Объект филиала (branch) |
| `deleted` | `boolean` | Признак удаления |
| `archived` | `boolean` | Признак архивирования |
| `annotation` | `string` | Примечание к записи |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/reservation/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/reservation/list`

_Получить список записей на занятия_

Возвращает массив записей из CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `fields` | `array` | — | Какие колонки выгружать. Если не указать, то все записи выгрузятся. | `["id", "entity", "client", "date"]` |
| `limit` | `number` | — | Сколько записей выгружать. Если не указать, то все записи выгрузятся | `20` |
| `page` | `number` | — | Какую страницу выборки выгружать | `1` |
| `sort` | `object` | — | Сортировка: имя поля — порядок asc или desc (например date, minutes, client) | `{"date": "asc", "minutes": "asc", "client": "asc"}` |
| `filters` | `object` | — | Фильтры по полям записи: например date — дата занятий (Unix timestamp начала дня) | `{"date": 1775174400}` |
| `columns` | `object` | — | Фильтрация по значению (например по периоду создания) | `[]` |

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
| `items` | `array` | Массив записей на занятие (описание зависит от параметров fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/reservation/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/reservation/update`

_Создать запись на занятие_

Создаёт новую запись на занятие в CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `type` | `number` | да | Тип записи (0 — групповое, 1 — самостоятельное, 2 — набор в группу) | `0` |
| `source` | `number` | да | Источник записи (0 — impulseCRM, 1 — виджет расписания, 2 — лист ожидания, 3 — мобильное приложение) | `0` |
| `time` | `array` | да | Массив слотов записи. Каждый элемент: date (Unix timestamp даты занятия), minutes (время начала в минутах от полуночи), group — группа (entity и id), schedule — слот расписания: id слота и вложенный group с id группы | `[{"date": 1775865600, "minutes": 960, "type": 0, "source": 0, "group": {"entity": "grou…` |
| `client` | `object` | да | Клиент, на которого оформляется запись (объект, можно передать только id) | `{"id": 3}` |

Пример тела запроса:

```json
{
  "type": 0,
  "source": 0,
  "time": [
    {
      "date": 1775865600,
      "minutes": 960,
      "type": 0,
      "source": 0,
      "group": {
        "entity": "group",
        "id": 3
      },
      "schedule": {
        "id": 48,
        "entity": "schedule",
        "group": {
          "id": 3
        }
      }
    }
  ],
  "client": {
    "id": 3
  }
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `count` | `number` | Количество созданных записей |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/reservation/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"type": 0, "source": 0, "time": [{"date": 1775865600, "minutes": 960, "type": 0, "source": 0, "group": {"entity": "group", "id": 3}, "schedule": {"id": 48, "entity": "schedule", "group": {"id": 3}}}], "client": {"id": 3}}'
```

<a id="update"></a>
## Обновить

`POST /api/public/reservation/update`

_Обновить запись на занятие_

Обновляет запись на занятие в CRM.

Тот же endpoint, что и при создании; для обновления передайте в теле id существующей записи.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор записи | `143` |
| `type` | `number` | да | Тип записи (0 — групповое, 1 — самостоятельное, 2 — набор в группу) | `0` |
| `source` | `number` | да | Источник записи (0 — impulseCRM, 1 — виджет расписания, 2 — лист ожидания, 3 — мобильное приложение) | `0` |
| `time` | `array` | да | Массив слотов записи. Каждый элемент: date (Unix timestamp даты занятия), minutes (время начала в минутах от полуночи), group — группа (entity и id), schedule — слот расписания: id слота и вложенный group с id группы | `[{"date": 1775865600, "minutes": 960, "type": 0, "source": 0, "group": {"entity": "grou…` |
| `client` | `object` | да | Клиент, на которого оформляется запись (объект, можно передать только id) | `{"id": 3}` |

Пример тела запроса:

```json
{
  "id": 143,
  "type": 0,
  "source": 0,
  "time": [
    {
      "date": 1775865600,
      "minutes": 960,
      "type": 0,
      "source": 0,
      "group": {
        "entity": "group",
        "id": 3
      },
      "schedule": {
        "id": 48,
        "entity": "schedule",
        "group": {
          "id": 3
        }
      }
    }
  ],
  "client": {
    "id": 3
  }
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `count` | `number` | Количество созданных записей |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/reservation/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 143, "type": 0, "source": 0, "time": [{"date": 1775865600, "minutes": 960, "type": 0, "source": 0, "group": {"entity": "group", "id": 3}, "schedule": {"id": 48, "entity": "schedule", "group": {"id": 3}}}], "client": {"id": 3}}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/reservation/delete`

_Удалить записи на занятия_

Удаляет одну или несколько записей в CRM.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор записи в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/reservation/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
