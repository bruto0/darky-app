# Пользователь — сущность `user`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Пользователь CRM (сотрудник): логин, роль, филиал, права, API-токен.

> **Проверено на демо-контуре 2026-11-19.** Создание запрещено правами демо-пользователя: 500 «Текущий пользователь не может редактировать пользователей.» Подробности — в [07-verification.md](../07-verification.md).

**Значение поля `entity`:** `user`

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Получить по идентификатору](#get) | `GET` | `/api/public/user/load/{id}` | Получить пользователя по идентификатору |
| [Список (выборка)](#list) | `POST` | `/api/public/user/list` | Получить список пользователей |
| [Создать](#create) | `POST` | `/api/public/user/update` | Создать пользователя |
| [Обновить](#update) | `POST` | `/api/public/user/update` | Обновить пользователя |
| [Удалить](#delete) | `POST` | `/api/public/user/delete` | Удалить пользователей |

<a id="get"></a>
## Получить по идентификатору

`GET /api/public/user/load/{id}`

_Получить пользователя по идентификатору_

Возвращает информацию о пользователе по идентификатору из CRM.

### Параметры пути

| Параметр | Тип | Описание | Пример |
|---|---|---|---|
| `id` | `number` | Идентификатор пользователя | `1` |

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `username` | `string` | Логин пользователя |
| `inn` | `string` | ИНН пользователя |
| `card` | `string` |  Номер карты пользователя |
| `sip` | `string` | SIP |
| `ownWage` | `boolean` | Признак индивидуального расчета зарплаты |
| `wageOptions` | `object` | Объект настроек индивидуального расчета зарплаты пользователя |
| `settings` | `object` | Объект настроек пользователя |
| `password` | `string` | Хеш пароля |
| `apiToken` | `string` | API токен пользователя |
| `role` | `object` | Объект роли пользователя |
| `teacher` | `object` | Объект преподавателя, за которым закреплен пользователь |
| `branch` | `object` | Объект основного филиала пользователя |
| `payBox` | `object` | Объект кассы, на которой последний раз работал или работает пользователь |
| `filterBranches` | `array` | Список идентификаторов филиалов, которые выбраны у пользователя для просмотра |
| `filterUsers` | `array` | Список идентификаторов пользователей для фильтрации при просмотре повестки дня по пользователю |
| `lastName` | `string` | Фамилия пользователя |
| `name` | `string` | Имя пользователя |
| `middleName` | `string` | Отчество пользователя |
| `fotoFileName` | `string` | Имя файла фотографии пользователя |
| `fotoUrl` | `string` | URL фото пользователя |
| `fotoThumbUrl` | `string` | URL превью фото пользователя |
| `id` | `number` | Идентификатор пользователя |
| `entity` | `string` | Тип сущности, для пользователя — user |
| `created` | `number` | Время создания записи (Unix timestamp) |
| `deleted` | `boolean` | Признак удаления пользователя |
| `archived` | `boolean` | Признак архивирования пользователя |

### Пример вызова

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/user/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

<a id="list"></a>
## Список (выборка)

`POST /api/public/user/list`

_Получить список пользователей_

Возвращает массив пользователей из CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `fields` | `array` | — | Какие колонки выгружать. Если не указать, то все записи выгрузятся. | `["username", "id"]` |
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
| `total` | `number` | Общее количество пользователей в выборке |
| `items` | `array` | Массив с описанием пользователей (описание зависит от параметров fields) |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/user/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```

<a id="create"></a>
## Создать

`POST /api/public/user/update`

_Создать пользователя_

Создает нового пользователя в CRM.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `entity` | `string` | да | Тип сущности, для пользователя — user | `"user"` |
| `username` | `string` | да | Логин пользователя | `"Тестовый"` |
| `newPassword` | `string` | да | Новый пароль пользователя (в открытом виде) | `"12345"` |
| `role` | `object` | да | Роль пользователя (объект, можно передать только id) | `{"id": 7}` |
| `branch` | `object` | да | Филиал пользователя (объект, можно передать только id) | `{"id": 1}` |
| `teacher` | `object` | — | Преподаватель, связанный с пользователем (объект, можно передать только id) | `null` |
| `lastName` | `string` | да | Фамилия пользователя | `"Тест"` |
| `name` | `string` | да | Имя пользователя | `"Тест"` |
| `middleName` | `string` | — | Отчество пользователя | `"Тест"` |
| `apiToken` | `string` | — | API токен пользователя | `null` |
| `inn` | `string` | — | ИНН пользователя | `null` |
| `card` | `string` | — | Номер карты пользователя | `null` |
| `phone` | `string` | — | Телефон пользователя | `null` |
| `email` | `string` | — | Email пользователя | `null` |
| `sip` | `string` | — | SIP | `null` |
| `sideBarImage` | `number` | — | Идентификатор изображения сайдбара | `0` |
| `fotoUrl` | `string` | — | URL фото пользователя | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `ownWage` | `boolean` | — | Признак индивидуального расчета зарплаты (или null) | `null` |
| `wageOptions` | `array` | — | Массив настроек индивидуального расчета зарплаты пользователя | `[]` |
| `settings` | `object` | — | Объект настроек пользователя | `[]` |

Пример тела запроса:

```json
{
  "entity": "user",
  "username": "Тестовый",
  "newPassword": "12345",
  "role": {
    "id": 7
  },
  "branch": {
    "id": 1
  },
  "lastName": "Тест",
  "name": "Тест",
  "middleName": "Тест",
  "sideBarImage": 0,
  "wageOptions": [],
  "settings": []
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного пользователя |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/user/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"entity": "user", "username": "Тестовый", "newPassword": "12345", "role": {"id": 7}, "branch": {"id": 1}, "lastName": "Тест", "name": "Тест", "middleName": "Тест", "sideBarImage": 0, "wageOptions": [], "settings": []}'
```

<a id="update"></a>
## Обновить

`POST /api/public/user/update`

_Обновить пользователя_

Обновляет информацию о пользователе в CRM.

Обратите внимание, что endpoint такой же, как и при создании пользователя, но для обновления необходимо передать в теле идентификатор существующего пользователя (id)

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `id` | `number` | да | Идентификатор пользователя | `1` |
| `entity` | `string` | да | Тип сущности, для пользователя — user | `"user"` |
| `username` | `string` | да | Логин пользователя | `"Тестовый"` |
| `newPassword` | `string` | да | Новый пароль пользователя (в открытом виде) | `"12345"` |
| `role` | `object` | да | Роль пользователя (объект, можно передать только id) | `{"id": 7}` |
| `branch` | `object` | да | Филиал пользователя (объект, можно передать только id) | `{"id": 1}` |
| `teacher` | `object` | — | Преподаватель, связанный с пользователем (объект, можно передать только id) | `null` |
| `lastName` | `string` | да | Фамилия пользователя | `"Тест"` |
| `name` | `string` | да | Имя пользователя | `"Тест"` |
| `middleName` | `string` | — | Отчество пользователя | `"Тест"` |
| `apiToken` | `string` | — | API токен пользователя | `null` |
| `inn` | `string` | — | ИНН пользователя | `null` |
| `card` | `string` | — | Номер карты пользователя | `null` |
| `phone` | `string` | — | Телефон пользователя | `null` |
| `email` | `string` | — | Email пользователя | `null` |
| `sip` | `string` | — | SIP | `null` |
| `sideBarImage` | `number` | — | Идентификатор изображения сайдбара | `0` |
| `fotoUrl` | `string` | — | URL фото пользователя | `null` |
| `fotoBody` | `string` | — | Данные фото (fotoBody) | `null` |
| `ownWage` | `boolean` | — | Признак индивидуального расчета зарплаты (или null) | `null` |
| `wageOptions` | `array` | — | Массив настроек индивидуального расчета зарплаты пользователя | `[]` |
| `settings` | `object` | — | Объект настроек пользователя | `[]` |

Пример тела запроса:

```json
{
  "id": 1,
  "entity": "user",
  "username": "Тестовый",
  "newPassword": "12345",
  "role": {
    "id": 7
  },
  "branch": {
    "id": 1
  },
  "lastName": "Тест",
  "name": "Тест",
  "middleName": "Тест",
  "sideBarImage": 0,
  "wageOptions": [],
  "settings": []
}
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |
| `id` | `number` | Идентификатор созданного пользователя |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/user/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "entity": "user", "username": "Тестовый", "newPassword": "12345", "role": {"id": 7}, "branch": {"id": 1}, "lastName": "Тест", "name": "Тест", "middleName": "Тест", "sideBarImage": 0, "wageOptions": [], "settings": []}'
```

<a id="delete"></a>
## Удалить

`POST /api/public/user/delete`

_Удалить пользователей_

Удаляет пользователей в CRM.

Позволяет удалить как одного пользователя, так и несколько.

### Тело запроса

Тело — JSON-массив идентификаторов: Идентификатор пользователя в корневом массиве тела запроса. Можно передать один или несколько id за один запрос.

```json
[1]
```

### Ответ

| Поле | Тип | Описание |
|---|---|---|
| `success` | `boolean` | Статус операции: true — успешно, false — ошибка |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/user/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[1]'
```
