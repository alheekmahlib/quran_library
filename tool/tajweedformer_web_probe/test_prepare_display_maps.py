import unittest

from prepare_display_maps import map_words


class DisplayMapsTest(unittest.TestCase):
    def test_merges_pronunciation_text_parts_within_one_display_word(self):
        self.assertEqual(map_words(['ab', 'c', 'de'], ['abc', 'de'], '1:1'),
                         [0, 0, 1])

    def test_rejects_crossed_boundaries_and_different_text(self):
        with self.assertRaises(ValueError):
            map_words(['abc', 'de'], ['ab', 'cde'], '1:1')
        with self.assertRaises(ValueError):
            map_words(['abc'], ['xyz'], '1:1')

    def test_reviewed_spelling_exception_is_specific(self):
        source = ['a', 'b', 'c', 'فادرتم']
        target = ['a', 'b', 'c', 'فادرءتم']
        self.assertEqual(map_words(source, target, '2:72'), [0, 1, 2, 3])
        with self.assertRaises(ValueError):
            map_words(source, target, '2:73')
        with self.assertRaises(ValueError):
            map_words(source, ['a', 'b', 'c', 'فادركم'], '2:72')


if __name__ == '__main__':
    unittest.main()
