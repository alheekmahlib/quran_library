#!/usr/bin/env python3
"""Make temporary fixtures comparing Dart with the public reference scorer."""
import argparse
import importlib.util
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('benchmark_dir', type=Path)
parser.add_argument('upstream_scorer', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
spec = importlib.util.spec_from_file_location('quran_lab_scorer', args.upstream_scorer)
scorer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scorer)
cases = json.loads((args.benchmark_dir / 'cases.json').read_text())
hypotheses = json.loads((args.benchmark_dir / 'hypotheses.json').read_text())
if len(cases) != len(hypotheses):
    raise ValueError('A hypothesis is required for every clip')
fixtures = []
for case, hypothesis in zip(cases, hypotheses):
    lattice = json.loads(case['lattice'])
    heard = [token for token in hypothesis['text'].split() if token != '|']
    vocabulary = {token: index for index, token in enumerate(sorted({
        token for word in lattice['words'] for form in word['forms']
        for token in form['tj3']
    } | set(heard)))}
    words = [{
        'index': word['w'],
        'forms': [{
            'left': 'stop' if form['L'] == 'ibtida' else 'connected',
            'right': 'stop' if form['R'] == 'waqf' else 'connected',
            'tokens': [vocabulary[token] for token in form['tj3']],
        } for form in word['forms']],
    } for word in lattice['words']]
    distance, _ = scorer.lattice_best(lattice, heard)
    fixtures.append({'id': case['ayah'], 'words': words,
                     'heard': [vocabulary[token] for token in heard],
                     'distance': distance})
args.output.write_text(json.dumps(fixtures, ensure_ascii=False))
