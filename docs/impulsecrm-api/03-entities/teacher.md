# Преподаватель — сущность `teacher`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Преподаватель: контакты, фото, описание, параметры расчёта зарплаты.

> **Проверено на демо-контуре 2026-11-19.** Для создания нужны `wageOptions` и `options` (иначе NOT NULL → 500). Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `teacher`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/teacher/load/{id}` | Получить преподавателя по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/teacher/list` | Получить список преподавателей |
| [Создать](#create) | `POST` | `/api/public/teacher/update` | Создать преподавателя |
| [Обновить](#update) | `POST` | `/api/public/teacher/update` | Обновить преподавателя |
| [Удалить](#delete) | `POST` | `/api/public/teacher/delete` | Удалить преподавателей |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/teacher/load/{id}`

_Получить преподавателя по идентификатору_

Возвращает информацию о преподавателе по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор преподавателя | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `inn` | `string` | ИНН преподавателя |
| `post` | `string` | Должность преподавателя |
| `rating` | `number` | Рейтинг преподавателя по 5-бальной шкале |
| `reviews` | `number` | Количество отзывов о преподавателе |
| `ownWage` | `boolean` | Признак индивидуального расчета зарплаты |
| `wageOptions` | `object` | Объект настроек индивидуального расчета зарплаты преподавателя |
| `wageAdd` | `number` | Надбавка к зарплате преподавателя (в процентах или в валюте) |
| `wageAddCurrency` | `boolean` | Доплата в валюте, иначе в процентах |
| `options` | `object` | Объект настроек преподавателя |
| `birthDate` | `number` | Дата рождения (UTC) |
| `man` | `boolean` | Пол: true — муж., false — жен. |
| `phone` | `array` | Массив телефонов преподавателя |
| `email` | `string` | Электронная почта |
| `socialPage` | `string` | Страница соц. сети |
| `address` | `string` | Адрес проживания |
| `age` | `number` | Возраст преподавателя |
| `lastName` | `string` | Фамилия преподавателя |
| `name` | `string` | Имя преподавателя |
| `middleName` | `string` | Отчество преподавателя |
| `updated` | `number` | Время последнего обновления, (Unix timestamp) |
| `updater` | `object` | Пользователь, внесший последнее изменение |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `creator` | `object` | Пользователь, создавший преподавателя |
| `branch` | `object` | Объект филиала преподавателя |
| `id` | `number` | Идентификатор преподавателя |
| `entity` | `string` | Тип сущности, для преподавателя — teacher |
| `deleted` | `boolean` | Признак удаления преподавателя |
| `archived` | `boolean` | Признак архивирования преподавателя |
| `annotation` | `string` | Примечание |
| `fotoFileName` | `string` | Имя файла фотографии преподавателя |
| `fotoUrl` | `string` | URL фото преподавателя |
| `fotoThumbUrl` | `string` | URL превью фото преподавателя |
| `description` | `string` | Описание преподавателя |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/teacher/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/teacher/list`

_Получить список преподавателей_

Возвращает массив преподавателей из CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `fields` | `array` | — | Какие колонки выгружать. Если не указать, то все записи выгрузятся. | `["name", "id"]` |
| `limit` | `number` | — | Сколько записей выгружать. Если не указать, то все записи выгрузятся | `10` |
| `page` | `number` | — | Какую страницу выборки выгружать | `1` |
| `sort` | `object` | — | По какой колонке сортировать | `{"created": "desc"}` |
| `filters` | `object` | — | Фильтрация по свойствам | `{"branch": {"id": 1}}` |
| `columns` | `object` | — | Фильтрация значению (например по периоду создания) | `{"created": {"from": 1767214800, "to": 1798750800}}` |

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
| `total` | `number` | Общее количество преподавателей в выборке |
| `items` | `array` | Массив с описанием преподавателей (описание зависит от параметров fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/teacher/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/teacher/update`

_Создать преподавателя_

Создает нового преподавателя в CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | да | Тип сущности, для преподавателя — teacher | `"teacher"` |
| `lastName` | `string` | да | Фамилия преподавателя | `"Тестовый"` |
| `name` | `string` | да | Имя преподавателя | `"Преподаватель"` |
| `middleName` | `string` | — | Отчество преподавателя | `null` |
| `birthDate` | `number` | — | Дата рождения (UTC) | `null` |
| `inn` | `string` | — | ИНН преподавателя | `null` |
| `man` | `boolean` | — | Пол: true — муж., false — жен. | `null` |
| `phone` | `array` | — | Массив телефонов преподавателя | `null` |
| `email` | `string` | — | Электронная почта | `null` |
| `socialPage` | `string` | — | Страница соц. сети | `null` |
| `address` | `string` | — | Адрес проживания | `null` |
| `fotoUrl` | `string` | — | URL фото преподавателя | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `description` | `string` | — | Описание преподавателя | `null` |
| `post` | `string` | — | Должность преподавателя | `null` |
| `rating` | `number` | — | Рейтинг преподавателя по 5-бальной шкале | `null` |
| `reviews` | `number` | — | Количество отзывов о преподавателе | `null` |
| `ownWage` | `boolean` | — | Признак индивидуального расчета зарплаты | `null` |
| `wageOptions` | `object` | — | Объект настроек индивидуального расчета зарплаты преподавателя | `[]` |
| `wageAdd` | `number` | — | Надбавка к зарплате преподавателя (в процентах или в валюте) | `null` |
| `wageAddCurrency` | `boolean` | — | Доплата в валюте, иначе в процентах | `null` |
| `options` | `array` | — | Массив настроек преподавателя | `[]` |
| `annotation` | `string` | — | Примечание | `null` |

Пример тела запроса:

```json
{
  "entity": "teacher",
  "lastName": "Тестовый",
  "name": "Преподаватель",
  "wageOptions": [],
  "options": []
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного преподавателя |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/teacher/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "teacher", "lastName": "Тестовый", "name": "Преподаватель", "wageOptions": [], "options": []}'
```

<a id="update"></a>
## Обновить

`POST /api/public/teacher/update`

_Обновить преподавателя_

Обновляет информацию о преподавателе в CRM.

Обратите внимание, что endpoint такой же, как и при создании преподавателя, но для обновления необходимо передать в теле идентификатор существующего преподавателя (id)

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор преподавателя | `1` |
| `entity` | `string` | да | Тип сущности, для преподавателя — teacher | `"teacher"` |
| `lastName` | `string` | да | Фамилия преподавателя | `"Тестовый"` |
| `name` | `string` | да | Имя преподавателя | `"Преподаватель"` |
| `middleName` | `string` | — | Отчество преподавателя | `null` |
| `birthDate` | `number` | — | Дата рождения (UTC) | `null` |
| `inn` | `string` | — | ИНН преподавателя | `null` |
| `man` | `boolean` | — | Пол: true — муж., false — жен. | `null` |
| `phone` | `array` | — | Массив телефонов преподавателя | `null` |
| `email` | `string` | — | Электронная почта | `null` |
| `socialPage` | `string` | — | Страница соц. сети | `null` |
| `address` | `string` | — | Адрес проживания | `null` |
| `fotoUrl` | `string` | — | URL фото преподавателя | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `description` | `string` | — | Описание преподавателя | `null` |
| `post` | `string` | — | Должность преподавателя | `null` |
| `rating` | `number` | — | Рейтинг преподавателя по 5-бальной шкале | `null` |
| `reviews` | `number` | — | Количество отзывов о преподавателе | `null` |
| `ownWage` | `boolean` | — | Признак индивидуального расчета зарплаты | `null` |
| `wageOptions` | `object` | — | Объект настроек индивидуального расчета зарплаты преподавателя | `[]` |
| `wageAdd` | `number` | — | Надбавка к зарплате преподавателя (в процентах или в валюте) | `null` |
| `wageAddCurrency` | `boolean` | — | Доплата в валюте, иначе в процентах | `null` |
| `options` | `array` | — | Массив настроек преподавателя | `[]` |
| `annotation` | `string` | — | Примечание | `null` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "teacher",
  "lastName": "Тестовый",
  "name": "Преподаватель",
  "wageOptions": [],
  "options": []
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного преподавателя |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/teacher/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "teacher", "lastName": "Тестовый", "name": "Преподаватель", "wageOptions": [], "options": []}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/teacher/delete`

_Удалить преподавателей_

Удаляет преподавателей в CRM.

Позволяет удалить как одного преподавателя, так и несколько.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор преподавателя в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/teacher/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
