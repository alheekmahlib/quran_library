#!/usr/bin/env python3
"""Score decoded phonemes against Quran Lab's legal-reading lattice."""
import argparse
import importlib.util
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('benchmark_dir', type=Path)
parser.add_argument('upstream_scorer', type=Path)
args = parser.parse_args()
spec = importlib.util.spec_from_file_location('quran_lab_scorer', args.upstream_scorer)
scorer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scorer)
cases = json.loads((args.benchmark_dir / 'cases.json').read_text())
hypotheses = json.loads((args.benchmark_dir / 'hypotheses.json').read_text())
if len(cases) != len(hypotheses):
    raise ValueError('A hypothesis is required for every clip')
errors = units = 0
for case, hypothesis in zip(cases, hypotheses):
    lattice = json.loads(case['lattice'])
    reference = [token for token in case['ref_tj3'].split() if token != '|']
    tokens = [token for token in hypothesis['text'].split() if token != '|']
    if scorer.lattice_best(lattice, reference)[0] != 0:
        raise ValueError(f"Reference is outside the legal lattice: {case['id']}")
    distance, path = scorer.lattice_best(lattice, tokens)
    errors += distance
    units += len(path)
    print(f"{case['ayah']}: {distance} edits / {len(path)} units")
print(f'{len(cases)} clips: {errors}/{units} phoneme edits ({100 * errors / units:.2f}%)')
print('Recognition only; these correct clips cannot measure error-detection recall.')
