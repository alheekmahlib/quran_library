part of '/quran.dart';

typedef QpcV4AyahUqResolver = int Function({
  required int surahNumber,
  required int ayahNumber,
});

class QpcV4PageRenderer {
  const QpcV4PageRenderer({
    required this.store,
    required this.ayahUqResolver,
  });

  final QpcV4AssetsStore store;
  final QpcV4AyahUqResolver ayahUqResolver;

  List<QpcV4RenderBlock> buildPage({required int pageNumber}) {
    final lines = store.linesByPage[pageNumber];
    if (lines == null || lines.isEmpty) return const <QpcV4RenderBlock>[];

    final endMaps = _buildAyahEndMaps(lines);
    final endWordIdByAyahKey = endMaps.endWordIdByAyahKey;
    final maxWordIndexByAyahKey = endMaps.maxWordIndexByAyahKey;

    final blocks = <QpcV4RenderBlock>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      switch (line.lineType) {
        case QpcV4LineType.surahName:
          if (line.surahNumber != null) {
            blocks.add(QpcV4SurahHeaderBlock(line.surahNumber!));
          }
          break;

        case QpcV4LineType.basmallah:
          final inferred = _inferBasmalahSurahNumber(lines: lines, index: i);
          if (inferred != null) {
            blocks.add(QpcV4BasmallahBlock(inferred));
          }
          break;

        case QpcV4LineType.ayah:
          final rangeStart = line.firstWordId;
          final rangeEnd = line.lastWordId;
          if (rangeStart == null || rangeEnd == null) break;

          final segments = _buildAyahSegmentsForLine(
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            endWordIdByAyahKey: endWordIdByAyahKey,
            maxWordIndexByAyahKey: maxWordIndexByAyahKey,
          );
          if (segments.isNotEmpty) {
            blocks.add(QpcV4AyahLineBlock(
                isCentered: line.isCentered, segments: segments));
          }
          break;
      }
    }

    return blocks;
  }

  ({Map<int, int> endWordIdByAyahKey, Map<int, int> maxWordIndexByAyahKey})
      _buildAyahEndMaps(List<QpcV4AyahInfoLine> lines) {
    final lastWordIdSeenByAyahKey = <int, int>{};
    final maxWordIndexByAyahKey = <int, int>{};

    for (final line in lines) {
      if (line.lineType != QpcV4LineType.ayah) continue;
      final start = line.firstWordId;
      final end = line.lastWordId;
      if (start == null || end == null) continue;

      for (var wordId = start; wordId <= end; wordId++) {
        final w = store.wordsById[wordId];
        if (w == null) continue;
        final key = _ayahKey(w.surah, w.ayah);
        lastWordIdSeenByAyahKey[key] = wordId;
        final prevMax = maxWordIndexByAyahKey[key];
        if (prevMax == null || w.wordIndex > prevMax) {
          maxWordIndexByAyahKey[key] = w.wordIndex;
        }
      }
    }

    // ملفات QPC غالباً تضيف عنصراً أخيراً داخل نفس (سورة/آية) يمثل رقم الآية.
    // نعتبره أعلى wordIndex داخل الآية، ونحدد نهاية الآية على آخر كلمة حقيقية.
    final endWordIdByAyahKey = <int, int>{};
    for (final entry in lastWordIdSeenByAyahKey.entries) {
      final key = entry.key;
      final lastWordId = entry.value;
      final maxIndex = maxWordIndexByAyahKey[key];
      if (maxIndex == null) {
        endWordIdByAyahKey[key] = lastWordId;
        continue;
      }

      var effectiveEnd = lastWordId;
      while (effectiveEnd > 0) {
        final w = store.wordsById[effectiveEnd];
        if (w == null) break;
        if (_ayahKey(w.surah, w.ayah) != key) break;
        if (w.wordIndex != maxIndex) break;
        effectiveEnd -= 1;
      }

      endWordIdByAyahKey[key] = effectiveEnd > 0 ? effectiveEnd : lastWordId;
    }

    return (
      endWordIdByAyahKey: endWordIdByAyahKey,
      maxWordIndexByAyahKey: maxWordIndexByAyahKey,
    );
  }

  List<QpcV4AyahSegment> _buildAyahSegmentsForLine({
    required int rangeStart,
    required int rangeEnd,
    required Map<int, int> endWordIdByAyahKey,
    required Map<int, int> maxWordIndexByAyahKey,
  }) {
    final segments = <QpcV4AyahSegment>[];

    int? currentSurah;
    int? currentAyah;
    int? currentKey;
    int? lastWordIdInSegment;
    final buffer = StringBuffer();

    void flush() {
      if (currentKey == null || currentSurah == null || currentAyah == null) {
        buffer.clear();
        return;
      }
      final glyphs = buffer.toString();
      if (glyphs.isEmpty) {
        buffer.clear();
        return;
      }
      final uq = ayahUqResolver(
        surahNumber: currentSurah,
        ayahNumber: currentAyah,
      );
      if (uq == 0) {
        buffer.clear();
        return;
      }
      final endWordId = endWordIdByAyahKey[currentKey];
      final isAyahEnd = endWordId != null && lastWordIdInSegment == endWordId;
      segments.add(
        QpcV4AyahSegment(
          ayahUq: uq,
          surahNumber: currentSurah,
          ayahNumber: currentAyah,
          glyphs: glyphs,
          isAyahEnd: isAyahEnd,
        ),
      );
      buffer.clear();
    }

    for (var wordId = rangeStart; wordId <= rangeEnd; wordId++) {
      final w = store.wordsById[wordId];
      if (w == null) continue;
      final key = _ayahKey(w.surah, w.ayah);

      // تجاهل عنصر "رقم الآية" الموجود كآخر wordIndex في qpc-v4.json.
      final maxIndex = maxWordIndexByAyahKey[key];
      if (maxIndex != null && w.wordIndex == maxIndex) {
        continue;
      }

      if (currentKey == null) {
        currentKey = key;
        currentSurah = w.surah;
        currentAyah = w.ayah;
      } else if (key != currentKey) {
        flush();
        currentKey = key;
        currentSurah = w.surah;
        currentAyah = w.ayah;
      }

      // فصل خفيف بين الكلمات بدون letterSpacing.
      // استخدمنا Narrow No‑Break Space لتفادي التفاف/كسر السطر داخل نفس line block.
      if (buffer.isNotEmpty) {
        buffer.write('\u202F');
      }
      buffer.write(w.text);
      lastWordIdInSegment = wordId;
    }

    flush();
    return segments;
  }

  int? _inferBasmalahSurahNumber({
    required List<QpcV4AyahInfoLine> lines,
    required int index,
  }) {
    for (var i = index + 1; i < lines.length; i++) {
      final next = lines[i];
      if (next.lineType != QpcV4LineType.ayah) continue;
      final start = next.firstWordId;
      if (start == null) continue;
      final word = store.wordsById[start];
      return word?.surah;
    }
    return null;
  }

  int _ayahKey(int surah, int ayah) => surah * 1000 + ayah;
}
