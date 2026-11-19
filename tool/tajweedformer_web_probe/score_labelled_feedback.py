#!/usr/bin/env python3
"""Aggregate independently labelled feedback without printing source data.

Coverage must represent actual assessment, not recognition of a word.
"""
import argparse
import json
from collections import defaultdict


def score(rows):
    if not isinstance(rows, list):
        raise ValueError('observations must be a list')
    counts = defaultdict(lambda: dict(tp=0, fp=0, fn=0, tn=0, unassessed=0,
                                      unassessed_positive=0))
    seen = set()
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError('invalid observation')
        case, verse, word, category = (row.get(k) for k in
                                        ('case', 'verse', 'word', 'category'))
        if (not isinstance(case, str) or not case or
                not isinstance(verse, str) or not verse or
                type(word) is not int or word < 0 or
                not isinstance(category, str) or not category):
            raise ValueError('invalid observation identity')
        identity = (case, verse, word, category)
        if identity in seen:
            raise ValueError('duplicate observation')
        seen.add(identity)
        assessed, expected, flagged = (row.get(k) for k in
                                        ('assessed', 'expected', 'flagged'))
        if any(type(value) is not bool for value in (assessed, expected, flagged)):
            raise ValueError('observation flags must be booleans')
        if not assessed and flagged:
            raise ValueError('an unassessed observation cannot be flagged')
        outcome = ('unassessed' if not assessed else
                   'tp' if expected and flagged else
                   'fn' if expected else 'fp' if flagged else 'tn')
        counts[category][outcome] += 1
        if not assessed and expected:
            counts[category]['unassessed_positive'] += 1

    def report(values):
        result = dict(values)
        tp, fp, fn = (values[k] for k in ('tp', 'fp', 'fn'))
        result['precision'] = tp / (tp + fp) if tp + fp else None
        result['recall'] = tp / (tp + fn) if tp + fn else None
        total_positive = tp + fn + values['unassessed_positive']
        result['end_to_end_recall'] = tp / total_positive if total_positive else None
        return result

    totals = dict(tp=0, fp=0, fn=0, tn=0, unassessed=0, unassessed_positive=0)
    for values in counts.values():
        for key in totals:
            totals[key] += values[key]
    return {'total': report(totals),
            'categories': {key: report(counts[key]) for key in sorted(counts)}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('observations', help='local JSON file containing observations')
    args = parser.parse_args()
    with open(args.observations, encoding='utf-8') as source:
        data = json.load(source)
    print(json.dumps(score(data['observations']), ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
