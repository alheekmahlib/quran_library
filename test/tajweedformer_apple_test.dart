import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_apple.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('quran_library/tajweedformer_apple');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'available':
          return true;
        case 'configuredKey':
          return 'test';
        case 'initialize':
          return <String, dynamic>{
            'version': '4.0.0',
            'blank': 0,
            'wordBar': 1,
            'calibrationJson': '{"format":"test"}',
            'calibrationSha256': 'abc',
          };
        case 'reference':
          return <String, dynamic>{
            'units': [2],
            'words': [0],
            'wordCount': 1
          };
        case 'finish':
          return <String, dynamic>{
            'log_probs': <String, dynamic>{'frames': 1}
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('initializes, sends audio and disposes the only client', () async {
    expect(await TajweedFormerApple.isAvailable(), isTrue);
    final client = TajweedFormerApple();
    expect((await client.initializeFromHost())['version'], '4.0.0');
    expect(client.calibration()['sha256'], 'abc');
    expect((client.calibration()['data'] as Map)['format'], 'test');
    expect((await client.reference(1, 1))['wordCount'], 1);
    final other = TajweedFormerApple();
    await expectLater(other.initialize('test'), throwsStateError);
    await client.start();
    await client.push(Float32List(5));
    expect((await client.finish())['log_probs'], isNotNull);
    await client.close();
    await other.close();
    expect(
        calls,
        containsAllInOrder(
            ['initialize', 'reference', 'start', 'push', 'finish', 'close']));
    await expectLater(client.start(), throwsStateError);
  });

  test('a failed initialization releases ownership', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'initialize') {
        throw PlatformException(code: 'runtime_unsupported');
      }
      return null;
    });
    final first = TajweedFormerApple();
    final second = TajweedFormerApple();
    await expectLater(
        first.initialize('test'), throwsA(isA<PlatformException>()));
    await expectLater(
        second.initialize('test'), throwsA(isA<PlatformException>()));
    await first.close();
    await second.close();
  });

  test('the factory returns no V4 client on unsupported platforms', () async {
    final available = await createTajweedFormerClient();
    expect(available, isA<TajweedFormerApple>());
    await available!.close();
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final mac = await createTajweedFormerClient();
    expect(mac, isA<TajweedFormerApple>());
    await mac!.close();
    messenger.setMockMethodCallHandler(channel, (call) async => false);
    expect(await createTajweedFormerClient(), isNull);
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(await createTajweedFormerClient(), isNull);
  });
}
