# impulseCRM API — справочник запросов

Полное описание HTTP-интерфейса impulseCRM: 23 сущности, 103 эндпойнта, все параметры
запросов и полей ответов. Справочник собран из официальной документации
<https://tech.impulsecrm.ru/api/> и предназначен для того, чтобы по запросу создавать,
читать, изменять и удалять как отдельные записи, так и группы записей (выборки, пакетные
операции).

- **Базовый URL:** адрес вашей CRM, например `https://demo.impulsecrm.ru`
- **Префикс API:** `/api/public`
- **Авторизация:** `Authorization: Basic <API_KEY>`
- **Формат:** JSON, UTF-8; даты — Unix timestamp в секундах (UTC)

> `https://tech.impulsecrm.ru/api/` — это **страница документации** (одностраничное
> приложение), а не сам API. Запросы вида `https://tech.impulsecrm.ru/api/public/...`
> возвращают 404: методы API работают только на домене вашей CRM. Подробнее —
> [01-connection.md](01-connection.md#where).

## Быстрый старт

```bash
# 1. Адрес CRM и ключ (ключ: профиль → «Настройка API» → «Обновить ключ»)
export IMPULSE_BASE_URL="https://demo.impulsecrm.ru"
export IMPULSE_API_KEY="ваш-ключ"

# 2. Проверка доступа: получить филиал с id=1
curl -s -g "$IMPULSE_BASE_URL/api/public/branch/load/1" \
  -H "Authorization: Basic $IMPULSE_API_KEY"

# 3. Первые 10 клиентов, свежие сверху
curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10, "page": 1, "sort": {"created": "desc"}, "fields": ["id", "name", "phone"]}'
```

Или через прилагаемый CLI (без зависимостей, только стандартная библиотека Python):

```bash
python tools/impulse_api.py ping
python tools/impulse_api.py list client --body '{"limit": 5, "fields": ["id", "name"]}'
python tools/impulse_api.py get client 1
```

> **PowerShell на Windows** съедает кавычки при передаче JSON в аргументах. Либо
> экранируйте их: `--body '{\"limit\": 5}'`, либо передавайте тело файлом:
> `--body @body.json`.

## Оглавление

| Файл | Что внутри |
|---|---|
| [01-connection.md](01-connection.md) | Базовый URL, API-ключ, заголовки, коды ответов и ошибки, форматы данных, лимиты |
| [02-actions.md](02-actions.md) | Пять базовых действий, устройство `list`, фильтры `filters`/`columns`, постраничная выдача, массовые операции (группы записей) |
| [03-entities/README.md](03-entities/README.md) | Индекс 23 сущностей: ключ, значение `entity`, набор действий, ссылка на файл |
| [03-entities/client.md](03-entities/client.md) | Клиент: все запросы и поля (эталонный формат страницы) |
| [03-entities/ancestor.md](03-entities/ancestor.md) | Родитель клиента |
| [03-entities/informer.md](03-entities/informer.md) | Источник (только чтение) |
| [03-entities/pipeline.md](03-entities/pipeline.md) | Воронка (только чтение) |
| [03-entities/branch.md](03-entities/branch.md) | Филиал |
| [03-entities/hall.md](03-entities/hall.md) | Зал |
| [03-entities/style.md](03-entities/style.md) | Направление |
| [03-entities/teacher.md](03-entities/teacher.md) | Преподаватель |
| [03-entities/user.md](03-entities/user.md) | Пользователь CRM |
| [03-entities/group.md](03-entities/group.md) | Группа |
| [03-entities/schedule.md](03-entities/schedule.md) | Занятие в расписании |
| [03-entities/reservation.md](03-entities/reservation.md) | Запись на занятие |
| [03-entities/visit.md](03-entities/visit.md) | Посещение по абонементу (только чтение/удаление) |
| [03-entities/deposit.md](03-entities/deposit.md) | Операции по депозиту: пополнение, списание, история |
| [03-entities/product.md](03-entities/product.md) | Продажа товара |
| [03-entities/group_account.md](03-entities/group_account.md) | Групповой абонемент |
| [03-entities/individual_account.md](03-entities/individual_account.md) | Индивидуальный абонемент |
| [03-entities/self_account.md](03-entities/self_account.md) | Самостоятельный абонемент |
| [03-entities/rent_account.md](03-entities/rent_account.md) | Абонемент на аренду |
| [03-entities/group_single.md](03-entities/group_single.md) | Разовое групповое занятие |
| [03-entities/individual_single.md](03-entities/individual_single.md) | Разовое индивидуальное занятие |
| [03-entities/self_single.md](03-entities/self_single.md) | Разовое самостоятельное занятие |
| [03-entities/rent_single.md](03-entities/rent_single.md) | Разовая аренда |
| [04-scenarios.md](04-scenarios.md) | Готовые сценарии: найти → создать → изменить → удалить, пакетные операции, типовые связки сущностей |
| [05-reference.md](05-reference.md) | Сводная таблица всех 103 эндпойнтов (метод, путь, назначение) |
| [06-troubleshooting.md](06-troubleshooting.md) | Частые ошибки: 401, 404, «пустой» список, фильтры не применяются, CORS |
| [07-verification.md](07-verification.md) | **Отчёт о живой проверке** на демо-контуре: что работает, минимальные тела создания, 16 расхождений с документацией |
| [verified.json](verified.json) | Машиночитаемые результаты проверки: статусы действий по сущностям, поведение фильтров и ошибок |
| [catalog.json](catalog.json) | Машиночитаемый каталог (все эндпойнты и поля) для скриптов и агентов |
| [tools/impulse_api.py](tools/impulse_api.py) | CLI-клиент: `ping`, `list`, `get`, `create`, `update`, `delete`, `deposit-input`, `deposit-output`, `call` |
| [tools/verify_live.py](tools/verify_live.py) | Скрипт живой проверки по чек-листу (54 проверки, адрес и ключ — из переменных окружения) |
| [tools/build_docs.py](tools/build_docs.py) | Генератор страниц `03-entities/` и `05-reference.md` из исходного JSON |
| [_source/api_doc_ru.json](_source/api_doc_ru.json) | Исходный JSON документации, снятый с сайта (источник истины для перегенерации) |

## Как устроен API в двух словах

1. У каждой сущности есть **ключ** (`client`, `group_account`, …) — он входит в URL.
2. Почти у всех сущностей пять действий: `load` (чтение одной записи), `list` (чтение
   набора), `update` (создание и изменение — один и тот же URL, различаются наличием `id`),
   `delete` (удаление).
3. **Создание и изменение** — это `POST …/{сущность}/update`: без `id` в теле создаётся
   новая запись, с `id` — обновляется существующая.
4. **Удаление** — `POST …/{сущность}/delete` с JSON-массивом идентификаторов: одной
   операцией можно удалить несколько записей сразу. У `schedule` тело особое (объект
   `item` + `date`), у `deposit` — только одна операция за вызов, у `visit` нет создания.
   Удаление логическое: запись получает `deleted: true` и исчезает из `list`, но остаётся
   доступной через `load`.
5. **Выборки** — `POST …/{сущность}/list` с телом `{fields, limit, page, sort, filters,
   columns}`; минимум один параметр обязателен (пустой `{}` → 500). Фильтры работают
   частично — рабочий минимум в [02-actions.md](02-actions.md#list) и
   [07-verification.md](07-verification.md).

## Как пользоваться справочником

**Человеку.** Начните с [02-actions.md](02-actions.md) — там общая механика. Дальше
открывайте страницу нужной сущности: сверху таблица действий, ниже — для каждого действия
параметры пути, таблица полей тела запроса (с признаком «Обязательное»), таблица полей
ответа и готовый `curl`.

**Агенту (автоматизация по запросу).** Порядок действий:

1. Определить сущность по [индексу](03-entities/README.md) (например, «абонемент» →
   `group_account`).
2. Открыть страницу сущности, взять оттуда путь и обязательные поля.
3. Найти нужные записи через `list` с `filters`/`columns` (раздел
   [«Действие list»](02-actions.md#list)) — так получаются `id` для чтения, изменения и
   удаления.
4. Выполнить `load` / `update` / `delete`; проверить ответ (`{"success": true}`), при
   ошибке — [06-troubleshooting.md](06-troubleshooting.md).
5. Для группы записей — один `delete` с массивом `id`; для массового создания — цикл
   `update` (пакетного создания в API нет).

## Статус и происхождение данных

- Справочник собран **2026-11-18** из JSON, который отдаёт страница документации:
  `GET https://tech.impulsecrm.ru/api/public/api_doc/load/ru` (и `…/en` для английской
  версии). Исходный файл сохранён в `_source/api_doc_ru.json`.
- Страницы `03-entities/*.md` и `05-reference.md` **сгенерированы** из этого JSON
  скриптом [tools/build_docs.py](tools/build_docs.py); ручные правки в них затрутся при
  перегенерации — правьте генератор или исходный JSON.
- Описания полей приведены дословно, включая опечатки источника (например, «Возвращет»,
  «масиив»): так их проще сверять с сайтом.
- На живом API проверено: запрос без ключа к `…/api/public/branch/load/1` возвращает
  `401 {"message":"Требуется аутентификация"}`; несуществующий путь на домене
  документации возвращает 404. Остальные примеры ответов взяты из документации.
- **Полная живая проверка — 2026-11-19** на `https://demo.impulsecrm.ru` (см.
  [07-verification.md](07-verification.md)): работают все 23 `list`, 19 `load`,
  создание/изменение/удаление; найдены расхождения (пустой `list` → 500, частичное
  обновление, логическое удаление, неработающие `not`/`empty`, обязательные «технические»
  поля). У `informer` и `pipeline` фактически есть `load`/`update`/`delete`, которых нет в
  документации, — итого не 103, а 109 эндпойнтов.
