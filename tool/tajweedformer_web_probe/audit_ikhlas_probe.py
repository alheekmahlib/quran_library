#!/usr/bin/env python3
"""Summarize the pinned sample's annotation coverage, without audio output."""
import csv
import io
import urllib.request

from prepare_ikhlas_probe import BASE, select_rows


def main():
    with urllib.request.urlopen(BASE + 'metadata.csv', timeout=30) as response:
        rows = list(csv.DictReader(io.StringIO(response.read().decode('utf-8-sig'))))
    sample = select_rows(rows, per_stratum=10, seed=112)
    errors = [row for _, label, row in sample if label == '0']
    qalqalah = sum('قلقلة' in row['error_explanation'] for row in errors)
    multiple = sum(',' in row['error_location'] for row in errors)
    print(f'error-labelled clips={len(errors)}, mention qalqalah={qalqalah}, '
          f'multiple described locations={multiple}')


if __name__ == '__main__':
    main()
