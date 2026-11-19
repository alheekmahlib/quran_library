import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_audio_session.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_range_session.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_reference.dart';

import 'tajweedformer_range_session_test.dart' show FakeClient;

class RecordingClient extends FakeClient {
  final values = <double>[];
  @override
  Future<void> push(Float32List value) async {
    await super.push(value);
    values.addAll(value);
  }
}

class DelayedClient extends RecordingClient {
  final gate = Completer<void>();
  bool finished = false;

  @override
  Future<void> push(Float32List value) async {
    await gate.future;
    await super.push(value);
  }

  @override
  Future<Map<String, dynamic>> finish() async {
    finished = true;
    return super.finish();
  }
}

class FailingClient extends FakeClient {
  @override
  Future<void> push(Float32List value) async {
    throw StateError('inference failed');
  }
}

void main() {
  TajweedFormerRangeSession range(FakeClient client) =>
      TajweedFormerRangeSession(
        client: client,
        blankId: 0,
        wordBarId: 1,
        reference: [
          const TajweedFormerReferenceUnit(
              tokenId: 2, verseIndex: 0, wordIndex: 0),
        ],
      );

  test('streams PCM across odd chunk boundaries and finishes', () async {
    final client = RecordingClient();
    final audio = StreamController<Uint8List>(sync: true);
    var closed = false;
    final session = TajweedFormerAudioSession(
      range: range(client),
      openAudio: () async => audio.stream,
      closeAudio: () async {
        closed = true;
      },
    );
    await session.start();
    audio.add(Uint8List.fromList([0, 128, 255]));
    audio.add(Uint8List.fromList([127, 0, 0]));
    expect((await session.finish())['log_probs'], 'head');
    expect(client.samples, 3);
    expect(client.values, [-1.0, 32767 / 32768, 0.0]);
    expect(closed, isTrue);
    await audio.close();
    await client.close();
  });

  test('capture errors cancel rather than return incomplete heads', () async {
    final client = FakeClient();
    final audio = StreamController<Uint8List>(sync: true);
    final session = TajweedFormerAudioSession(
      range: range(client),
      openAudio: () async => audio.stream,
      closeAudio: () async {},
    );
    await session.start();
    audio.addError(StateError('capture failed'));
    await expectLater(session.finish(), throwsStateError);
    expect(client.cancelled, isTrue);
    await audio.close();
    await client.close();
  });

  test('waits for asynchronous audio pushes in order before finish', () async {
    final client = DelayedClient();
    final audio = StreamController<Uint8List>(sync: true);
    final session = TajweedFormerAudioSession(
      range: range(client),
      openAudio: () async => audio.stream,
      closeAudio: () async {},
    );
    await session.start();
    audio.add(Uint8List.fromList([0, 64]));
    audio.add(Uint8List.fromList([0, 128]));
    final result = session.finish();
    await Future<void>.delayed(Duration.zero);
    expect(client.finished, isFalse);
    client.gate.complete();
    await result;
    expect(client.values, [0.5, -1.0]);
    expect(client.finished, isTrue);
    await audio.close();
    await client.close();
  });

  test('an asynchronous inference failure cancels the take', () async {
    final client = FailingClient();
    final audio = StreamController<Uint8List>(sync: true);
    final session = TajweedFormerAudioSession(
      range: range(client),
      openAudio: () async => audio.stream,
      closeAudio: () async {},
    );
    final errors = <Object>[];
    final errorsSub = session.errors.listen(errors.add);
    await session.start();
    audio.add(Uint8List.fromList([0, 0]));
    await expectLater(session.finish(), throwsStateError);
    expect(errors, hasLength(1));
    expect(client.cancelled, isTrue);
    await errorsSub.cancel();
    await audio.close();
    await client.close();
  });

  test('fails a take when queued audio exceeds the bounded buffer', () async {
    final client = FakeClient();
    final audio = StreamController<Uint8List>(sync: true);
    final session = TajweedFormerAudioSession(
      range: range(client),
      openAudio: () async => audio.stream,
      closeAudio: () async {},
    );
    await session.start();
    audio.add(Uint8List(16000 * 30 * 2 + 2));
    await expectLater(session.finish(), throwsStateError);
    expect(client.cancelled, isTrue);
    expect(client.samples, 0);
    await audio.close();
    await client.close();
  });

  test('permission failure cleans up the started model session', () async {
    final client = FakeClient();
    var closed = false;
    final session = TajweedFormerAudioSession(
      range: range(client),
      openAudio: () async => throw StateError('denied'),
      closeAudio: () async {
        closed = true;
      },
    );
    await expectLater(session.start(), throwsStateError);
    expect(client.cancelled, isTrue);
    expect(closed, isTrue);
    await client.close();
  });
}
