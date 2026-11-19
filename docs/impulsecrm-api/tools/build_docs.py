# -*- coding: utf-8 -*-
"""Генератор справочника по API impulseCRM.

Источник: https://tech.impulsecrm.ru/api/public/api_doc/load/ru (JSON, который
отдаёт страница документации https://tech.impulsecrm.ru/api/).

Запуск:
    python build_docs.py <путь к api_doc_ru.json> <каталог docs/impulsecrm-api>
"""

import json
import os
import re
import sys
import html as htmllib
from datetime import datetime, timezone

ACTION_ORDER = ["get", "list", "create", "update", "input", "output", "delete"]
ACTION_TITLES = {
    "get": "Получить по идентификатору",
    "list": "Список (выборка)",
    "create": "Создать",
    "update": "Обновить",
    "delete": "Удалить",
    "input": "Пополнить депозит",
    "output": "Списать с депозита",
}

ENTITY_NOTES = {
    "client": "Клиент CRM: контакты, документ, статус в воронке, депозит и бонусы, метки, комментарии, задачи, родители, ответственный пользователь.",
    "ancestor": "Родитель (законный представитель) клиента. Связан с клиентом через поля `parent1` / `parent2` сущности `client`.",
    "informer": "Источник, из которого пришёл клиент (используется в поле `informer` клиента). Только чтение.",
    "pipeline": "Воронка продаж и её статусы (используется в поле `status` клиента). Только чтение.",
    "deposit": "Операции по депозиту клиента: пополнение, списание, история. Отдельной карточки депозита нет — баланс хранится в клиенте (`client.deposit`).",
    "branch": "Филиал (студия/клуб).",
    "hall": "Зал, в котором проводятся занятия.",
    "product": "Продажа товара: позиции, касса, смена, оплаты.",
    "teacher": "Преподаватель: контакты, фото, описание, параметры расчёта зарплаты.",
    "user": "Пользователь CRM (сотрудник): логин, роль, филиал, права, API-токен.",
    "style": "Направление (вид занятий): название, описание, фото.",
    "group": "Группа: направление, преподаватели, вместимость, статус, показ в виджете.",
    "schedule": "Занятие в расписании: зал, группа/преподаватель/клиент, день недели или разовая дата, время, тип.",
    "group_account": "Групповой абонемент клиента.",
    "group_single": "Разовое групповое занятие (продажа/посещение без абонемента).",
    "individual_account": "Индивидуальный абонемент клиента.",
    "individual_single": "Разовое индивидуальное занятие.",
    "self_account": "Самостоятельный абонемент (самостоятельные тренировки).",
    "self_single": "Разовое самостоятельное занятие.",
    "rent_account": "Абонемент на аренду зала.",
    "rent_single": "Разовая аренда зала.",
    "visit": "Посещение по абонементу (факт списания занятия). Только чтение и удаление.",
    "reservation": "Запись клиента на занятие (в расписании).",
}

VERIFIED_NOTES = {
    "client": "Для создания на демо обязательны `deposit` и `bonus`; `email`, `socialPage`, `address` — массивы строк, не строки; `update` частичный; `delete` логический.",
    "ancestor": "Проверено: create/load/update/delete работают.",
    "informer": "В документации только `list`, но `load`, `update` (создание/изменение) и `delete` тоже работают.",
    "pipeline": "В документации только `list`, но CRUD работает; для создания нужны `number`, `smartSorting`, `triggers`.",
    "deposit": "`delete` принимает только одну операцию за вызов (>1 → 500 «Можно удалить только 1 операцию.»); удаление операции откатывает баланс.",
    "branch": "Для создания нужен `options` (иначе NOT NULL → 500).",
    "hall": "Для создания нужен `options` (иначе NOT NULL → 500).",
    "product": "`id` в ответе на создание приходит **массивом** (`\"id\": [3]`); `load` — по элементу массива.",
    "teacher": "Для создания нужны `wageOptions` и `options` (иначе NOT NULL → 500).",
    "user": "Создание запрещено правами демо-пользователя: 500 «Текущий пользователь не может редактировать пользователей.»",
    "style": "Самое простое тело создания: `entity` + `name`.",
    "group": "Для создания нужны `status` и `*WageOptions` (иначе NOT NULL → 500).",
    "schedule": "Создание в занятое время → 200 + `success: false` с текстом конфликта; `delete` — `{item, date}`; удаление логическое.",
    "group_account": "Для создания нужны `number`, `payBox`, `shift`, `pays`.",
    "individual_account": "Для создания нужны `number`, `payBox`, `shift`, `pays`.",
    "self_account": "Для создания нужны `number`, `payBox`, `shift`, `pays`.",
    "rent_account": "Для создания нужны `number`, `payBox`, `shift`, `pays`.",
    "group_single": "Для создания нужны `payBox`, `shift`, `pays`.",
    "individual_single": "Для создания нужны `payBox`, `shift`, `pays`.",
    "self_single": "Для создания нужны `payBox`, `shift`, `pays`.",
    "rent_single": "Для создания нужны `payBox`, `shift`, `pays`.",
    "visit": "`load` и `update` отсутствуют (404); запись создаётся системой при списании абонемента.",
    "reservation": "Ответ на создание: `{\"success\": true, \"count\": N}`; слот должен существовать в расписании.",
}

GROUP_ORDER = [
    ("Клиенты и контакты", ["client", "ancestor", "informer", "pipeline"]),
    ("Структура студии", ["branch", "hall", "style", "teacher", "user", "group"]),
    ("Расписание и записи", ["schedule", "reservation", "visit"]),
    ("Абонементы и разовые занятия", [
        "group_account", "individual_account", "self_account", "rent_account",
        "group_single", "individual_single", "self_single", "rent_single",
    ]),
    ("Деньги и товары", ["deposit", "product"]),
]


def clean_html(text):
    """HTML из документации -> читаемый текст с переводами строк."""
    if not text:
        return ""
    text = re.sub(r"<br\s*/?>", "\n", text, flags=re.I)
    text = re.sub(r"</p>", "\n\n", text, flags=re.I)
    text = re.sub(r"</div>", "\n", text, flags=re.I)
    text = re.sub(r"</tr>", "\n", text, flags=re.I)
    text = re.sub(r"</t[dh]>", " | ", text, flags=re.I)
    text = re.sub(r"<[^>]+>", "", text)
    text = htmllib.unescape(text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def text_of_body_lines(ep):
    """Осмысленный текст описания эндпойнта без служебных html-таблиц."""
    out = []
    for line in ep.get("content", {}).get("bodyLines", []):
        if "<table" in line:
            continue
        txt = clean_html(line)
        if not txt:
            continue
        if txt.startswith("Cущность ") or txt.startswith("Сущность "):
            continue
        out.append(txt)
    return "\n\n".join(out)


def html_table_to_md(line):
    """Первую HTML-таблицу в строке -> markdown-таблица."""
    rows = re.findall(r"<tr[^>]*>(.*?)</tr>", line, flags=re.S | re.I)
    result = []
    for i, row in enumerate(rows):
        cells = re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", row, flags=re.S | re.I)
        cells = [clean_html(c).replace("\n", " ").strip() for c in cells]
        if not cells:
            continue
        result.append("| " + " | ".join(cells) + " |")
        if i == 0:
            result.append("|" + "|".join(["---"] * len(cells)) + "|")
    return "\n".join(result)


def esc(value):
    return str(value).replace("|", "\\|").replace("\n", " ")


def type_str(field):
    t = field.get("type") or "any"
    return f"`{t}`"


def json_compact(value):
    return json.dumps(value, ensure_ascii=False, separators=(", ", ": "))


def example_cell(field):
    if "example" not in field:
        return ""
    value = field["example"]
    if value is None:
        return "`null`"
    s = json_compact(value)
    if len(s) > 90:
        s = s[:87] + "…"
    return f"`{s}`"


def fields_table(fields, with_required=False, show_example=True):
    if not fields:
        return "_Полей нет._"
    if with_required:
        head = "| Поле | Тип | Обязательное | Описание | Пример |\n|---|---|---|---|---|"
    elif show_example:
        head = "| Поле | Тип | Описание | Пример |\n|---|---|---|---|"
    else:
        head = "| Поле | Тип | Описание |\n|---|---|---|"
    lines = [head]
    for name, f in fields.items():
        if not isinstance(f, dict):
            continue
        req = "да" if f.get("required") else "—"
        desc = esc(f.get("description", ""))
        ex = example_cell(f)
        if with_required:
            lines.append(f"| `{name}` | {type_str(f)} | {req} | {desc} | {ex} |")
        elif show_example:
            lines.append(f"| `{name}` | {type_str(f)} | {desc} | {ex} |")
        else:
            lines.append(f"| `{name}` | {type_str(f)} | {desc} |")
    return "\n".join(lines)


PLACEHOLDERS = {
    "string": "string",
    "number": 0,
    "boolean": False,
    "array": [],
    "object": {},
}


def example_body(fields, include_id=False):
    body = {}
    for name, f in fields.items():
        if not isinstance(f, dict):
            continue
        if name == "entity" and "example" not in f:
            continue
        if "example" in f and f["example"] is not None:
            body[name] = f["example"]
        elif f.get("required"):
            body[name] = PLACEHOLDERS.get(f.get("type"), "string")
    if include_id and "id" in fields:
        body["id"] = fields["id"].get("example", 1)
    return body


def path_of(ep, key):
    """Возвращает канонический путь эндпойнта."""
    template = ep.get("pathTemplate")
    if template:
        return template
    return ep.get("path", "")


def curl_base(command_lines):
    return "\n".join(command_lines)


def endpoint_anchor(action):
    return f'<a id="{action}"></a>'


def render_entity(key, ent):
    title = ent["entity"]
    eps = ent["endpoints"]
    actions = [a for a in ACTION_ORDER if a in eps] + [a for a in eps if a not in ACTION_ORDER]

    out = []
    out.append(f"# {title} — сущность `{key}`\n")
    out.append("[← Оглавление](../README.md) · [Индекс сущностей](README.md)\n")
    out.append(f"{ENTITY_NOTES.get(key, '')}\n")
    if VERIFIED_NOTES.get(key):
        out.append(f"> **Проверено на демо-контуре 2026-11-19.** {VERIFIED_NOTES[key]} "
                   f"Подробности — в [07-verification.md](../07-verification.md).\n")

    entity_type = None
    for a in ("create", "update"):
        if a in eps:
            f = (eps[a].get("content", {}).get("requestBody") or {}).get("fields") or {}
            if "entity" in f:
                entity_type = f["entity"].get("example")
                break
    if entity_type:
        out.append(f"**Значение поля `entity`:** `{entity_type}`\n")

    out.append("## Действия\n")
    out.append("| Действие | Метод | Путь | Описание |")
    out.append("|---|---|---|---|")
    for a in actions:
        ep = eps[a]
        out.append(
            f"| [{ACTION_TITLES.get(a, a)}](#{a}) | `{ep.get('method')}` | `{path_of(ep, key)}` | {esc(ep.get('description', ''))} |"
        )
    out.append("")

    for a in actions:
        ep = eps[a]
        content = ep.get("content", {})
        out.append(endpoint_anchor(a))
        out.append(f"## {ACTION_TITLES.get(a, a)}\n")
        out.append(f"`{ep.get('method')} {path_of(ep, key)}`\n")
        out.append(f"_{esc(ep.get('description', ''))}_\n")
        txt = text_of_body_lines(ep)
        if txt:
            out.append(txt + "\n")

        # параметры пути
        path_params = ep.get("pathParams") or {}
        if path_params:
            out.append("### Параметры пути\n")
            out.append("| Параметр | Тип | Описание | Пример |")
            out.append("|---|---|---|---|")
            for pname, p in path_params.items():
                out.append(
                    f"| `{pname}` | `number` | {esc(p.get('description', ''))} | `{p.get('value')}` |"
                )
            out.append("")

        req = content.get("requestBody")
        if req:
            out.append("### Тело запроса\n")
            if req.get("type") == "array":
                example = req.get("example") or []
                desc = ""
                for v in (req.get("fields") or {}).values():
                    if isinstance(v, dict) and v.get("description"):
                        desc = v["description"]
                        break
                out.append(
                    "Тело — JSON-массив идентификаторов"
                    + (f": {desc}." if desc else ".")
                    + " Можно передать один или несколько id за один запрос.\n"
                )
                out.append("```json")
                out.append(json.dumps(example, ensure_ascii=False))
                out.append("```\n")
            else:
                out.append(fields_table(req.get("fields") or {}, with_required=True) + "\n")
                if a == "list":
                    body = {"limit": 10, "page": 1, "sort": {"created": "desc"}}
                    out.append("Пример тела запроса:\n")
                    out.append("```json")
                    out.append(json.dumps(body, ensure_ascii=False, indent=2))
                    out.append("```\n")
                    out.append(
                        "Полный набор параметров выборки (`fields`, `limit`, `page`, `sort`, "
                        "`filters`, `columns`) и правила фильтрации — в разделе "
                        "[«Действие list»](../02-actions.md#list).\n"
                    )
                else:
                    body = example_body(req.get("fields") or {}, include_id=(a == "update"))
                    out.append("Пример тела запроса:\n")
                    out.append("```json")
                    out.append(json.dumps(body, ensure_ascii=False, indent=2))
                    out.append("```\n")

        resp = content.get("responseBody")
        if resp:
            out.append("### Ответ\n")
            out.append(fields_table(resp.get("fields") or {}, show_example=False) + "\n")

        # пример вызова
        out.append("### Пример вызова\n")
        path = path_of(ep, key)
        for pname, p in (ep.get("pathParams") or {}).items():
            path = path.replace("{" + pname + "}", str(p.get("value")))
        out.append("```bash")
        if ep.get("method") == "GET":
            out.append(f'curl -s -g "$IMPULSE_BASE_URL{path}" \\')
            out.append('  -H "Authorization: Basic $IMPULSE_API_KEY"')
        elif req and req.get("type") == "array":
            out.append(f'curl -s -X POST "$IMPULSE_BASE_URL{path}" \\')
            out.append('  -H "Authorization: Basic $IMPULSE_API_KEY" \\')
            out.append('  -H "Content-Type: application/json" \\')
            out.append(f"  -d '{json.dumps(req.get('example') or [], ensure_ascii=False)}'")
        elif req:
            if a == "list":
                body = {"limit": 10, "page": 1, "sort": {"created": "desc"}}
            else:
                body = example_body(req.get("fields") or {}, include_id=(a == "update"))
            out.append(f'curl -s -X POST "$IMPULSE_BASE_URL{path}" \\')
            out.append('  -H "Authorization: Basic $IMPULSE_API_KEY" \\')
            out.append('  -H "Content-Type: application/json" \\')
            out.append(f"  -d '{json.dumps(body, ensure_ascii=False)}'")
        else:
            out.append(f'curl -s -X POST "$IMPULSE_BASE_URL{path}" \\')
            out.append('  -H "Authorization: Basic $IMPULSE_API_KEY"')
        out.append("```\n")

        # html-таблицы в тексте (например, поля элемента items у deposit.list)
        for line in content.get("bodyLines", []):
            if "<table" in line:
                md = html_table_to_md(line)
                if md:
                    out.append("### Поля элемента `items`\n")
                    out.append(md + "\n")

    return "\n".join(out)


def build_index(catalog):
    out = ["# Сущности API impulseCRM\n"]
    out.append("[← Оглавление](../README.md) · [Все эндпойнты](../05-reference.md)\n")
    out.append(f"{len(catalog)} сущности. У большинства набор действий одинаковый: получить по id, "
               "получить список, создать, обновить, удалить.\n")
    for group_title, keys in GROUP_ORDER:
        out.append(f"## {group_title}\n")
        out.append("| Сущность | Ключ | `entity` в теле | Действия | Файл |")
        out.append("|---|---|---|---|---|")
        for key in keys:
            if key not in catalog:
                continue
            ent = catalog[key]
            eps = ent["endpoints"]
            entity_type = "—"
            for a in ("create", "update"):
                if a in eps:
                    f = (eps[a].get("content", {}).get("requestBody") or {}).get("fields") or {}
                    if "entity" in f:
                        entity_type = f"`{f['entity'].get('example')}`"
                        break
            actions = ", ".join(
                ACTION_TITLES.get(a, a).split(" (")[0] for a in ACTION_ORDER if a in eps
            ) + "".join(f", {ACTION_TITLES.get(a, a)}" for a in eps if a not in ACTION_ORDER)
            out.append(
                f"| {ent['entity']} | `{key}` | {entity_type} | {actions} | [{key}.md]({key}.md) |"
            )
        out.append("")
    return "\n".join(out)


def build_reference(catalog):
    out = ["# Сводная таблица эндпойнтов\n"]
    out.append("[← Оглавление](README.md) · [Индекс сущностей](03-entities/README.md)\n")
    out.append("Все HTTP-запросы API: метод, путь, назначение. Префикс `$IMPULSE_BASE_URL` — "
               "адрес вашей CRM (например, `https://demo.impulsecrm.ru`).\n")
    total = sum(len(ent["endpoints"]) for ent in catalog.values())
    out.append(f"Всего эндпойнтов: **{total}**, сущностей: **{len(catalog)}**.\n")
    for key, ent in catalog.items():
        eps = ent["endpoints"]
        out.append(f"## {ent['entity']} — `{key}`\n")
        out.append("| Действие | Метод | Путь | Описание |")
        out.append("|---|---|---|---|")
        for a in ACTION_ORDER + [x for x in eps if x not in ACTION_ORDER]:
            if a not in eps:
                continue
            ep = eps[a]
            out.append(
                f"| [{ACTION_TITLES.get(a, a)}](03-entities/{key}.md#{a}) | `{ep.get('method')}` | `{path_of(ep, key)}` | {esc(ep.get('description', ''))} |"
            )
        out.append("")
    return "\n".join(out)


def build_catalog_json(catalog, source):
    data = {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "source": source,
        "base_url_hint": "https://<домен-вашей-crm>",
        "api_prefix": "/api/public",
        "auth": "Authorization: Basic <API_KEY>",
        "entities": {},
    }
    for key, ent in catalog.items():
        eps = {}
        for a, ep in ent["endpoints"].items():
            content = ep.get("content", {})
            eps[a] = {
                "method": ep.get("method"),
                "path": path_of(ep, key),
                "description": ep.get("description"),
                "path_params": ep.get("pathParams") or {},
                "request": content.get("requestBody"),
                "response": content.get("responseBody"),
            }
        data["entities"][key] = {"title": ent["entity"], "endpoints": eps}
    return json.dumps(data, ensure_ascii=False, indent=1)


def main():
    src, outdir = sys.argv[1], sys.argv[2]
    raw = json.load(open(src, encoding="utf-8"))
    catalog = raw["catalog"]

    os.makedirs(outdir, exist_ok=True)
    entdir = os.path.join(outdir, "03-entities")
    os.makedirs(entdir, exist_ok=True)

    for key, ent in catalog.items():
        with open(os.path.join(entdir, f"{key}.md"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write(render_entity(key, ent))

    with open(os.path.join(entdir, "README.md"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(build_index(catalog))
    with open(os.path.join(outdir, "05-reference.md"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(build_reference(catalog))
    with open(os.path.join(outdir, "catalog.json"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(build_catalog_json(catalog, "https://tech.impulsecrm.ru/api/public/api_doc/load/ru"))

    print(f"entities: {len(catalog)}")
    print(f"out: {outdir}")


if __name__ == "__main__":
    main()
