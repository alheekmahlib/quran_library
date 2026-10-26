import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/live_recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/models/muaalem_config.dart';
import 'package:quran_library/src/tasmee/engine/models/recitation_result.dart';
import 'package:quran_library/src/tasmee/engine/quran_reference.dart';
import 'package:quran_library/src/tasmee/engine/recitation_engine.dart';
import 'package:quran_library/src/tasmee/engine/recitation_session.dart';
import 'package:quran_library/src/tasmee/engine/recitation_state.dart';
import 'package:quran_library/src/tasmee/engine/tasmee_error_kind.dart';
import 'package:record/record.dart';

/// مسجّل مزوّر — إذن متاح وبثّ فارغ (لا يلمس قنوات المنصة).
class _FakeRecorder implements AudioRecorder {
  @override
  Future<bool> hasPermission({bool request = true}) async => true;

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    return const Stream.empty();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// محرّك حي مزوّر — يحتفظ باستدعاءات startLive ليطلقها الاختبار يدويًا.
class _FakeLiveEngine implements RecitationEngine, LiveCapableRecitationEngine {
  void Function(int verseIdx, int wordIdx)? onRangeWord;
  void Function()? onEndpoint;

  @override
  void startLive({
    void Function(LiveRecognitionFrame frame)? onPartial,
    void Function()? onEndpoint,
    void Function(int wordIdx)? onWord,
    void Function(int verseIdx, int wordIdx)? onRangeWord,
    void Function(
      int verseIdx,
      int wordIdx,
      TasmeeErrorKind kind,
      TasmeeWordMistake? mistake,
    )? onWordDone,
    void Function()? onRangeComplete,
    int? suraIdx,
    int? ayaIdx,
    QuranReferenceRange? range,
  }) {
    this.onRangeWord = onRangeWord;
    this.onEndpoint = onEndpoint;
  }

  /// تقدّم مزيف يتحكم به الاختبار.
  double? progressOverride;

  @override
  double? get liveRangeProgress => progressOverride;

  @override
  void feedPcm(Float32List samples) {}

  @override
  Future<LiveRecognitionFrame> endLive() async {
    return const LiveRecognitionFrame(units: [], timestamps: []);
  }

  @override
  Future<RecitationResult> correctRecitation({
    required Uint8List wavBytes,
    MuaalemConfig config = const MuaalemConfig(),
    double errorRatio = 0.1,
    int? suraIdx,
    int? ayaIdx,
    QuranReferenceRange? range,
    String? referenceText,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isHealthy() async => true;

  @override
  String? getVerseText({required int suraIdx, required int ayaIdx}) => null;

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'C5: onRangeWord الذري — انتقال الآية يسلّم الفهرسين معًا متسقين لحظيًّا',
      () async {
    final engine = _FakeLiveEngine();
    final session = RecitationSession(
      config: const MuaalemConfig(),
      engine: engine,
      recorder: _FakeRecorder(),
    );

    // عند كل نداء يجب أن يحمل الحقلان معًا قيمَ النداء نفسه — لا قيمة
    // كلمة قديمة من الآية السابقة (كان يحدث مع عاملَي ever المنفصلين).
    final seen = <(int, int)>[];
    session.onRangeWord = (v, w) {
      expect(session.currentVerseIdx.value, v,
          reason: 'currentVerseIdx يجب أن يكون محدَّثًا لحظة النداء');
      expect(session.currentWordIdx.value, w,
          reason: 'currentWordIdx يجب أن يكون محدَّثًا لحظة النداء');
      seen.add((v, w));
    };

    await session.startLive();
    expect(session.state.value, RecitationState.recording);
    expect(engine.onRangeWord, isNotNull);

    // آية أولى من 5 كلمات حتى كلمتها الأخيرة (فهرس 4)، ثم انتقال
    // إلى آية ثانية من 8 كلمات — يجب ألا يظهر إلا زوج (1, 0).
    engine.onRangeWord!(0, 4);
    engine.onRangeWord!(1, 0);

    expect(seen, [(0, 4), (1, 0)]);
    expect(session.currentVerseIdx.value, 1);
    expect(session.currentWordIdx.value, 0);
  });

  test('C4-صمت: onEndpoint يُمرَّر من المحرّك وliveRangeProgress مكشوف',
      () async {
    final engine = _FakeLiveEngine();
    final session = RecitationSession(
      config: const MuaalemConfig(),
      engine: engine,
      recorder: _FakeRecorder(),
    );
    var endpointCalls = 0;
    session.onEndpoint = () => endpointCalls++;

    await session.startLive();
    expect(engine.onEndpoint, isNotNull,
        reason: 'الجلسة توصّل كشف صمت نهاية المقطع من المحرّك');
    expect(session.liveRangeProgress, isNull,
        reason: 'قبل الإرساء لا تقدّم بعد');

    engine.progressOverride = 0.85;
    expect(session.liveRangeProgress, 0.85);

    engine.onEndpoint!();
    expect(endpointCalls, 1,
        reason: 'صمت الختام يصل للطبقة الأعلى (إنهاء المعلم الآلي)');
  });
}
