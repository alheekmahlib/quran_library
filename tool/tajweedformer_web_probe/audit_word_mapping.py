#!/usr/bin/env python3
"""Audit candidate word boundaries; output is not an approved UI mapping.

Uses the separately installed, pinned quran-p2g source and this repository's
QPC and Zipformer reference assets. No model files are accessed.
"""
import argparse
import gzip
import json
from collections import Counter, defaultdict
from pathlib import Path
import unicodedata

from quran_p2g import quran

ROOT = Path(__file__).resolve().parents[2]


def letters(text):
    # Compare letters, retaining distinctions such as hamza and alef variants.
    # Diacritics and formatting differ across the two sources.
    return ''.join(c for c in unicodedata.normalize('NFC', text)
                   if unicodedata.category(c).startswith('L'))


def boundaries(source, target):
    """Map each source word to one target word, or return a reason to review."""
    source = [letters(word) for word in source]
    target = [letters(word) for word in target]
    if not source or not target or any(not w for w in source + target):
        return None, 'empty_word'
    if ''.join(source) != ''.join(target):
        return None, 'text_mismatch'
    result = []
    target_index = 0
    source_end = 0
    target_end = len(target[0])
    for word in source:
        source_end += len(word)
        if source_end > target_end:
            return None, 'source_crosses_target_boundary'
        result.append(target_index)
        if source_end == target_end and target_index + 1 < len(target):
            target_index += 1
            target_end += len(target[target_index])
    return result, 'matched'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--details', type=Path,
                        help='Write candidate maps and review reasons as JSON')
    args = parser.parse_args()
    with gzip.open(ROOT / 'assets/jsons/qpc-hafs-word-by-word.json.gz', 'rt') as f:
        qpc = json.load(f)
    with gzip.open(ROOT / 'assets/quran_lab/ordered_quran_phonemes.json.gz', 'rt') as f:
        zipformer = json.load(f)
    displayed = defaultdict(list)
    for row in qpc.values():
        displayed[(int(row['surah']), int(row['ayah']))].append(
            (int(row['word']), row['text']))

    report = {}
    counts = Counter()
    reference = quran()
    for surah, ayah in reference.keys():
        verse = reference.ayah(surah, ayah)
        key = f'{surah}:{ayah}'
        entries = sorted(displayed[(surah, ayah)])
        # The last QPC entry is an ayah number, never a spoken word.
        if (not entries or not entries[-1][1].strip().isdigit() or
                [n for n, _ in entries] != list(range(1, len(entries) + 1))):
            raise ValueError(f'Unexpected QPC word sequence at {key}')
        qpc_words = [text for _, text in entries[:-1]]
        text_map, reason = boundaries(verse.uthmani, qpc_words)
        zip_map, zip_reason = boundaries(zipformer[key]['aya_text'].split(), qpc_words)
        if text_map is not None:
            indexes = [w.text_index for w in verse.words]
            if (any(i < 0 or i >= len(text_map) for i in indexes) or
                    any(a > b for a, b in zip(indexes, indexes[1:]))):
                raise ValueError(f'Unexpected pronunciation word map at {key}')
            pronunciation_map = [text_map[i] for i in indexes]
            if (set(pronunciation_map) != set(range(len(qpc_words))) or
                    any(b > a + 1 for a, b in zip(pronunciation_map,
                                                  pronunciation_map[1:]))):
                reason, pronunciation_map = 'uncovered_display_word', None
        else:
            pronunciation_map = None
        counts[f'candidate_{reason}'] += 1
        counts[f'zipformer_{zip_reason}'] += 1
        report[key] = {'status': reason, 'candidate': pronunciation_map,
                       'zipformer_status': zip_reason, 'zipformer_map': zip_map}
    for key, value in sorted(counts.items()):
        print(f'{key}: {value}')
    if args.details:
        args.details.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    main()
