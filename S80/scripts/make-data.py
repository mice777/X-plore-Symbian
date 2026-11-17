#!/usr/bin/env python3
"""Builds Data.dta (X-plore's resource pack, a plain zip): the prebuilt
LcgApps/Explorer/Data.dta plus every language in LcgApps/Lang/Explorer.
Usage: make-data.py <repo root> <output>"""
import os, sys, zipfile

root, out = sys.argv[1], sys.argv[2]
os.makedirs(os.path.dirname(out), exist_ok=True)
src = zipfile.ZipFile(os.path.join(root, 'LcgApps', 'Explorer', 'Data.dta'))
lang_dir = os.path.join(root, 'LcgApps', 'Lang', 'Explorer')
langs = sorted(f for f in os.listdir(lang_dir) if f.lower().endswith('.txt'))
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for info in src.infolist():
        if info.filename.lower().startswith('lang/'):
            continue
        z.writestr(info, src.read(info))
    for f in langs:
        with open(os.path.join(lang_dir, f), 'rb') as fh:
            z.writestr('Lang/' + f, fh.read())
print('Data.dta: %d languages' % len(langs))
