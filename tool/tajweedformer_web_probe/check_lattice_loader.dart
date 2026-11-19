// Checks every prepared lattice verse against references exported from the SDK.
// Also checks a generated QPC map when supplied; accuracy needs device tests.
import 'dart:convert';
import 'dart:io';

import 'package:quran_library/src/tasmee/engine/tajweedformer_lattice_loader.dart';

void main(List<String> args) {
  if (args.length != 3) {
    throw ArgumentError(
        'Expected lattice, SDK reference, and QPC map JSON paths');
  }
  final lattice =
      jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>;
  final sdk =
      jsonDecode(File(args[1]).readAsStringSync()) as Map<String, dynamic>;
  final info = sdk['info'] as Map<String, dynamic>;
  final references = sdk['references'] as Map<String, dynamic>;
  final verses = lattice['verses'] as Map<String, dynamic>;
  final mapFile =
      jsonDecode(File(args[2]).readAsStringSync()) as Map<String, dynamic>;
  if (mapFile['format'] != 'quran-library.v4-qpc-map.v1') {
    throw StateError('Invalid QPC map format');
  }
  final maps = mapFile['maps'] as Map<String, dynamic>;
  if (references.length != 6236 ||
      verses.length != 6236 ||
      maps.length != 6236) {
    throw StateError('Expected all 6,236 verses in every input');
  }
  for (final entry in verses.entries) {
    final parts = entry.key.split(':').map(int.parse).toList();
    final map = (maps[entry.key] as List).cast<int>();
    final ref = references[entry.key];
    if (ref is! Map<String, dynamic>) throw StateError('Missing ${entry.key}');
    loadTajweedFormerLatticeVerse(
      data: lattice,
      surah: parts[0],
      ayah: parts[1],
      verseIndex: 0,
      tokenNames: (info['tokens'] as List).cast<String>(),
      blankId: info['blank'] as int,
      wordBarId: info['wordBar'] as int,
      sdkReference: ref,
      displayWordMap: map,
      displayWordCount: map.last + 1,
    );
  }
  stdout.writeln(
      'Loaded ${verses.length} verses against the SDK canonical references and QPC maps.');
}
