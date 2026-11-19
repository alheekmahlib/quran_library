#!/usr/bin/env python3
"""Prepare canonical reference data from the separately installed quran-p2g."""
import argparse
import json
from pathlib import Path

from quran_p2g import quran
from quran_p2g.formats import degeminate

parser = argparse.ArgumentParser()
parser.add_argument('output', type=Path)
args = parser.parse_args()
reference = quran()
rows = []
for surah, ayah in reference.keys():
    verse = reference.ayah(surah, ayah)
    tokens, words = [], []
    for index, word in enumerate(verse.words):
        left = 'ibtida' if index == 0 else 'wasl'
        right = 'waqf' if index == len(verse.words) - 1 else 'wasl'
        mode = 'sukun' if right == 'waqf' else 'plain'
        form = next(f for f in word.forms if f.left == left and f.right == right
                    and f.mode == mode and f.wajh is None)
        form_tokens = [degeminate(t) for t in form.tj3g.split()]
        tokens.extend(form_tokens)
        words.extend([index] * len(form_tokens))
    rows.append({'s': surah, 'a': ayah, 'expected': tokens,
                 'expectedWords': words, 'words': len(verse.uthmani)})
args.output.write_text(json.dumps(rows, ensure_ascii=False))
print(f'Prepared {len(rows)} canonical references.')
