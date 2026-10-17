"""Audit Git's publication set, not ignored runtime state."""
import hashlib
from pathlib import Path
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
paths=subprocess.check_output(['git','ls-files','-z'],cwd=ROOT).decode().split('\0')
reviewed={}
manifest=ROOT/'assets'/'SHA256SUMS'
if manifest.exists():
    for line in manifest.read_text().splitlines():
        digest, name=line.split(maxsplit=1);reviewed[name]=digest
bad=[]
for name in filter(None,paths):
    path=ROOT/name;data=path.read_bytes()
    if name.startswith('local-data/') or path.suffix.lower() in {'.exe','.dll','.gguf','.zip','.env'}:
        bad.append((name,'private/runtime artifact'));continue
    if path.suffix.lower()=='.png':
        if reviewed.get(name)!=hashlib.sha256(data).hexdigest():bad.append((name,'unreviewed image'))
        continue
    try:text=data.decode('utf-8-sig')
    except UnicodeDecodeError:bad.append((name,'unexpected binary'));continue
    patterns=[r'sk-or-v1-[a-f0-9]{30,}',r'gh[pousr]_[A-Za-z0-9]{30,}',r'-----BEGIN [A-Z ]*PRIVATE KEY-----',r'C:[\\/]Users[\\/]paras',r'82\.112\.235\.26',r'100\.99\.221\.34']
    for pattern in patterns:
        if re.search(pattern,text):bad.append((name,'credential/host-specific content'))
print(f'Audited {len(list(filter(None,paths)))} tracked files; {len(bad)} findings.')
for name,reason in bad:print(name+': '+reason)
sys.exit(bool(bad))
