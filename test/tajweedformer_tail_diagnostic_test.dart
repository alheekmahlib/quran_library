import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_alignment.dart';

void main() {
  const directory = String.fromEnvironment('TAJWEED_LABELLED_PATH');
  test('diagnose trailing-speech handling on labelled captures', () {
    final root = Directory(directory);
    final captures =
        jsonDecode(File('${root.path}/sdk-captures.json').readAsStringSync())
            as Map;
    final items = captures['captures'] as List;
    final names = (captures['info'] as Map)['tokens'] as List;
    final blank = (captures['info'] as Map)['blank'] as int;
    final bar = (captures['info'] as Map)['wordBar'] as int;
    for (var i = 0; i < items.length; i++) {
      final item = Map<String, dynamic>.from(items[i] as Map);
      final tokens = (item['sample'] as Map)['tokens'] as List;
      final reference =
          ((item['reference'] as Map)['units'] as List).cast<int>();
      final heard = tokens
          .map((t) => (t as Map)['id'] as int)
          .where((id) => id != blank && id != bar)
          .toList();
      if (heard.length <= reference.length) {
        // ignore: avoid_print
        print(
            'clip[$i] ${item['ayah']}: heard=${heard.length} ref=${reference.length} (fits)');
        continue;
      }
      final ops = alignTajweedFormerTokens(reference, heard);
      final trailingInserts = <int>[];
      for (final op in ops.reversed) {
        if (op.kind != TajweedFormerAlignmentKind.insert) break;
        trailingInserts.add(op.predictedIndex!);
      }
      final matchedRef = ops
          .where((op) => op.referenceIndex != null)
          .map((op) => op.referenceIndex!)
          .toList(growable: false);
      final covered = matchedRef.toSet().length;
      // ignore: avoid_print
      print('clip[$i] ${item['ayah']}: heard=${heard.length} '
          'ref=${reference.length} trailingPureInserts=${trailingInserts.length} '
          'refCovered=$covered/${reference.length}');
      final kinds = <String, int>{};
      for (final op in ops) {
        kinds[op.kind.name] = (kinds[op.kind.name] ?? 0) + 1;
      }
      // ignore: avoid_print
      print('   ops=$kinds lastRefUnits='
          '${reference.sublist(reference.length - 4).map((u) => names[u]).toList()}');
      // أين آخر match للمرجع؟
      final lastRefOp = ops.lastWhere(
          (op) => op.referenceIndex == reference.length - 1,
          orElse: () => throw 'no last');
      // ignore: avoid_print
      print('   last ref op: ${lastRefOp.kind.name} @heard=${lastRefOp.predictedIndex}');
    }
  }, skip: directory.isEmpty ? 'set TAJWEED_LABELLED_PATH' : false);
}
