import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/controller/tasmee_ctrl.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/recitation_session.dart';

/// محرّك خامل — الجلسات هنا لا تُطلق شيئًا؛ الاختبار للتنسيق وحده.
class _IdleEngine implements RecitationEngine {
  @override
  Future<RecitationResult> correctRecitation({
    required Uint8List wavBytes,
    MuaalemConfig config = const MuaalemConfig(),
    double errorRatio = 0.1,
    int? suraIdx,
    int? ayaIdx,
    QuranReferenceRange? range,
    String? referenceText,
  }) async {
    throw StateError('not expected');
  }

  @override
  Future<bool> isHealthy() async => true;

  @override
  String? getVerseText({required int suraIdx, required int ayaIdx}) => null;

  @override
  void dispose() {}
}

RecitationSession _session() =>
    RecitationSession(config: const MuaalemConfig(), engine: _IdleEngine());

void main() {
  test('a deferred stop only acts while its issuing session still owns',
      () {
    final issuer = _session();
    expect(
      tasmeeDeferredStopAppliesToCurrentSession(
          current: issuer, issuer: issuer, recording: true),
      isTrue,
      reason: 'same session still recording: the stop applies',
    );
    expect(
      tasmeeDeferredStopAppliesToCurrentSession(
          current: issuer, issuer: issuer, recording: false),
      isFalse,
      reason: 'the session already stopped on its own',
    );
  });

  test('a stale callback cannot stop a replacement session', () {
    final old = _session();
    final replacement = _session();
    expect(
      tasmeeDeferredStopAppliesToCurrentSession(
          current: replacement, issuer: old, recording: true),
      isFalse,
      reason: 'the 800 ms delay outlived the old session; the new one is '
          'recording and must not be stopped by the old callback',
    );
    expect(
      tasmeeDeferredStopAppliesToCurrentSession(
          current: null, issuer: old, recording: true),
      isFalse,
      reason: 'no current session at all',
    );
  });
}
