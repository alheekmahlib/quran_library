import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/core/services/tajweedformer_prefetch_service.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_client.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_key_source.dart';

class FakeV4Client implements TajweedFormerInferenceClient {
  FakeV4Client({this.prefetchError, this.requireKey = true});

  final Object? prefetchError;
  final bool requireKey;

  String? lastPrefetchKey;
  bool? lastUnmeteredOnly;
  bool removeModelsCalled = false;
  bool closed = false;

  final _progress =
      StreamController<({int done, int total})>.broadcast(sync: true);

  @override
  Stream<({int done, int total})> get prefetchProgress => _progress.stream;

  @override
  Future<void> prefetch({String key = '', bool unmeteredOnly = false}) async {
    lastPrefetchKey = key;
    lastUnmeteredOnly = unmeteredOnly;
    if (requireKey && key.trim().isEmpty) {
      throw StateError('Quran Lab key is not configured');
    }
    if (prefetchError != null) throw prefetchError!;
    _progress.add((done: 25, total: 0));
    _progress.add((done: 10, total: 100));
    _progress.add((done: 100, total: 100));
  }

  @override
  Future<void> removeModels({String key = ''}) async {
    removeModelsCalled = true;
  }

  @override
  Future<void> close() async => closed = true;

  @override
  Stream<Map<String, dynamic>> get chunks => const Stream.empty();
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
  Future<void> start() async {}
  @override
  Future<void> push(Float32List samples) async {}
  @override
  Future<Map<String, dynamic>> finish() async => {};
  @override
  Future<void> cancel() async {}
}

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    configureQuranLabKeys(null);
  });
  test('prefetch forwards key and unmeteredOnly and reports byte progress',
      () async {
    late FakeV4Client client;
    final service = TajweedFormerPrefetchService(
      clientFactory: () async => client = FakeV4Client(),
      keyOverride: 'qlk_v1_test',
    );
    final progress = <double>[];
    final ok = await service.prefetch(
        unmeteredOnly: true, onProgress: progress.add);
    expect(ok, isTrue);
    expect(client.lastPrefetchKey, 'qlk_v1_test');
    expect(client.lastUnmeteredOnly, isTrue);
    expect(progress, [0.1, 1.0]); // zero-total events are ignored.
    expect(client.closed, isTrue, reason: 'temp client must be closed');
  });

  test('prefetch returns false where no bridge exists', () async {
    final service = TajweedFormerPrefetchService(clientFactory: () async => null);
    expect(await service.isAvailable(), isFalse);
    expect(await service.prefetch(), isFalse);
    expect(await service.removeModels(), isFalse);
  });

  test('a missing app key fails the download before touching the SDK',
      () async {
    final client = FakeV4Client();
    final service =
        TajweedFormerPrefetchService(clientFactory: () async => client);
    await expectLater(service.prefetch(),
        throwsStateError);
    expect(client.closed, isTrue);
  });

  test('removeModels forwards to a fresh client and closes it', () async {
    late FakeV4Client client;
    final service = TajweedFormerPrefetchService(
      clientFactory: () async => client = FakeV4Client(),
      keyOverride: 'qlk_v1_test',
    );
    expect(await service.removeModels(), isTrue);
    expect(client.removeModelsCalled, isTrue);
    expect(client.closed, isTrue);
  });

  test('prefetch failures surface to the caller', () async {
    final service = TajweedFormerPrefetchService(
      clientFactory: () async =>
          FakeV4Client(prefetchError: StateError('storage_full')),
      keyOverride: 'qlk_v1_test',
    );
    await expectLater(
        service.prefetch(), throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('storage_full'))));
  });

  test('host keys from init reach the SDK client per platform', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    configureQuranLabKeys(const QuranLabKeys(androidAndApple: 'qlk_v1_host_mobile'));
    late FakeV4Client client;
    final service =
        TajweedFormerPrefetchService(clientFactory: () async => client = FakeV4Client());
    await service.prefetch();
    expect(client.lastPrefetchKey, 'qlk_v1_host_mobile');
  });

  test('an explicit key override still beats the host keys', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    configureQuranLabKeys(const QuranLabKeys(androidAndApple: 'qlk_v1_host_mobile'));
    late FakeV4Client client;
    final service = TajweedFormerPrefetchService(
      clientFactory: () async => client = FakeV4Client(),
      keyOverride: 'qlk_v1_override',
    );
    await service.prefetch();
    expect(client.lastPrefetchKey, 'qlk_v1_override');
  });
}
