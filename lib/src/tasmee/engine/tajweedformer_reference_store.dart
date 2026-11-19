import 'dart:convert';

import 'package:archive/archive.dart' show GZipDecoder;

import 'asset_loader.dart';
import 'tajweedformer_client.dart';
import 'tajweedformer_lattice.dart';
import 'tajweedformer_lattice_loader.dart';
import 'tajweedformer_reference.dart';

/// Loads the bundled V4 references and checks each verse against the SDK.
class TajweedFormerReferenceStore {
  TajweedFormerReferenceStore._(
      this._client, this._metadata, this._lattice, this._maps, this._timing);

  final TajweedFormerInferenceClient _client;
  final Map<String, dynamic> _metadata;
  final Map<String, dynamic> _lattice;
  final Map<String, dynamic> _maps;
  final Map<String, dynamic> _timing;

  /// Public phonetic timing metadata for a canonical full-verse reading.
  Map<String, dynamic>? timingReference(int surah, int ayah) {
    final raw = _timing['$surah:$ayah'];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  static Future<TajweedFormerReferenceStore> load({
    required TajweedFormerInferenceClient client,
    required Map<String, dynamic> metadata,
  }) async {
    Future<Map<String, dynamic>> read(String path) async {
      final bytes = await loadPackageAssetBytes(path);
      final data =
          jsonDecode(utf8.decode(const GZipDecoder().decodeBytes(bytes)));
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid V4 asset');
      }
      return data;
    }

    final assets = await Future.wait([
      read('assets/quran_lab/tajweedformer_v4_lattice.json.gz'),
      read('assets/quran_lab/tajweedformer_v4_qpc_maps.json.gz'),
      read('assets/quran_lab/tajweedformer_v4_timing_reference.json.gz'),
    ]);
    if (assets[1]['format'] != 'quran-library.v4-qpc-map.v1' ||
        assets[1]['maps'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid V4 word maps');
    }
    if (assets[2]['format'] != 'quran-library.v4-timing-reference.v1' ||
        assets[2]['verses'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid V4 timing reference');
    }
    return TajweedFormerReferenceStore._(
        client,
        metadata,
        assets[0],
        assets[1]['maps'] as Map<String, dynamic>,
        assets[2]['verses'] as Map<String, dynamic>);
  }

  Future<
          ({
            List<TajweedFormerReferenceUnit> reference,
            List<TajweedFormerLatticeWord> lattice
          })>
      verse(
          {required int surah,
          required int ayah,
          required int verseIndex}) async {
    final rawMap = _maps['$surah:$ayah'];
    final rawNames = _metadata['tokens'];
    final blank = _metadata['blank'];
    final wordBar = _metadata['wordBar'];
    if (rawMap is! List ||
        rawMap.isEmpty ||
        rawMap.any((e) => e is! int) ||
        rawNames is! List ||
        rawNames.any((e) => e is! String) ||
        blank is! int ||
        wordBar is! int) {
      throw const FormatException('Missing V4 reference metadata');
    }
    final map = rawMap.cast<int>();
    final sdk = await _client.reference(surah, ayah);
    final lattice = loadTajweedFormerLatticeVerse(
      data: _lattice,
      surah: surah,
      ayah: ayah,
      verseIndex: verseIndex,
      tokenNames: rawNames.cast<String>(),
      blankId: blank,
      wordBarId: wordBar,
      sdkReference: sdk,
      displayWordMap: map,
      displayWordCount: map.last + 1,
    );
    final sdkVerse = TajweedFormerReferenceVerse.fromWebReference(
      surah: surah,
      ayah: ayah,
      reference: sdk,
      wordBarId: wordBar,
      blankId: blank,
      expectedWordCount: map.length,
    );
    final units = buildTajweedFormerReference(
      verses: [sdkVerse],
      blankId: blank,
      wordBarId: wordBar,
      expectedWordCounts: [map.last + 1],
      displayWordMaps: [map],
    );
    return (
      reference: List<TajweedFormerReferenceUnit>.unmodifiable(
          units.map((u) => TajweedFormerReferenceUnit(
                tokenId: u.tokenId,
                verseIndex: verseIndex,
                wordIndex: u.wordIndex,
              ))),
      lattice: lattice,
    );
  }
}
