import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/core/services/tasmee_reference_store.dart';
import 'package:quran_library/src/tasmee/engine/live_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';
import 'package:quran_library/src/tasmee/engine/models/tasmee_tolerance.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_coverage.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference_store.dart';
import 'package:quran_library/src/tasmee/engine/tasmee_error_kind.dart';

import 'tajweedformer_reference_store_test.dart' show ReferenceClient;

const metadata = {
  'blank': 0,
  'wordBar': 1,
  'defaultContext': 'ctx',
  'tokens': [
    '<blk>',
    '|',
    'ء',
    'ب',
    'ت',
    'ث',
    'ج',
    'ح',
    'خ',
    'د',
    'ذ',
    'ر',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ع',
    'غ',
    'ف',
    'ق',
    'ك',
    'ل',
    'م',
    'ن',
    'ه',
    'و',
    'ي',
    'ں',
    'a',
    'i',
    'u',
    'aa',
    'ii',
    'uu',
    '<foreign>'
  ],
};

class StreamingClient extends ReferenceClient {
  @override
  Map<String, dynamic> calibration() => {
        'data': {
          'format': 'quranlab.tajweed-calibration/1',
          'contexts': {
            'ctx': {
              'fusion': {
                'heads': ['log_probs', 'inter1_log_probs'],
                'a': {'default': 0.5},
                'clip': [-30, 30],
                'inter1_prep': "'|' merged into blank",
              },
              'sites': {
                for (final name in [
                  'cons_sub',
                  'cons_del',
                  'vowel_sub',
                  'vowel_del',
                  'vowel_ins',
                  'short_to_long',
                  'long_to_short'
                ])
                  name: {
                    'status': 'off',
                    'thresholds': {'balanced': 0.5}
                  }
              },
            },
          },
        },
      };

  @override
  Future<void> push(Float32List value) async {
    await super.push(value);
    final ref = await reference(1, 1);
    final ids = (ref['units'] as List).cast<int>();
    stream.add({
      'tokens': [
        for (var i = 0; i < ids.length; i++)
          {
            'id': ids[i],
            'name': (metadata['tokens'] as List)[ids[i]],
            'firstMs': i * 100,
            'lastMs': i * 100 + 100
          }
      ],
      'settled': ids.length,
      'isFinal': false
    });
  }

  @override
  Future<Map<String, dynamic>> finish() async {
    final ref = await reference(1, 1);
    final ids = (ref['units'] as List).cast<int>();
    stream.add({
      'tokens': [
        for (var i = 0; i < ids.length; i++)
          {
            'id': ids[i],
            'name': (metadata['tokens'] as List)[ids[i]],
            'firstMs': i * 100,
            'lastMs': i * 100 + 100
          }
      ],
      'settled': ids.length,
      'isFinal': true
    });
    final head = {
      'frames': 60,
      'classes': 38,
      'frameMs': 40,
      'values': List<double>.filled(38 * 60, -1)
    };
    return {'log_probs': head, 'inter1_log_probs': head};
  }
}

class FailingStreamingClient extends StreamingClient {
  @override
  Future<void> push(Float32List value) async => throw StateError('push failed');
}

class MissingFinalClient extends StreamingClient {
  @override
  Future<Map<String, dynamic>> finish() async {
    final head = {
      'frames': 60,
      'classes': 38,
      'frameMs': 40,
      'values': List<double>.filled(38 * 60, -1),
    };
    return {'log_probs': head, 'inter1_log_probs': head};
  }
}

class DelayedReferenceClient extends StreamingClient {
  final gate = Completer<void>();
  @override
  Future<Map<String, dynamic>> reference(int surah, int ayah) async {
    await gate.future;
    return super.reference(surah, ayah);
  }
}

class DelayedFinishClient extends StreamingClient {
  final gate = Completer<void>();
  @override
  Future<Map<String, dynamic>> finish() async {
    await gate.future;
    return super.finish();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('streams a take through the reference and returns a positioned result',
      () async {
    final client = StreamingClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    final oldStore = TasmeeReferenceStore.instance;
    await oldStore.load();
    final range = oldStore.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    final positions = <(int, int)>[];
    final matched = <Set<({int verseIndex, int wordIndex})>>[];
    engine.onMatchedWords = (words, _) => matched.add(words);
    engine.startLive(
        range: range, onRangeWord: (v, w) => positions.add((v, w)));
    engine.feedPcm(Float32List(160));
    final frame = await engine.endLive();
    final result = await engine.evaluateLive(
        config: const MuaalemConfig(), range: range, frame: frame);
    expect(positions, isNotEmpty);
    expect(matched.last.length, 4);
    expect(result.start?.suraIdx, 1);
    expect(result.matchedWordSpans.length, 4);
    expect(result.errors, isEmpty);
    // تلاوة نظيفة = تقييم مكتمل (كما تحقق ميدانيًا 2026-11-16)؛ يجري عرضه
    // وقبوله كالنموذج القديم، بينما سياسة إعادة النطق تبقى متحفظة لـ V4.
    expect(result.assessmentComplete, isTrue);
    expect(result.isFullyCorrect, isTrue);
    expect(isRecitationAcceptable(result), isTrue);
    // الدالتان التاليتان تتبعان الاكتمال العام؛ سياسة V4 الفعلية في
    // المتحكم تبقى متحفظة (InconclusiveWordRetryPolicy) لأن التحقق
    // الميداني لم يشمل لقطات الكلمة المفردة.
    expect(isWordRetryAcceptable(result), isTrue);
    expect(
        isContextWordRetryAcceptable(result,
            targetWordIdx: 0, targetUnitCount: 5),
        isTrue);
    // كل الفئات مغلقة بهذه المعايرة: تغطية النتيجة تقول «لم تُقيَّم»
    // بسببها، فلا تُقرأ القوائم الفارغة اجتيازًا.
    expect(result.coverage, isNotNull);
    expect(result.coverage!.categories.keys,
        containsAll(tajweedFormerCoverageCategoryKeys));
    expect(
      result.coverage!.categories['cons_sub']!.reason,
      TajweedFormerCoverageReason.calibrationDisabled,
    );
    expect(
      result.coverage!.categories['madd']!.reason,
      TajweedFormerCoverageReason.missingHead,
      reason: 'this fake exposes no timing head at all',
    );
    expect(
      result.coverage!.categories['ghunna']!.reason,
      TajweedFormerCoverageReason.signalUnsupported,
    );
    await engine.close();
  });

  test('session propagates skipped vowel and madd coverage', () async {
    final client = StreamingClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    final references = TasmeeReferenceStore.instance;
    await references.load();
    final range = references.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    engine.startLive(range: range);
    engine.feedPcm(Float32List(160));
    final frame = await engine.endLive();
    final result = await engine.evaluateLive(
      config: const MuaalemConfig(
          tajweedFormerTolerance: TasmeeToleranceProfile(
              tashkeel: TasmeeToleranceLevel.skip,
              madd: TasmeeToleranceLevel.skip)),
      range: range,
      frame: frame,
    );
    // تجاهل محور لا يجعل اللقطة غير مكتملة ما لم يقع فرق عليه.
    expect(result.assessmentComplete, isTrue);
    expect(result.coverage!.categories['vowel_sub']!.reason,
        TajweedFormerCoverageReason.skippedByUser);
    expect(result.coverage!.categories['madd']!.reason,
        TajweedFormerCoverageReason.skippedByUser);
    expect(result.coverage!.categories['cons_sub']!.reason,
        TajweedFormerCoverageReason.calibrationDisabled);
    await engine.close();
  });

  test('a failed PCM push cancels the take instead of producing a result',
      () async {
    final client = FailingStreamingClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    final oldStore = TasmeeReferenceStore.instance;
    await oldStore.load();
    final range = oldStore.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    engine.startLive(range: range);
    engine.feedPcm(Float32List(160));
    await expectLater(engine.endLive(), throwsStateError);
    expect(client.cancelled, isTrue);
    await engine.close();
  });

  test('evaluates a 16 kHz PCM WAV without microphone capture', () async {
    final client = StreamingClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    final oldStore = TasmeeReferenceStore.instance;
    await oldStore.load();
    final range = oldStore.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    final wav = Uint8List(44 + 320);
    final bytes = ByteData.sublistView(wav);
    wav.setRange(0, 4, 'RIFF'.codeUnits);
    bytes.setUint32(4, wav.length - 8, Endian.little);
    wav.setRange(8, 12, 'WAVE'.codeUnits);
    wav.setRange(12, 16, 'fmt '.codeUnits);
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, 16000, Endian.little);
    bytes.setUint32(28, 32000, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    wav.setRange(36, 40, 'data'.codeUnits);
    bytes.setUint32(40, 320, Endian.little);
    final result = await engine.correctRecitation(wavBytes: wav, range: range);
    expect(result.hasMatch, isTrue);
    expect(result.matchedWordSpans.length, 4);
    await engine.close();
  });

  test('cancelling during preparation prevents an active take', () async {
    final client = DelayedReferenceClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    final oldStore = TasmeeReferenceStore.instance;
    await oldStore.load();
    final range = oldStore.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    engine.startLive(range: range);
    final ready = engine.waitUntilReady();
    final cancelling = engine.cancelLive();
    client.gate.complete();
    await expectLater(ready, throwsStateError);
    await cancelling;
    expect(engine.hasActiveTake, isFalse);
    expect(client.cancelled, isTrue);
    await engine.close();
  });

  test('finish and cancellation prevent overlapping V4 takes', () async {
    final client = DelayedFinishClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    final oldStore = TasmeeReferenceStore.instance;
    await oldStore.load();
    final range = oldStore.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    engine.startLive(range: range);
    await engine.waitUntilReady();
    engine.feedPcm(Float32List(160));
    final finishing = engine.endLive();
    expect(() => engine.startLive(range: range), throwsStateError);
    final cancelling = engine.cancelLive();
    expect(() => engine.startLive(range: range), throwsStateError);
    client.gate.complete();
    await finishing;
    await cancelling;
    engine.startLive(range: range);
    await engine.waitUntilReady();
    expect(engine.hasActiveTake, isTrue);
    await engine.close();
  });

  test('missing final transcription cannot be evaluated after finish fails',
      () async {
    final client = MissingFinalClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    final oldStore = TasmeeReferenceStore.instance;
    await oldStore.load();
    final range = oldStore.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    engine.startLive(range: range);
    engine.feedPcm(Float32List(160));
    await expectLater(engine.endLive(), throwsStateError);
    final result = await engine.evaluateLive(
        config: const MuaalemConfig(),
        range: range,
        frame: const LiveRecognitionFrame(units: [], timestamps: []));
    expect(result.hasMatch, isFalse);
    await engine.close();
  });

  test('cancelling a finished take invalidates its evaluation data', () async {
    final client = StreamingClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    final oldStore = TasmeeReferenceStore.instance;
    await oldStore.load();
    final range = oldStore.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    engine.startLive(range: range);
    engine.feedPcm(Float32List(160));
    final frame = await engine.endLive();
    await engine.cancelLive();
    final result = await engine.evaluateLive(
        config: const MuaalemConfig(), range: range, frame: frame);
    expect(result.hasMatch, isFalse);
    await engine.close();
  });

  test('does not evaluate a non-Hafs configuration against Hafs references',
      () async {
    final client = StreamingClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    final result = await engine.correctRecitation(
      wavBytes: Uint8List(0),
      config: const MuaalemConfig(rewaya: 'warsh'),
    );
    expect(result.hasMatch, isFalse);
    expect(result.noMatchMessage, contains('حفص'));
    await engine.close();
  });

  test('word retry uses only selected V4 display words and cannot auto-pass',
      () async {
    final client = StreamingClient();
    final store = await TajweedFormerReferenceStore.load(
        client: client, metadata: metadata);
    final oldStore = TasmeeReferenceStore.instance;
    await oldStore.load();
    final full = oldStore.buildRange([(suraIdx: 1, ayaIdx: 1)])!;
    final range =
        QuranReferenceRange.fromWordWithContext(full.verses.first, 3)!;
    expect(range.selectedDisplayedWords, {
      (verseIndex: 0, wordIndex: 2),
      (verseIndex: 0, wordIndex: 3),
    });
    final engine = TajweedFormerRecitationEngine(
        client: client, metadata: metadata, store: store);
    final matches = <Set<({int verseIndex, int wordIndex})>>[];
    engine.onMatchedWords = (words, _) => matches.add(words);
    engine.startLive(range: range);
    engine.feedPcm(Float32List(160));
    final frame = await engine.endLive();
    expect(matches.last.every((word) => word.wordIndex >= 2), isTrue);
    final result = await engine.evaluateLive(
        config: const MuaalemConfig(), range: range, frame: frame);
    expect(result.matchedWordSpans, isNotEmpty);
    expect(result.matchedWordSpans.every((word) => word.wordIdx >= 2), isTrue);
    expect(isWordRetryAcceptable(result), isFalse);
    await engine.close();
  });
}
