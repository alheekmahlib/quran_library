#!/usr/bin/env python3
"""Export quran-p2g pronunciation data for experimental validation.

The result is NPL-1.2 data and is not an approved Mushaf mapping or a model.
Install quran-p2g at the pinned revision described in README.md first.
"""
import argparse
import json
from pathlib import Path

from quran_p2g import quran
from quran_p2g.formats import degeminate

parser = argparse.ArgumentParser()
parser.add_argument('output', type=Path)
args = parser.parse_args()
reference = quran()
verses = {}
for surah, ayah in reference.keys():
    verse = reference.ayah(surah, ayah)
    words = []
    for index, word in enumerate(verse.words):
        canonical = []
        forms = []
        for form in word.forms:
            forms.append({
                'left': form.left, 'right': form.right,
                'mode': form.mode, 'variant': form.wajh,
                'tokens': [degeminate(token) for token in form.tj3g.split()],
            })
            if (form.left == ('ibtida' if index == 0 else 'wasl') and
                form.right == ('waqf' if index == len(verse.words) - 1 else 'wasl') and
                form.mode == ('sukun' if index == len(verse.words) - 1 else 'plain') and
                    form.wajh is None):
                canonical.append(len(forms) - 1)
        if len(canonical) != 1:
            raise ValueError(f'{surah}:{ayah}:{index}: ambiguous canonical form')
        words.append({'canonical': canonical[0], 'forms': forms})
    verses[f'{surah}:{ayah}'] = words
args.output.write_text(json.dumps({
    'format': 'quran-library.tajweedformer-lattice.v1',
    'source_revision': '233568a621d853da7969ed174ddff625ef9ace5e',
    'verses': verses,
}, ensure_ascii=False, separators=(',', ':')))
print(f'Prepared {len(verses)} verses for experimental validation.')
