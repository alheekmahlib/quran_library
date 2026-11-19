import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_client.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_range_session.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';

class FakeClient implements TajweedFormerInferenceClient {
  final stream = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  bool started = false;
  bool cancelled = false;
  int samples = 0;
  @override
  Stream<Map<String, dynamic>> get chunks => stream.stream;
  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<void> push(Float32List value) async {
    samples += value.length;
  }

  @override
  Future<Map<String, dynamic>> finish() async => {'log_probs': 'head'};
  @override
  Future<void> cancel() async {
    cancelled = true;
  }

  @override
  Future<void> close() => stream.close();
  @override
  Future<Map<String, dynamic>> initialize(String key) async => {};
  @override
  Future<Map<String, dynamic>> reference(int surah, int ayah) async => {};
  @override
  Future<Map<String, dynamic>> sample() async => {};
  @override
  Future<Map<String, dynamic>> recognize(Float32List samples) async => {};
  @override
  Map<String, dynamic> calibration() => {};
  @override
  Future<Map<String, dynamic>> diagnose() async => {};
  @override
  Future<void> prefetch({String key = '', bool unmeteredOnly = false}) async {}
  @override
  Stream<({int done, int total})> get prefetchProgress => const Stream.empty();
  @override
  Future<void> removeModels({String key = ''}) async {}
}

class FinalChunkClient extends FakeClient {
  @override
  Future<Map<String, dynamic>> finish() async {
    stream.add({'tokens': 'malformed', 'settled': 1});
    return super.finish();
  }
}

void main() {
  TajweedFormerRangeSession make(FakeClient client) =>
      TajweedFormerRangeSession(
        client: client,
        blankId: 0,
        wordBarId: 1,
        reference: [
          for (final id in [2, 3, 4, 5])
            TajweedFormerReferenceUnit(tokenId: id, verseIndex: 0, wordIndex: 0)
        ],
      );

  test('routes settled chunks into progress and returns raw heads', () async {
    final client = FakeClient();
    final session = make(client);
    final progress = <Set<int>>[];
    final sub = session.progress
        .listen((value) => progress.add(value.matchedUnitIndices));
    await expectLater(session.push(Float32List(1)), throwsStateError);
    await session.start();
    await session.push(Float32List(100));
    client.stream.add({
      'tokens': [
        {'id': 2},
        {'id': 3},
        {'id': 4},
        {'id': 5}
      ],
      'settled': 3
    });
    final heads = await session.finish();
    expect(client.started, isTrue);
    expect(client.samples, 100);
    expect(progress.single, {0, 1, 2});
    expect(heads['log_probs'], 'head');
    await expectLater(session.start(), throwsStateError);
    await sub.cancel();
    await client.close();
  });

  test('cancels the take without closing its caller-owned client', () async {
    final client = FakeClient();
    final session = make(client);
    await session.start();
    await session.cancel();
    await session.cancel();
    expect(client.cancelled, isTrue);
    await expectLater(session.push(Float32List(1)), throwsStateError);
    expect(client.stream.isClosed, isFalse);
    await client.close();
  });

  test('projects streamed matches onto the supplied word positions', () async {
    final client = FakeClient();
    final session = make(client);
    final snapshots = [];
    final sub = session.wordProgress.listen(snapshots.add);
    await session.start();
    client.stream.add({
      'tokens': [
        {'id': 2},
        {'id': 3},
        {'id': 4},
        {'id': 5}
      ],
      'settled': 4,
    });
    await session.finish();
    expect(snapshots.single.matchedWords, {(verseIndex: 0, wordIndex: 0)});
    await sub.cancel();
    await client.close();
  });

  test('a stream failure cancels the take instead of returning heads',
      () async {
    final client = FakeClient();
    final session = make(client);
    final errors = <Object>[];
    final sub = session.progress.listen((_) {}, onError: errors.add);
    await session.start();
    client.stream.addError(StateError('inference stream failed'));
    await expectLater(session.finish(), throwsStateError);
    expect(client.cancelled, isTrue);
    expect(errors, hasLength(1));
    await sub.cancel();
    await client.close();
  });

  test('rejects heads when the final decoded chunk is malformed', () async {
    final client = FinalChunkClient();
    final session = make(client);
    final errors = <Object>[];
    final sub = session.progress.listen((_) {}, onError: errors.add);
    await session.start();
    await expectLater(session.finish(), throwsFormatException);
    expect(errors, hasLength(1));
    await sub.cancel();
    await client.close();
  });
}
