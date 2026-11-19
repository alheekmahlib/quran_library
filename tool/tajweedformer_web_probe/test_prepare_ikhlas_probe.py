import unittest

from prepare_ikhlas_probe import select_rows


class SelectRowsTest(unittest.TestCase):
    def test_seeded_sample_is_balanced_unique_and_reproducible(self):
        rows = []
        for verse in range(1, 5):
            for label, suffix in (('0', 'F'), ('1', 'T')):
                for participant in range(40):
                    rows.append(dict(file_name=f'data/ID{participant}V{verse}{suffix}.wav',
                                     label=label, error_location='x'))
        first = select_rows(rows, per_stratum=2, seed=112)
        self.assertEqual(first, select_rows(rows, per_stratum=2, seed=112))
        self.assertEqual(len(first), 16)
        participants = [row['file_name'].split('ID')[1].split('V')[0]
                        for _, _, row in first]
        self.assertEqual(len(set(participants)), 16)
        for verse in range(1, 5):
            for label in ('0', '1'):
                self.assertEqual(sum(v == verse and value == label
                                     for v, value, _ in first), 2)

    def test_excludes_disagreements_and_missing_error_details(self):
        rows = [dict(file_name='ID1V1T.wav', label='0', error_location='x'),
                dict(file_name='ID2V1F.wav', label='0', error_location='')]
        with self.assertRaises(ValueError):
            select_rows(rows, 1, seed=1)


if __name__ == '__main__':
    unittest.main()
