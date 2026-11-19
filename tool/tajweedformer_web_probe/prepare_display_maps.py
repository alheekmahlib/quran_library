#!/usr/bin/env python3
"""Generate V4 pronunciation-word to QPC display-word maps.

Uses quran-p2g (Quran Lab NPL-1.2), pinned as documented in README.md.
"""
import argparse
import gzip
import json
from collections import defaultdict
from pathlib import Path
import unicodedata

from quran_p2g import quran

ROOT = Path(__file__).resolve().parents[2]


def normalized(text):
    text = unicodedata.normalize('NFKD', text).translate(str.maketrans({
        'ى': 'ي', 'ٱ': 'ا', 'أ': 'ا', 'إ': 'ا', 'آ': 'ا',
        'ؤ': 'و', 'ئ': 'ي', 'ۥ': '', 'ۦ': '',
    }))
    return ''.join(c for c in text
                   if unicodedata.category(c).startswith('L') and c != 'ـ')


def map_words(source, target, key):
    source = [normalized(w) for w in source]
    target = [normalized(w) for w in target]
    # In 2:72 the two editions write the same hamza as a combining mark or a
    # spacing character, respectively. Keep the exception limited to this word.
    if key == '2:72':
        if source[3] != 'فادرتم' or target[3] != 'فادرءتم':
            raise ValueError('The reviewed 2:72 spelling has changed')
        target[3] = source[3]
    if any(not word for word in source + target) or ''.join(source) != ''.join(target):
        raise ValueError(f'{key}: verse texts differ')
    mapping = []
    target_index = 0
    source_end, target_end = 0, len(target[0])
    for word in source:
        source_end += len(word)
        if source_end > target_end:
            raise ValueError(f'{key}: source word crosses a display boundary')
        mapping.append(target_index)
        if source_end == target_end and target_index + 1 < len(target):
            target_index += 1
            target_end += len(target[target_index])
    return mapping


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    with gzip.open(ROOT / 'assets/jsons/qpc-hafs-word-by-word.json.gz', 'rt') as f:
        raw = json.load(f)
    display = defaultdict(list)
    for row in raw.values():
        display[(int(row['surah']), int(row['ayah']))].append(
            (int(row['word']), row['text']))
    maps = {}
    ref = quran()
    for surah, ayah in ref.keys():
        key = f'{surah}:{ayah}'
        entries = sorted(display[(surah, ayah)])
        if (not entries or not entries[-1][1].strip().isdigit() or
                [n for n, _ in entries] != list(range(1, len(entries) + 1))):
            raise ValueError(f'{key}: invalid QPC word sequence')
        verse = ref.ayah(surah, ayah)
        target = [text for _, text in entries[:-1]]
        text_map = map_words(verse.uthmani, target, key)
        mapping = [text_map[word.text_index] for word in verse.words]
        if (not mapping or set(mapping) != set(range(len(target))) or
                any(a > b or b > a + 1 for a, b in zip(mapping, mapping[1:]))):
            raise ValueError(f'{key}: invalid pronunciation map')
        maps[key] = mapping
    args.output.write_text(json.dumps({'format': 'quran-library.v4-qpc-map.v1',
                                       'maps': maps}, separators=(',', ':')))
    print(f'Prepared {len(maps)} QPC word maps.')


if __name__ == '__main__':
    main()
