#!/usr/bin/env python3
"""Extract public Quran Lab benchmark FLAC to temporary 16 kHz float PCM."""
import argparse
import json
import subprocess
from pathlib import Path

import pyarrow.parquet as parquet

parser = argparse.ArgumentParser()
parser.add_argument('parquet_file', type=Path)
parser.add_argument('output_dir', type=Path)
args = parser.parse_args()
args.output_dir.mkdir(parents=True, exist_ok=True)
rows = parquet.read_table(args.parquet_file).to_pylist()
cases = []
for index, row in enumerate(rows):
    if row['clip_is_error'] or row['audio']['bytes'] is None:
        raise ValueError('Expected public correct clips with embedded audio')
    flac = args.output_dir / f'clip{index}.flac'
    pcm = args.output_dir / f'clip{index}.f32'
    flac.write_bytes(row['audio']['bytes'])
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(flac),
                    '-ac', '1', '-ar', '16000', '-f', 'f32le', str(pcm)], check=True)
    flac.unlink()
    cases.append({key: row[key] for key in
                  ('id', 'ayah', 'ref_tj3', 'alt_tj3', 'lattice', 'duration')})
(args.output_dir / 'cases.json').write_text(json.dumps(cases, ensure_ascii=False))
print(f'Prepared {len(cases)} public correct clips')
