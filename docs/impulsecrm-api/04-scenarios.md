# 04. Готовые сценарии

[← Действия](02-actions.md) · [Оглавление](README.md) · [Ошибки →](06-troubleshooting.md)

Ниже — рабочие последовательности вызовов для типовых задач. Все примеры используют
переменные:

```bash
export IMPULSE_BASE_URL="https://demo.impulsecrm.ru"
export IMPULSE_API_KEY="ваш-ключ"
```

Порядок «найти → проверить → изменить» безопаснее прямых изменений по угаданному `id`:
сначала получите запись через `list`/`load`, затем действуйте.

## 1. Найти клиента по телефону

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"fields": ["id", "name", "lastName", "phone", "deposit", "branch"],
       "limit": 10,
       "filters": {"phone": "79130000000"}}'
```

Если фильтр по телефону не находит запись (телефоны хранятся массивом), возьмите более
широкую выборку и отфильтруйте на своей стороне:

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"fields": ["id", "name", "phone"], "limit": 500, "sort": {"id": "asc"}}'
```

## 2. Прочитать клиента по id

```bash
curl -s -g "$IMPULSE_BASE_URL/api/public/client/load/42" \
  -H "Authorization: Basic $IMPULSE_API_KEY"
```

В ответе — полный объект: контакты, `deposit`, `bonus`, `status`, `branch`, `user`,
`parent1`/`parent2`, `tag`, `comment`, `task`, `document` и служебные `created`/`updated`.

## 3. Создать клиента

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "entity": "client",
    "lastName": "Петров",
    "name": "Иван",
    "middleName": "Сергеевич",
    "phone": ["79130000000"],
    "email": ["ivan@example.com"],
    "birthDate": 946684800,
    "man": true,
    "deposit": 0,
    "bonus": 0,
    "branch": {"id": 1},
    "informer": {"id": 1}
  }'
```

Ответ: `{"success": true, "id": 123, "updated": null}`. Сохраните `id` — он нужен для
записи на занятие, абонемента и депозита.

Обязательные поля: `name`, `deposit`, `bonus` (на демо-контуре без `deposit` и `bonus` —
`500`, потому что это NOT NULL колонки). `email`, `socialPage`, `address` — **массивы
строк**, а не строки. Связанные сущности (`branch`, `informer`, `status`, `user`, `level`,
`friend`, `parent1`, `parent2`) передаются объектом `{"id": N}`.

## 4. Изменить клиента

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 123,
    "entity": "client",
    "name": "Иван",
    "lastName": "Петров",
    "phone": ["79130000000"],
    "blacklist": true,
    "annotation": "Проверен менеджером"
  }'
```

Обновление **частичное**: достаточно `id` и изменяемых полей; остальные сохраняются
(проверено). Обязательные поля из документации передавать не нужно, если вы их не меняете.

## 5. Удалить клиента или группу клиентов

```bash
# один
curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" -d '[123]'

# несколько за один запрос
curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" -d '[123, 124, 125]'
```

Ответ: `{"success": true}`.

## 6. Создать группу

Сначала нужны `style` (направление) и `teacher` (преподаватель) — их `id` берутся из
`list`:

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/style/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" -d '{"fields": ["id", "name"]}'

curl -s -X POST "$IMPULSE_BASE_URL/api/public/group/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "entity": "group",
    "style": {"id": 15},
    "teacher1": {"id": 5},
    "number": "2",
    "age": "10",
    "level": "1",
    "placeCount": 10,
    "status": 1,
    "teacher1WageOptions": [],
    "teacher2WageOptions": [],
    "webHeader": "Дети 10-12 лет",
    "showInWidget": true
  }'
```

На демо без `status` и `*WageOptions` создание вернёт 500 (NOT NULL). Ответ:
`{"success": true, "id": N}`.

## 7. Поставить занятие в расписание

Групповое регулярное занятие (каждый вторник, 16:00–17:00):

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/schedule/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "hall": {"id": 6},
    "group": {"id": 11},
    "teacher1": {"id": 4},
    "regular": true,
    "day": 2,
    "dateBegin": 1775174400,
    "minutesBegin": 960,
    "minutesEnd": 1020,
    "type": 0,
    "color": "ffd966"
  }'
```

- `day`: `1` понедельник … `7` воскресенье; `minutesBegin/End` — минуты от полуночи;
- `type`: `0` групповое, `1` индивидуальное, `2` аренда;
- разовое занятие вместо `day`/`dateBegin` использует `date` (timestamp) и `regular: false`;
- если время занято, ответ будет `200` + `{"success": false, "message": "В указанное время
  уже есть занятие: …"}` — выбирайте свободный слот (проверено).

Удаление занятия — особое тело:

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/schedule/delete" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"item": {"id": 119, "entity": "schedule"}, "date": 1775174400}'
```

Если на занятие уже есть записи клиентов, вернётся `success: false` с просьбой сначала
отменить записи.

## 8. Записать клиента на занятие

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/reservation/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "type": 0,
    "source": 0,
    "client": {"id": 123},
    "time": [{
      "date": 1775865600,
      "minutes": 960,
      "type": 0,
      "source": 0,
      "group": {"entity": "group", "id": 11},
      "schedule": {"id": 48, "entity": "schedule", "group": {"id": 11}}
    }]
  }'
```

Ответ: `{"success": true, "count": 1}` — в `count` количество созданных записей. Массив
`time` позволяет записать клиента сразу на несколько слотов. Слот `schedule` должен
существовать в расписании, а клиент — быть доступным пользователю; иначе `500`.
Удаление записи — `POST …/reservation/delete` с массивом `id`; пока записи есть, удалить
само занятие из расписания нельзя.

## 9. Пополнить депозит и посмотреть историю

```bash
# пополнение
curl -s -X POST "$IMPULSE_BASE_URL/api/public/deposit/input" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sum": 100, "payment": 1, "debt": false, "client_id": 123, "annotation": "Наличные"}'

# списание
curl -s -X POST "$IMPULSE_BASE_URL/api/public/deposit/output" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sum": 50, "payment": 2, "client_id": 123, "annotation": "Оплата занятия"}'

# история операций клиента
curl -s -X POST "$IMPULSE_BASE_URL/api/public/deposit/list" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"filters": {"client_id": 123}, "sort": {"created": "desc"}, "limit": 20}'
```

`payment`: `1` — наличные, `2` — карта. Баланс после операции — в `client.deposit`.

## 10. Продать абонемент

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/group_account/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "entity": "groupAccount",
    "client": {"id": 123},
    "typeName": "Детский",
    "typeColor": "FFC300",
    "cost": 2000,
    "discount": 0,
    "discountCurrency": false,
    "trainings": 12,
    "days": 60,
    "beginDate": 1775001600,
    "number": 0,
    "paid": 2000,
    "payBox": {"id": 1},
    "shift": {"id": 149},
    "pays": [{"sum": 2000, "payment": 1, "date": null}]
  }'
```

На демо обязательны также `number`, `payBox`, `shift`, `pays` — без них `500`. Ответ:
`{"success": true, "id": N, "kkt": null}`.

Аналогично устроены `individual_account`, `self_account`, `rent_account` (различаются
набором связей: преподаватель/зал/группы). Список полей — на странице сущности.

## 11. Продать товар

```bash
curl -s -X POST "$IMPULSE_BASE_URL/api/public/product/update" \
  -H "Authorization: Basic $IMPULSE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "entity": "product",
    "client": {"id": 123},
    "items": [{"count": 1, "type": {"id": 1}, "certMonths": null, "cost": 70,
               "discount": null, "discountCurrency": false, "total": 70}],
    "payBox": {"id": 1},
    "shift": {"id": 149},
    "pays": [{"sum": 70, "payment": 1, "date": null}],
    "paid": 70
  }'
```

Ответ: `{"success": true, "id": [4], "kkt": null}` — `id` приходит **массивом**. Читать и
удалять нужно по элементу: `GET …/product/load/4`, `POST …/product/delete` с `[4]`.

## 12. Выгрузить всех клиентов постранично

```bash
page=1
while :; do
  body="{\"limit\": 100, \"page\": $page, \"sort\": {\"id\": \"asc\"}, \"fields\": [\"id\", \"name\", \"lastName\", \"phone\", \"email\", \"created\"]}"
  response=$(curl -s -X POST "$IMPULSE_BASE_URL/api/public/client/list" \
    -H "Authorization: Basic $IMPULSE_API_KEY" \
    -H "Content-Type: application/json" -d "$body")
  count=$(echo "$response" | python -c 'import json,sys; print(len(json.load(sys.stdin)["items"]))')
  echo "$response" >> clients.jsonl
  [ "$count" -lt 100 ] && break
  page=$((page+1))
done
```

## 13. Проверить права и справочники перед работой

```bash
# филиалы, направления, залы, преподаватели, воронки, источники
for entity in branch style hall teacher pipeline informer; do
  echo "== $entity"
  curl -s -X POST "$IMPULSE_BASE_URL/api/public/$entity/list" \
    -H "Authorization: Basic $IMPULSE_API_KEY" \
    -H "Content-Type: application/json" -d '{"limit": 5, "fields": ["id", "name"]}'
done
```

Эти `id` нужны как значения связей при создании клиентов, групп, расписания и абонементов.

## 14. Тот же набор через CLI

```bash
python tools/impulse_api.py ping
python tools/impulse_api.py list client --body '{"limit": 5, "filters": {"blacklist": true}}'
python tools/impulse_api.py get client 123
python tools/impulse_api.py create client --body '{"name": "Иван", "lastName": "Петров", "phone": ["79130000000"]}'
python tools/impulse_api.py update client 123 --body '{"name": "Иван", "annotation": "VIP"}'
python tools/impulse_api.py delete client 123 124 125
python tools/impulse_api.py deposit-input --body '{"sum": 100, "payment": 1, "debt": false, "client_id": 123}'
python tools/impulse_api.py call POST /api/public/group/list --body '{"fields": ["id", "number"]}'
```

CLI сам подставляет `entity`, `Authorization` и печатает ответ в JSON; при `--dry-run`
показывает запрос, не отправляя его.
