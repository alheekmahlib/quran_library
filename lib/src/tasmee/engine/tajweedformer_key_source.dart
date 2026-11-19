/// مفاتيح Quran Lab حسب المنصة — يمررها التطبيق المضيف عند التهيئة.
///
/// The library itself never ships a key: each host app registers its own
/// identifiers at https://sdk.quranlab.ai and passes the issued keys here.
library;

import 'package:flutter/foundation.dart';

/// App-scoped Quran Lab keys, one per platform kind.
///
/// A key is issued per app identifier (Android applicationId, Apple bundle
/// id, web origin, desktop bundle id) and binds to the first app identifier
/// that launches with it — hosts must register their own identifiers, never
/// another app's key.
class QuranLabKeys {
  const QuranLabKeys({this.androidAndApple, this.web, this.desktop});

  /// Android and iOS `apps` key (the app's applicationId/bundle id).
  final String? androidAndApple;

  /// Web key, scoped by Quran Lab to the app's deployed https origins.
  final String? web;

  /// Desktop key (macOS today; Windows/Linux have no bridge yet).
  final String? desktop;
}

QuranLabKeys? _hostKeys;

/// يخزّن مفاتيح المضيف — في الذاكرة فقط، لا تُحفَظ ولا تُسجَّل في أي سجل.
void configureQuranLabKeys(QuranLabKeys? keys) => _hostKeys = keys;

/// المفاتيح التي مُرِّرت عبر `QuranLibrary.init`، إن وُجدت.
QuranLabKeys? get configuredQuranLabKeys => _hostKeys;

/// يحلّ مفتاح المنصة الحالية: حقلُ `QuranLabKeys` المطابق أولًا، ثم
/// `--dart-define=QURANLAB_KEY`. يعيد null إن لم يوجد أي منهما — احتياط
/// Info.plist على Apple يبقى في `Recitation.initTajweedFormer`.
String? resolveQuranLabKeyForPlatform(
    {String environmentKey = const String.fromEnvironment('QURANLAB_KEY')}) {
  final keys = _hostKeys;
  final String? platformKey = kIsWeb
      ? keys?.web
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => keys?.androidAndApple,
          TargetPlatform.iOS => keys?.androidAndApple,
          _ => keys?.desktop,
        };
  final fromInit = platformKey?.trim() ?? '';
  if (fromInit.isNotEmpty) return fromInit;
  final fromDefine = environmentKey.trim();
  return fromDefine.isNotEmpty ? fromDefine : null;
}
