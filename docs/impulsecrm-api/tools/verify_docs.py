# -*- coding: utf-8 -*-
"""Сверка сгенерированных страниц с catalog.json (локально)."""

import io
import json
import os
import sys

ROOT = r"J:\work\__dsh__\workspace\docs\impulsecrm-api"
cat = json.load(io.open(os.path.join(ROOT, "catalog.json"), encoding="utf-8"))
errors = []

entities = cat["entities"]
if len(entities) != 23:
    errors.append(f"сущностей {len(entities)}, ожидалось 23")

total = sum(len(v["endpoints"]) for v in entities.values())
if total != 103:
    errors.append(f"эндпойнтов {total}, ожидалось 103")

ref = io.open(os.path.join(ROOT, "05-reference.md"), encoding="utf-8").read()
rows = ref.count("| `GET` |") + ref.count("| `POST` |")
if rows != total:
    errors.append(f"в 05-reference.md строк {rows}, ожидалось {total}")

for key, ent in entities.items():
    path = os.path.join(ROOT, "03-entities", f"{key}.md")
    if not os.path.exists(path):
        errors.append(f"нет файла {key}.md")
        continue
    text = io.open(path, encoding="utf-8").read()
    if f"`{key}`" not in text:
        errors.append(f"{key}.md: не упомянут ключ сущности")
    for action, ep in ent["endpoints"].items():
        if ep["path"] not in text:
            errors.append(f"{key}.md: нет пути {ep['path']}")
        anchor = f'<a id="{action}"></a>'
        if anchor not in text:
            errors.append(f"{key}.md: нет якоря {action}")
        if text.count("### Пример вызова") < len(ent["endpoints"]):
            errors.append(f"{key}.md: меньше примеров вызова, чем действий")
            break
    req = ent["endpoints"].get("create", {}).get("request") or {}
    fields = req.get("fields") or {}
    for name, f in fields.items():
        if isinstance(f, dict) and f.get("required") and f"`{name}`" not in text:
            errors.append(f"{key}.md: не найден обязательный параметр {name}")
    if ent["endpoints"] and "## Действия" not in text:
        errors.append(f"{key}.md: нет таблицы действий")

print(f"entities={len(entities)} endpoints={total}")
print(f"errors={len(errors)}")
for e in errors:
    print(" -", e)
sys.exit(1 if errors else 0)
