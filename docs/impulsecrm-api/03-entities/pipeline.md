# Воронка — сущность `pipeline`

[← Оглавление](../README.md) · [Индекс сущностей](README.md)

Воронка продаж и её статусы (используется в поле `status` клиента). Только чтение.

> **Проверено на демо-контуре 2026-11-19.** В документации только `list`, но CRUD работает; для создания нужны `number`, `smartSorting`, `triggers`. Подробности — в [07-verification.md](../07-verification.md).

## Действия

| Действие | Метод | Путь | Описание |
|---|---|---|---|
| [Список (выборка)](#list) | `POST` | `/api/public/pipeline/list` | Получить список воронок |

<a id="list"></a>
## Список (выборка)

`POST /api/public/pipeline/list`

_Получить список воронок_

Один элемент массива items содержит: number, smartSorting, triggers, id, entity, created, deleted, archived, name.

### Тело запроса

| Поле | Тип | Обязательное | Описание | Пример |
|---|---|---|---|---|
| `fields` | `array` | — | Какие колонки выгружать. Если не указать, то все записи выгрузятся. | `["id", "number", "name", "entity"]` |
| `limit` | `number` | — | Сколько записей выгружать за одну страницу | `10` |
| `page` | `number` | — | Номер страницы (начиная с 1) | `1` |
| `sort` | `object` | — | Сортировка | `{"created": "desc"}` |
| `filters` | `object` | — | Фильтрация по свойствам | `[]` |
| `columns` | `object` | — | Фильтрация по значению полей в уже полученной выборке | `[]` |

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
| `total` | `number` | Общее количество воронок в выборке |
| `items` | `array` | Массив воронок. Один элемент обычно содержит: number, smartSorting, triggers, id, entity, created, deleted, archived, name. |

### Пример вызова

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/pipeline/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}}'
```
