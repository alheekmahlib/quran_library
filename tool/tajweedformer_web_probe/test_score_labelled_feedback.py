import unittest

from score_labelled_feedback import score


class LabelledFeedbackTest(unittest.TestCase):
    def test_scores_only_explicitly_assessed_words_and_categories(self):
        def row(word, expected, flagged, assessed=True, category='letters'):
            return dict(case='clip', verse='1:1', word=word, category=category,
                        expected=expected, flagged=flagged, assessed=assessed)

        result = score([
            row(0, True, True), row(1, False, True), row(2, True, False),
            row(3, False, False), row(4, True, False, assessed=False),
            row(4, True, True, category='madd'),
        ])
        self.assertEqual(result['categories']['letters'], dict(
            tp=1, fp=1, fn=1, tn=1, unassessed=1, unassessed_positive=1,
            precision=.5, recall=.5, end_to_end_recall=1 / 3))
        self.assertEqual(result['total']['tp'], 2)
        self.assertEqual(result['total']['unassessed'], 1)

    def test_no_positive_observations_leave_ratios_undefined(self):
        result = score([dict(case='a', verse='1:1', word=0, category='x',
                             assessed=True, expected=False, flagged=False)])
        self.assertIsNone(result['total']['precision'])
        self.assertIsNone(result['total']['recall'])

    def test_rejects_duplicates_and_impossible_coverage(self):
        row = dict(case='a', verse='1:1', word=0, category='x',
                   assessed=True, expected=True, flagged=True)
        with self.assertRaises(ValueError):
            score([row, row])
        with self.assertRaises(ValueError):
            score([{**row, 'assessed': False}])
        with self.assertRaises(ValueError):
            score([{**row, 'word': True}])


if __name__ == '__main__':
    unittest.main()
