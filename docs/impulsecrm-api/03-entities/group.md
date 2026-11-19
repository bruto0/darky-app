# Группа — сущность `group`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Группа: направление, преподаватели, вместимость, статус, показ в виджете.

> **Проверено на демо-контуре 2026-11-19.** Для создания нужны `status` и `*WageOptions` (иначе NOT NULL → 500). Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `group`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/group/load/{id}` | Получить группу по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/group/list` | Получить список групп |
| [Создать](#create) | `POST` | `/api/public/group/update` | Создать группу |
| [Обновить](#update) | `POST` | `/api/public/group/update` | Обновить группу |
| [Удалить](#delete) | `POST` | `/api/public/group/delete` | Удалить группы |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/group/load/{id}`

_Получить группу по идентификатору_

Возвращает информацию о групповом занятии по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор группы | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `id` | `number` | Идентификатор группы |
| `entity` | `string` | Тип сущности — group |
| `age` | `string` | Возрастная метка группы (например «7+») |
| `level` | `string` | Уровень группы |
| `number` | `string` | Номер группы |
| `placeCount` | `number` | Вместимость (количество мест) |
| `status` | `number` | Статус группы |
| `showInWidget` | `boolean` | Отображать группу в виджете расписания / мобильном приложении |
| `teacher1OwnWage` | `boolean` | Признак индивидуального расчета зарплаты первого преподавателя |
| `teacher1WageOptions` | `object` | Объект настроек индивидуального расчета зарплаты первого преподавателя |
| `teacher2OwnWage` | `boolean` | Признак индивидуального расчета зарплаты второго преподавателя |
| `teacher2WageOptions` | `object` | Объект настроек индивидуального расчета зарплаты второго преподавателя |
| `style` | `object` | Объект направления |
| `teacher1` | `object` | Объект первого преподавателя |
| `teacher2` | `object` | Объект второго преподавателя |
| `updated` | `number` | Время последнего обновления (Unix timestamp) |
| `updater` | `object` | Пользователь, внёсший последнее изменение |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `creator` | `object` | Пользователь, создавший группу (user) |
| `branch` | `object` | Объект филиала (branch) |
| `deleted` | `boolean` | Признак удаления |
| `archived` | `boolean` | Признак архивирования |
| `annotation` | `string` | Примечание к группе |
| `description` | `string` | Текстовое описание группы |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/group/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/group/list`

_Получить список групп_

Возвращает массив групп из CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `fields` | `array` | — | Какие колонки выгружать. Если не указать, то все записи выгрузятся. | `["id", "entity", "style"]` |
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
| `total` | `number` | Общее количество групп в выборке |
| `items` | `array` | Массив с описанием групп (описание зависит от параметров fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/group/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/group/update`

_Создать группу_

Создаёт новую группу в CRM.

При создании поле id в теле можно передать как null или не указывать.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | да | Тип сущности — group | `"group"` |
| `style` | `object` | да | Направление (объект, можно передать только id) | `{"id": 15}` |
| `age` | `string` | — | Возрастная метка группы | `"10"` |
| `level` | `string` | — | Уровень группы | `"1"` |
| `number` | `string` | — | Номер группы | `"2"` |
| `teacher1` | `object` | да | Первый преподаватель (объект, можно передать только id) | `{"id": 5}` |
| `teacher2` | `object` | — | Второй преподаватель (объект, можно передать только id) | `null` |
| `placeCount` | `number` | — | Вместимость (количество мест) | `"10"` |
| `webHeader` | `string` | — | Заголовок для веб-виджета | `"Название группы"` |
| `showInWidget` | `boolean` | — | Показывать группу в виджете расписания / мобильном приложении | `false` |
| `status` | `number` | — | Статус группы | `1` |
| `teacher1OwnWage` | `boolean` | — | Признак индивидуального расчета зарплаты первого преподавателя | `null` |
| `teacher1WageOptions` | `array` | — | Переопределение опций расчёта зарплаты первого преподавателя для группы | `[]` |
| `teacher2OwnWage` | `boolean` | — | Признак индивидуального расчета зарплаты второго преподавателя | `null` |
| `teacher2WageOptions` | `array` | — | Переопределение опций расчёта зарплаты второго преподавателя для группы | `[]` |
| `description` | `string` | — | Текстовое описание группы | `null` |
| `annotation` | `string` | — | Примечание | `null` |

Пример тела запроса:

```json
{
  "entity": "group",
  "style": {
    "id": 15
  },
  "age": "10",
  "level": "1",
  "number": "2",
  "teacher1": {
    "id": 5
  },
  "placeCount": "10",
  "webHeader": "Название группы",
  "showInWidget": false,
  "status": 1,
  "teacher1WageOptions": [],
  "teacher2WageOptions": []
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданной группы |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/group/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "group", "style": {"id": 15}, "age": "10", "level": "1", "number": "2", "teacher1": {"id": 5}, "placeCount": "10", "webHeader": "Название группы", "showInWidget": false, "status": 1, "teacher1WageOptions": [], "teacher2WageOptions": []}'
```

<a id="update"></a>
## Обновить

`POST /api/public/group/update`

_Обновить группу_

Обновляет информацию о группе в CRM.

Тот же endpoint, что и при создании; для обновления передайте в теле id существующей группы.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор группы | `1` |
| `entity` | `string` | да | Тип сущности — group | `"group"` |
| `style` | `object` | да | Направление (объект, можно передать только id) | `{"id": 15}` |
| `age` | `string` | — | Возрастная метка группы | `"10"` |
| `level` | `string` | — | Уровень группы | `"1"` |
| `number` | `string` | — | Номер группы | `"2"` |
| `teacher1` | `object` | да | Первый преподаватель (объект, можно передать только id) | `{"id": 5}` |
| `teacher2` | `object` | — | Второй преподаватель (объект, можно передать только id) | `null` |
| `placeCount` | `number` | — | Вместимость (количество мест) | `"10"` |
| `webHeader` | `string` | — | Заголовок для веб-виджета | `"Название группы"` |
| `showInWidget` | `boolean` | — | Показывать группу в виджете расписания / мобильном приложении | `false` |
| `status` | `number` | — | Статус группы | `1` |
| `teacher1OwnWage` | `boolean` | — | Признак индивидуального расчета зарплаты первого преподавателя | `null` |
| `teacher1WageOptions` | `array` | — | Переопределение опций расчёта зарплаты первого преподавателя для группы | `[]` |
| `teacher2OwnWage` | `boolean` | — | Признак индивидуального расчета зарплаты второго преподавателя | `null` |
| `teacher2WageOptions` | `array` | — | Переопределение опций расчёта зарплаты второго преподавателя для группы | `[]` |
| `description` | `string` | — | Текстовое описание группы | `null` |
| `annotation` | `string` | — | Примечание | `null` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "group",
  "style": {
    "id": 15
  },
  "age": "10",
  "level": "1",
  "number": "2",
  "teacher1": {
    "id": 5
  },
  "placeCount": "10",
  "webHeader": "Название группы",
  "showInWidget": false,
  "status": 1,
  "teacher1WageOptions": [],
  "teacher2WageOptions": []
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданной группы |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/group/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "group", "style": {"id": 15}, "age": "10", "level": "1", "number": "2", "teacher1": {"id": 5}, "placeCount": "10", "webHeader": "Название группы", "showInWidget": false, "status": 1, "teacher1WageOptions": [], "teacher2WageOptions": []}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/group/delete`

_Удалить группы_

Удаляет одну или несколько групп в CRM.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор группы в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/group/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
