import unittest

from audit_word_mapping import boundaries


class BoundaryAuditTest(unittest.TestCase):
    def test_adjacent_source_words_can_share_one_display_word(self):
        self.assertEqual(boundaries(['ab', 'c', 'de'], ['abc', 'de']),
                         ([0, 0, 1], 'matched'))

    def test_rejects_a_source_word_crossing_a_display_boundary(self):
        self.assertEqual(boundaries(['abc', 'de'], ['ab', 'cde']),
                         (None, 'source_crosses_target_boundary'))

    def test_same_word_counts_do_not_prove_identity(self):
        self.assertEqual(boundaries(['ab', 'cd'], ['ab', 'ef']),
                         (None, 'text_mismatch'))

    def test_empty_normalized_word_is_rejected(self):
        self.assertEqual(boundaries(['123'], ['123']), (None, 'empty_word'))

    def test_repeated_words_keep_their_boundaries(self):
        self.assertEqual(boundaries(['ab', 'ab'], ['ab', 'ab']),
                         ([0, 1], 'matched'))


if __name__ == '__main__':
    unittest.main()
