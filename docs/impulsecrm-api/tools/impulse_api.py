#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CLI-клиент API impulseCRM.

Только стандартная библиотека Python 3.8+. Никаких зависимостей.

Настройка (переменные окружения или флаги):
    IMPULSE_BASE_URL  — адрес CRM, например https://demo.impulsecrm.ru
    IMPULSE_API_KEY   — API-ключ из профиля («Настройка API» → «Обновить ключ»)

Примеры:
    python impulse_api.py ping
    python impulse_api.py list client --limit 5 --fields id,name,phone
    python impulse_api.py list client --body '{"filters": {"blacklist": true}}'
    python impulse_api.py get client 123
    python impulse_api.py create client --body '{"name": "Иван", "lastName": "Петров"}'
    python impulse_api.py update client 123 --body '{"name": "Иван", "annotation": "VIP"}'
    python impulse_api.py delete client 123 124 125
    python impulse_api.py deposit-input --body '{"sum": 100, "payment": 1, "debt": false, "client_id": 123}'
    python impulse_api.py call POST /api/public/group/list --body '{"limit": 5}'

Тело можно передать файлом: --body @body.json
Флаг --dry-run печатает запрос, но не отправляет его.
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request

# Значение поля "entity" для сущностей, у которых оно есть в теле запроса.
ENTITY_TYPES = {
    "client": "client",
    "ancestor": "ancestor",
    "branch": "branch",
    "hall": "hall",
    "product": "product",
    "teacher": "teacher",
    "user": "user",
    "style": "style",
    "group": "group",
    "group_account": "groupAccount",
    "group_single": "groupSingle",
    "individual_account": "individualAccount",
    "individual_single": "individualSingle",
    "self_account": "selfAccount",
    "self_single": "selfSingle",
    "rent_account": "rentAccount",
    "rent_single": "rentSingle",
}


def die(message, code=1):
    print(message, file=sys.stderr)
    sys.exit(code)


def common_parser():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--base-url", default=argparse.SUPPRESS,
                        help="адрес CRM (по умолчанию $IMPULSE_BASE_URL)")
    parser.add_argument("--api-key", default=argparse.SUPPRESS,
                        help="API-ключ (по умолчанию $IMPULSE_API_KEY)")
    parser.add_argument("--timeout", type=float, default=argparse.SUPPRESS,
                        help="таймаут, секунды")
    parser.add_argument("--dry-run", action="store_true", default=argparse.SUPPRESS,
                        help="показать запрос и выйти")
    parser.add_argument("--raw", action="store_true", default=argparse.SUPPRESS,
                        help="печатать ответ как есть")
    return parser


def build_parser():
    common = common_parser()
    parser = argparse.ArgumentParser(
        description="CLI для API impulseCRM (23 сущности: load/list/update/delete).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
        parents=[common],
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("ping", help="проверить ключ запросом branch/load/1", parents=[common])

    p = sub.add_parser("list", help="выборка записей", parents=[common])
    p.add_argument("entity")
    p.add_argument("--body", default=None, help="JSON тела запроса или @файл")
    p.add_argument("--limit", type=int, default=None)
    p.add_argument("--page", type=int, default=None)
    p.add_argument("--fields", default=None, help="список полей через запятую")
    p.add_argument("--sort", default=None, help="например created:desc")

    p = sub.add_parser("get", help="получить запись по id", parents=[common])
    p.add_argument("entity")
    p.add_argument("id")

    p = sub.add_parser("create", help="создать запись (entity подставится автоматически)",
                      parents=[common])
    p.add_argument("entity")
    p.add_argument("--body", required=True, help="JSON объекта или @файл")

    p = sub.add_parser("update", help="обновить запись по id", parents=[common])
    p.add_argument("entity")
    p.add_argument("id")
    p.add_argument("--body", required=True, help="JSON изменяемых полей или @файл")

    p = sub.add_parser("delete", help="удалить одну или несколько записей", parents=[common])
    p.add_argument("entity")
    p.add_argument("ids", nargs="+", type=int)

    p = sub.add_parser("deposit-input", help="пополнить депозит клиента", parents=[common])
    p.add_argument("--body", required=True, help="JSON или @файл")

    p = sub.add_parser("deposit-output", help="списать с депозита клиента", parents=[common])
    p.add_argument("--body", required=True, help="JSON или @файл")

    p = sub.add_parser("call", help="произвольный вызов API", parents=[common])
    p.add_argument("method", choices=["GET", "POST", "PUT", "PATCH", "DELETE"])
    p.add_argument("path", help="путь, например /api/public/client/list")
    p.add_argument("--body", default=None, help="JSON или @файл")

    return parser


def read_json_arg(value, what="тело"):
    if value is None:
        return None
    if value.startswith("@"):
        path = value[1:]
        try:
            with open(path, encoding="utf-8") as fh:
                return json.load(fh)
        except (OSError, ValueError) as exc:
            die(f"Не удалось прочитать {what} из {path}: {exc}", 2)
    try:
        return json.loads(value)
    except ValueError as exc:
        die(f"Некорректный JSON в {what}: {exc}", 2)


def request(base_url, api_key, method, path, body=None, timeout=60.0):
    url = base_url.rstrip("/") + path
    data = None
    headers = {
        "Authorization": "Basic {}".format(api_key),
        "Accept": "application/json",
    }
    if body is not None:
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8", "replace")
            return resp.status, raw
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", "replace")
        return exc.code, raw
    except urllib.error.URLError as exc:
        die(f"Сетевая ошибка: {exc.reason}", 1)


def print_response(status, raw, raw_mode=False):
    print(f"HTTP {status}")
    if raw_mode:
        print(raw)
        return
    try:
        parsed = json.loads(raw)
    except ValueError:
        print(raw[:2000])
        return
    print(json.dumps(parsed, ensure_ascii=False, indent=2))


def main():
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8")
        except (AttributeError, ValueError):
            pass

    args = build_parser().parse_args()

    base_url = (getattr(args, "base_url", None) or os.environ.get("IMPULSE_BASE_URL", "")).strip()
    api_key = (getattr(args, "api_key", None) or os.environ.get("IMPULSE_API_KEY", "")).strip()
    timeout = getattr(args, "timeout", 60.0)
    dry_run = getattr(args, "dry_run", False)
    raw_mode = getattr(args, "raw", False)

    if not base_url:
        die("Не задан адрес CRM: --base-url или IMPULSE_BASE_URL", 2)
    if not api_key:
        die("Не задан API-ключ: --api-key или IMPULSE_API_KEY", 2)

    method, path, body = None, None, None

    if args.command == "ping":
        method, path = "GET", "/api/public/branch/load/1"

    elif args.command == "list":
        body = read_json_arg(args.body) or {}
        if args.limit is not None:
            body["limit"] = args.limit
        if args.page is not None:
            body["page"] = args.page
        if args.fields:
            body["fields"] = [x.strip() for x in args.fields.split(",") if x.strip()]
        if args.sort:
            key, _, direction = args.sort.partition(":")
            body["sort"] = {key: direction or "asc"}
        method, path = "POST", f"/api/public/{args.entity}/list"

    elif args.command == "get":
        method, path = "GET", f"/api/public/{args.entity}/load/{args.id}"

    elif args.command == "create":
        body = read_json_arg(args.body) or {}
        if args.entity in ENTITY_TYPES:
            body.setdefault("entity", ENTITY_TYPES[args.entity])
        body.pop("id", None)
        method, path = "POST", f"/api/public/{args.entity}/update"

    elif args.command == "update":
        body = read_json_arg(args.body) or {}
        body["id"] = int(args.id)
        if args.entity in ENTITY_TYPES:
            body.setdefault("entity", ENTITY_TYPES[args.entity])
        method, path = "POST", f"/api/public/{args.entity}/update"

    elif args.command == "delete":
        method, path = "POST", f"/api/public/{args.entity}/delete"
        body = [int(x) for x in args.ids]

    elif args.command == "deposit-input":
        body = read_json_arg(args.body) or {}
        method, path = "POST", "/api/public/deposit/input"

    elif args.command == "deposit-output":
        body = read_json_arg(args.body) or {}
        method, path = "POST", "/api/public/deposit/output"

    elif args.command == "call":
        method, path = args.method, args.path
        body = read_json_arg(args.body)

    if dry_run:
        print(json.dumps({
            "method": method,
            "url": base_url.rstrip("/") + path,
            "headers": {
                "Authorization": "Basic ***",
                "Content-Type": "application/json" if body is not None else None,
            },
            "body": body,
        }, ensure_ascii=False, indent=2))
        return

    status, raw = request(base_url, api_key, method, path, body, timeout)
    print_response(status, raw, raw_mode)
    if status >= 400:
        sys.exit(1)
    try:
        parsed = json.loads(raw)
        if isinstance(parsed, dict) and parsed.get("success") is False:
            sys.exit(1)
    except ValueError:
        pass


if __name__ == "__main__":
    main()
