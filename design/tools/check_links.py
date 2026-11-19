import os
import re
import sys

root = os.path.abspath('.')
files = ['README.md', 'PLAN.md', 'design/README.md', 'design/DESIGN.md', 'design/LIVE-FINDINGS.md', 'design/APPROVAL.md']
missing = []
for rel in files:
    path = os.path.join(root, rel)
    text = open(path, encoding='utf-8').read()
    for m in re.finditer(r'!?\[[^\]]*\]\(([^)]+)\)', text):
        target = m.group(1).strip()
        if target.startswith(('http://', 'https://', 'mailto:', '#')):
            continue
        target = target.split('#', 1)[0]
        if not target:
            continue
        if target.startswith('/'):
            target = target[1:]
        full = os.path.normpath(os.path.join(os.path.dirname(path), target))
        if not os.path.exists(full):
            missing.append((rel, m.group(1), full))

print('missing:', len(missing))
for rel, link, full in missing:
    print(f'  {rel}: {link} -> {full}')
sys.exit(1 if missing else 0)
