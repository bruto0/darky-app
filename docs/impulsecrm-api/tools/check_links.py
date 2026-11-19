# -*- coding: utf-8 -*-
"""Проверка ссылок и структуры справочника (локально, без сети)."""

import os
import re
import sys
import io

ROOT = r"J:\work\__dsh__\workspace\docs\impulsecrm-api"
problems = []

def check_file(path):
    with io.open(path, encoding="utf-8") as fh:
        text = fh.read()
    # [текст](цель)
    for m in re.finditer(r"\[[^\]]*\]\(([^)\s]+)\)", text):
        target = m.group(1)
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        anchor = ""
        if "#" in target:
            target, anchor = target.split("#", 1)
        if not target:
            continue
        resolved = os.path.normpath(os.path.join(os.path.dirname(path), target))
        if not os.path.exists(resolved):
            problems.append(f"{os.path.relpath(path, ROOT)}: нет файла {target}")
            continue
        if anchor:
            with io.open(resolved, encoding="utf-8") as fh2:
                body = fh2.read()
            if f'id="{anchor}"' not in body:
                problems.append(
                    f"{os.path.relpath(path, ROOT)}: нет якоря #{anchor} в {target}"
                )

for dirpath, _dirnames, filenames in os.walk(ROOT):
    for name in filenames:
        if name.endswith(".md"):
            check_file(os.path.join(dirpath, name))

print(f"markdown files: {sum(1 for d,_,fs in os.walk(ROOT) for f in fs if f.endswith('.md'))}")
print(f"problems: {len(problems)}")
for p in problems:
    print(" -", p)
sys.exit(1 if problems else 0)
