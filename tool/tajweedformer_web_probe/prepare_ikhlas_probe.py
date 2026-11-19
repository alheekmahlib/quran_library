#!/usr/bin/env python3
"""Prepare a small exploratory, balanced Al-Ikhlas sample outside Git.

Audio: Maghraby et al., Mendeley Data, DOI 10.17632/sxtmmr6mvk.1, CC BY 4.0.
Metadata and audio mirror: MuazAhmad7/Surah_Ikhlas-Labeled_Dataset, pinned below.
"""
import argparse
import csv
import io
import json
import random
import re
import subprocess
import urllib.parse
import urllib.request
from pathlib import Path

REVISION = '973b5ef1d1532bcbe7e9a5a5b0dce125cc4d0dac'
BASE = ('https://huggingface.co/datasets/MuazAhmad7/'
        f'Surah_Ikhlas-Labeled_Dataset/resolve/{REVISION}/')


def select_rows(rows, per_stratum=2, seed=None):
    if type(per_stratum) is not int or per_stratum < 1:
        raise ValueError('Invalid sample size')
    selected = []
    used_participants = set()
    randomizer = random.Random(seed) if seed is not None else None
    for verse in range(1, 5):
        for label in ('0', '1'):
            candidates = list(rows)
            if randomizer is not None:
                randomizer.shuffle(candidates)
            matches = []
            for row in candidates:
                match = re.search(r'ID(\d+)V([1-4])([TF])\.wav$',
                                  row['file_name'], re.I)
                if (not match or int(match[2]) != verse or row['label'] != label or
                        (match[3].upper() == 'T') != (label == '1')):
                    continue
                if label == '0' and not row['error_location'].strip():
                    continue
                if ((randomizer is not None and match[1] in used_participants) or
                        any(match[1] == participant for participant, _ in matches)):
                    continue
                matches.append((match[1], row))
                if len(matches) == per_stratum:
                    break
            if len(matches) != per_stratum:
                raise ValueError('Insufficient dataset strata')
            used_participants.update(participant for participant, _ in matches)
            selected.extend((verse, label, row) for _, row in matches)
    return selected


def prepare(destination, per_stratum=2, seed=None):
    destination.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(BASE + 'metadata.csv', timeout=30) as response:
        rows = list(csv.DictReader(io.StringIO(response.read().decode('utf-8-sig'))))
    selected = select_rows(rows, per_stratum, seed)

    cases = []
    for index, (verse, label, row) in enumerate(selected):
        with urllib.request.urlopen(BASE + urllib.parse.quote(row['file_name']),
                                    timeout=45) as response:
            raw = response.read()
        wave = destination / f'clip{index}.wav'
        try:
            wave.write_bytes(raw)
            subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(wave),
                            '-ac', '1', '-ar', '16000', '-f', 'f32le',
                            str(destination / f'clip{index}.f32')], check=True)
        finally:
            wave.unlink(missing_ok=True)
        cases.append({'ayah': f'112:{verse}', 'label': label})
    (destination / 'cases.json').write_text(json.dumps(cases), encoding='utf-8')
    print(f'Prepared {len(cases)} labelled clips locally.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    parser.add_argument('--per-stratum', type=int, default=2)
    parser.add_argument('--seed', type=int)
    args = parser.parse_args()
    prepare(args.directory, args.per_stratum, args.seed)
