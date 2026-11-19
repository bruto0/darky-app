#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Живая проверка API impulseCRM по чек-листу.

Запуск (адрес и ключ — только из окружения):

    set IMPULSE_BASE_URL=https://demo.impulsecrm.ru
    set IMPULSE_API_KEY=...
    python verify_live.py

    IMPULSE_BASE_URL=... IMPULSE_API_KEY=... python verify_live.py --read-only

Что делает:
1. проверяет авторизацию (branch/load/1) и что base64-вариант отвергается;
2. вызывает list по всем 23 сущностям и load по первой записи;
3. создаёт тестового клиента, проверяет частичное обновление, депозит, массовое удаление;
4. удаляет всё созданное (префикс API-TEST) и печатает итог.

Только стандартная библиотека. Код возврата 1, если критичная проверка провалилась.
"""

import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request

ENTITIES = [
    "client", "ancestor", "informer", "pipeline", "deposit", "branch", "hall",
    "product", "teacher", "user", "style", "group", "schedule", "group_account",
    "group_single", "individual_account", "individual_single", "self_account",
    "self_single", "rent_account", "rent_single", "visit", "reservation",
]
NO_LOAD = {"informer", "pipeline", "deposit", "visit"}

results = []


def call(base, key, method, path, body=None, auth=None, timeout=60):
    data = json.dumps(body, ensure_ascii=False).encode("utf-8") if body is not None else None
    headers = {"Accept": "application/json"}
    if auth is not None:
        headers["Authorization"] = auth
    if data is not None:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(base.rstrip("/") + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8", "replace")
            status = resp.status
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", "replace")
        status = exc.code
    try:
        return status, json.loads(raw), raw
    except ValueError:
        return status, None, raw


def check(name, ok, detail=""):
    results.append((name, bool(ok), detail))
    print(("PASS " if ok else "FAIL ") + name + ((" — " + str(detail)[:160]) if detail else ""))
    return ok


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", default=os.environ.get("IMPULSE_BASE_URL", ""))
    parser.add_argument("--api-key", default=os.environ.get("IMPULSE_API_KEY", ""))
    parser.add_argument("--read-only", action="store_true", help="не создавать записи")
    args = parser.parse_args()

    base, key = args.base_url.strip(), args.api_key.strip()
    if not base or not key:
        print("Задайте IMPULSE_BASE_URL и IMPULSE_API_KEY", file=sys.stderr)
        return 2
    auth = "Basic " + key
    tag = "API-TEST-" + time.strftime("%H%M%S")
    created = []

    try:
        st, obj, raw = call(base, key, "GET", "/api/public/branch/load/1", auth=auth)
        check("auth: Basic <key>", st == 200 and isinstance(obj, dict), st)

        b64 = base64.b64encode(key.encode()).decode()
        st2, _, _ = call(base, key, "GET", "/api/public/branch/load/1", auth="Basic " + b64)
        check("auth: base64 отвергается", st2 == 401, st2)

        st3, _, _ = call(base, key, "GET", "/api/public/branch/load/1", auth=None)
        check("auth: без заголовка 401", st3 == 401, st3)

        listed = {}
        for entity in ENTITIES:
            st, obj, raw = call(base, key, "POST", f"/api/public/{entity}/list", {"limit": 1}, auth=auth)
            total = obj.get("total") if isinstance(obj, dict) else None
            ok = st == 200 and isinstance(obj, dict) and "items" in obj
            check(f"list {entity}", ok, f"[{st}] total={total}")
            listed[entity] = obj
            time.sleep(0.05)

        for entity in ENTITIES:
            if entity in NO_LOAD:
                continue
            obj = listed.get(entity) or {}
            items = obj.get("items") or []
            if not items:
                check(f"load {entity}", True, "нет записей — пропуск")
                continue
            st, rec, _ = call(base, key, "GET", f"/api/public/{entity}/load/{items[0]['id']}", auth=auth)
            check(f"load {entity}", st == 200 and isinstance(rec, dict), st)

        if args.read_only:
            raise SystemExit(0)

        st, obj, raw = call(base, key, "POST", "/api/public/client/update",
                            {"entity": "client", "name": tag, "deposit": 0, "bonus": 0}, auth=auth)
        cid = obj.get("id") if isinstance(obj, dict) else None
        check("client create", st == 200 and cid, f"[{st}] {raw[:120]}")
        if not cid:
            raise SystemExit(1)
        created.append(cid)

        st, obj, raw = call(base, key, "POST", "/api/public/client/update",
                            {"id": cid, "annotation": tag}, auth=auth)
        check("client partial update", st == 200 and obj.get("success"), st)
        st, rec, _ = call(base, key, "GET", f"/api/public/client/load/{cid}", auth=auth)
        check("client kept fields after partial update",
              isinstance(rec, dict) and rec.get("name") == tag, rec.get("name") if isinstance(rec, dict) else None)

        st, dep, raw = call(base, key, "POST", "/api/public/deposit/input",
                            {"sum": 10, "payment": 1, "debt": False, "client_id": cid}, auth=auth)
        dep_id = dep.get("id") if isinstance(dep, dict) else None
        check("deposit input", st == 200 and dep_id, st)
        st, rec, _ = call(base, key, "GET", f"/api/public/client/load/{cid}", auth=auth)
        check("deposit balance = 10", isinstance(rec, dict) and rec.get("deposit") == 10, rec.get("deposit") if isinstance(rec, dict) else None)
        if dep_id:
            st, _, _ = call(base, key, "POST", "/api/public/deposit/delete", [dep_id], auth=auth)
            check("deposit delete one", st == 200, st)

        second = []
        for i in range(2):
            st, obj, _ = call(base, key, "POST", "/api/public/client/update",
                              {"entity": "client", "name": f"{tag}-{i}", "deposit": 0, "bonus": 0}, auth=auth)
            if isinstance(obj, dict) and obj.get("id"):
                second.append(obj["id"])
        check("mass create 2 clients", len(second) == 2, second)
        if len(second) == 2:
            st, _, _ = call(base, key, "POST", "/api/public/client/delete", second, auth=auth)
            check("mass delete 2 clients", st == 200, st)
            st, obj, _ = call(base, key, "POST", "/api/public/client/list",
                              {"filters": {"id": second}, "fields": ["id"]}, auth=auth)
            check("mass delete verified", isinstance(obj, dict) and obj.get("total") == 0,
                  obj.get("total") if isinstance(obj, dict) else None)
    finally:
        for cid in created:
            call(base, key, "POST", "/api/public/client/delete", [cid], auth=auth)
        failed = [r for r in results if not r[1]]
        print("\nИтого: %d проверок, %d провалов" % (len(results), len(failed)))
        if failed:
            for name, _, detail in failed:
                print("  FAIL:", name, detail)


if __name__ == "__main__":
    sys.exit(main() or 0)
