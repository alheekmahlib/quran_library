import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_key_source.dart';

void main() {
  tearDown(() {
    configureQuranLabKeys(null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('each platform kind reads its own key field', () {
    configureQuranLabKeys(const QuranLabKeys(
      androidAndApple: 'qlk_v1_mobile',
      web: 'qlk_v1_web',
      desktop: 'qlk_v1_desktop',
    ));
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(resolveQuranLabKeyForPlatform(), 'qlk_v1_mobile');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(resolveQuranLabKeyForPlatform(), 'qlk_v1_mobile');
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(resolveQuranLabKeyForPlatform(), 'qlk_v1_desktop');
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(resolveQuranLabKeyForPlatform(), 'qlk_v1_desktop');
  });

  test('an init key wins over the dart-define fallback', () {
    configureQuranLabKeys(const QuranLabKeys(androidAndApple: 'qlk_v1_mobile'));
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      resolveQuranLabKeyForPlatform(environmentKey: 'qlk_v1_define'),
      'qlk_v1_mobile',
    );
  });

  test('the dart-define fills a platform whose field is empty', () {
    // لم يُمرَّ مفتاح الجوال؛ الاحتياط يملأه على Android وiOS معًا.
    configureQuranLabKeys(const QuranLabKeys(web: 'qlk_v1_web'));
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      resolveQuranLabKeyForPlatform(environmentKey: 'qlk_v1_define'),
      'qlk_v1_define',
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      resolveQuranLabKeyForPlatform(environmentKey: 'qlk_v1_define'),
      'qlk_v1_define',
    );
  });

  test('nothing configured resolves to null, not an error', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(resolveQuranLabKeyForPlatform(), isNull);
    expect(
      resolveQuranLabKeyForPlatform(environmentKey: '  '),
      isNull,
      reason: 'whitespace-only defines are ignored',
    );
  });

  test('configuredQuranLabKeys exposes what init stored', () {
    const keys = QuranLabKeys(androidAndApple: 'qlk_v1_mobile');
    configureQuranLabKeys(keys);
    expect(configuredQuranLabKeys, same(keys));
  });
}
