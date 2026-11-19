#!/usr/bin/env python3
"""Build per-unit timing metadata from Quran Lab's public phonetics data.

Run with PYTHONPATH pointing at quran-g2p/src (revision below), supplying the
quran_phonetics.jsonl dataset and an output path. The output is NPL-1.2 data.
"""
import argparse
import json
from collections import Counter
from pathlib import Path

from quran_g2p.tokenlayer_tj3 import WORD, phones_to_tj3_units

parser = argparse.ArgumentParser()
parser.add_argument('source', type=Path)
parser.add_argument('rulings', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
with args.rulings.open(encoding='utf-8') as source:
    rulings = {item['rule_id']: item for item in map(json.loads, source)}
verses = {}
counts = Counter()
with args.source.open(encoding='utf-8') as source:
    for line in source:
        row = json.loads(line)
        phones = row['phones']
        tokens, first = phones_to_tj3_units([[phone] for phone in phones])
        index_map = {}
        sounds = []
        for i, token in enumerate(tokens):
            if token != WORD:
                index_map[i] = len(sounds)
                sounds.append(token)
        madd = []
        geminated = []
        for phone, i in zip(phones, first):
            if phone.get('geminated'):
                if phone.get('kind') != 'consonant' or i not in index_map:
                    raise ValueError('Invalid gemination metadata')
                geminated.append(index_map[i])
            length = phone.get('length')
            if phone.get('kind') != 'madd' or not length:
                continue
            rules = phone.get('rules', [])
            if any(rule.startswith('R185_') for rule in rules):
                kind = 'muttasil'
            elif length.get('kind') == 'fixed' and length.get('scoring') == [2]:
                kind = 'fixed2'
            elif length.get('kind') == 'fixed' and length.get('scoring') == [6]:
                kind = 'lazim'
            else:
                kind = 'free'
            scoring = length.get('scoring') or length.get('allowed') or []
            if not scoring or i not in index_map:
                raise ValueError('Missing timing metadata')
            matching = [rulings[rule] for rule in rules
                        if rule.startswith('R18') and rule in rulings]
            if not matching:
                raise ValueError(f'Missing madd ruling: {rules}')
            name = matching[0]
            madd.append({'unit': index_map[i], 'class': kind, 'allowed': scoring,
                         'name_ar': name['name_ar'], 'name_en': name['name_en']})
            counts[kind] += 1
        key = f"{row['surah']}:{row['ayah']}"
        if key in verses:
            raise ValueError(f'Duplicate verse {key}')
        verses[key] = {'tokens': sounds, 'madd': madd, 'geminated': geminated}
if len(verses) != 6236:
    raise ValueError(f'Expected 6236 verses, got {len(verses)}')
data = {'format': 'quran-library.v4-timing-reference.v1',
        'g2p_revision': '7eeba1206146e0b4a81bbd12b59671042b1ba3f0',
        'dataset_revision': '6f4be6257c140f7e318574bca01386474b606999',
        'verses': verses}
with args.output.open('w', encoding='utf-8') as out:
    json.dump(data, out, ensure_ascii=False, separators=(',', ':'))
print(f'Prepared {len(verses)} verses; madd classes: {dict(counts)}')
