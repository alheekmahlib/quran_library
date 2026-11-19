#!/usr/bin/env python3
"""Compare V3 and V4 recognition on the same public, correct recordings.

Requires sherpa-onnx 1.13.8, numpy, quran-p2g and the upstream benchmark
scorer. This compares recognition, not the application's correctness verdicts.
"""
import argparse
import importlib.util
import json
from pathlib import Path

import numpy as np
import quran_p2g as p2g
from quran_p2g.formats import tokenize
import sherpa_onnx

parser = argparse.ArgumentParser()
parser.add_argument('benchmark_dir', type=Path)
parser.add_argument('--model', required=True, type=Path)
parser.add_argument('--tokens', required=True, type=Path)
parser.add_argument('--scorer', required=True, type=Path)
args = parser.parse_args()
if sherpa_onnx.__version__ != '1.13.8':
    raise ValueError('Use sherpa-onnx 1.13.8 to match the library')
spec = importlib.util.spec_from_file_location('quran_lab_scorer', args.scorer)
scorer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scorer)
cases = json.loads((args.benchmark_dir / 'cases.json').read_text())
hypotheses = json.loads((args.benchmark_dir / 'hypotheses.json').read_text())
if not cases or len(cases) != len(hypotheses):
    raise ValueError('A V4 hypothesis is required for every clip')

recognizer = sherpa_onnx.OnlineRecognizer.from_zipformer2_ctc(
    tokens=str(args.tokens), model=str(args.model), num_threads=2,
    sample_rate=16000, feature_dim=80, enable_endpoint_detection=True,
    rule1_min_trailing_silence=1.4, rule2_min_trailing_silence=1.2,
    rule3_min_utterance_length=20, decoding_method='greedy_search',
)
totals = {name: {'phone_edits': 0, 'reference_units': 0,
                 'word_edits': 0, 'reference_words': 0} for name in ('v3', 'v4')}
for index, (case, v4) in enumerate(zip(cases, hypotheses)):
    samples = np.fromfile(args.benchmark_dir / f'clip{index}.f32', dtype='<f4').astype(np.float64)
    if not len(samples) or not np.isfinite(samples).all():
        raise ValueError(f'Invalid audio for clip {index}')
    # Reproduce the current library's batch peak/RMS normalization and padding.
    peak = np.max(np.abs(samples))
    if peak >= 1e-6:
        samples *= 0.7 / peak
        rms = np.sqrt(np.mean(samples * samples))
        if rms < 0.03:
            samples = np.clip(samples * min(20, 0.06 / max(rms, 1e-6)), -1, 1)
    samples = np.concatenate([np.zeros(6400), samples]).astype(np.float32)
    stream = recognizer.create_stream()
    for at in range(0, len(samples), 1600):
        stream.accept_waveform(16000, samples[at:at + 1600])
        while recognizer.is_ready(stream):
            recognizer.decode_stream(stream)
    stream.accept_waveform(16000, np.zeros(8000, dtype=np.float32))
    stream.input_finished()
    while recognizer.is_ready(stream):
        recognizer.decode_stream(stream)
    v3_text = recognizer.get_result(stream)
    lattice = json.loads(case['lattice'])
    ground_truth = [token for token in case['ref_tj3'].split() if token != '|']
    if scorer.lattice_best(lattice, ground_truth)[0] != 0:
        raise ValueError(f"Reference outside legal lattice: {case['id']}")
    result = {}
    for name, text, fmt in (('v3', v3_text, 'muaalem'), ('v4', v4['text'], 'tj3')):
        # Quran Lab's phoneme-to-text tool puts the different alphabets into
        # a shared matching space and handles legal reading paths.
        distance, path = scorer.lattice_best(lattice, tokenize(text, fmt))
        converted = p2g.convert(text, ayah=case['ayah'], fmt=fmt)
        words = p2g.wer(converted, case['ayah'])
        values = {'phone_edits': distance, 'reference_units': len(path),
                  'word_edits': words.errors, 'reference_words': words.ref_words}
        result[name] = values
        for field, value in values.items():
            totals[name][field] += value
    print(f"{case['ayah']}: V3 {result['v3']['phone_edits']}/{result['v3']['reference_units']}, "
          f"V4 {result['v4']['phone_edits']}/{result['v4']['reference_units']} phoneme edits")
print(json.dumps({'clips': len(cases), 'totals': totals}, ensure_ascii=False))
print('Exploratory recognition only; this does not score the app\'s error correction.')
