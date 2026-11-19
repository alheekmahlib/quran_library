/// خدمة نموذج TajweedFormer V4: تنزيل مسبق وقت التشغيل عبر SDK Quran Lab.
///
/// The V4 model is never bundled with the app: this service asks the SDK to
/// download its protected model files ahead of first use (like the Zipformer
/// runtime download, but the files stay inside the SDK's own storage and are
/// never touched directly — NPL-1.2). Byte progress is reported where the
/// platform provides it; on Apple the host's Info.plist key is used when the
/// app-scoped key is not set.
library;

import '../../engine/tajweedformer_apple.dart';
import '../../engine/tajweedformer_client.dart';
import '../../engine/tajweedformer_factory.dart';
import '../../engine/tajweedformer_key_source.dart';

typedef TajweedFormerClientFactory
    = Future<TajweedFormerInferenceClient?> Function();

class TajweedFormerPrefetchService {
  TajweedFormerPrefetchService({
    TajweedFormerClientFactory? clientFactory,
    String? keyOverride,
  })  : _clientFactory = clientFactory ?? createTajweedFormerClient,
        _keyOverride = keyOverride;

  final TajweedFormerClientFactory _clientFactory;
  final String? _keyOverride;

  /// هل يوجد جسر V4 على هذه المنصة أصلًا؟
  Future<bool> isAvailable() async => await _clientFactory() != null;

  /// المفتاح: تجاوز الاختبار أولًا، ثم حاسم المنصة الموحد
  /// (حقل init ← `QURANLAB_KEY`). الفارغ مقبول على Apple حيث يقرأ الجسر
  /// مفتاح المضيف من Info.plist.
  String _keyFor() {
    final override = _keyOverride?.trim() ?? '';
    if (override.isNotEmpty) return override;
    return resolveQuranLabKeyForPlatform() ?? '';
  }

  /// ينزّل ملفات النموذج عبر SDK ويعيد false إن لم يوجد جسر على المنصة.
  ///
  /// [onProgress] نسبة 0.0–1.0 من البايتات (حيث تدعم المنصة التقدم).
  Future<bool> prefetch({
    bool unmeteredOnly = false,
    void Function(double progress)? onProgress,
  }) async {
    final client = await _clientFactory();
    if (client == null) return false;
    try {
      final key = _keyFor();
      if (key.isEmpty && client is! TajweedFormerApple) {
        throw StateError('Quran Lab key is not configured');
      }
      final subscription = client.prefetchProgress.listen((p) {
        if (p.total > 0) onProgress?.call((p.done / p.total).clamp(0.0, 1.0));
      });
      try {
        await client.prefetch(key: key, unmeteredOnly: unmeteredOnly);
      } finally {
        await subscription.cancel();
      }
      return true;
    } finally {
      await client.close();
    }
  }

  /// يحذف ملفات النموذج من مخزن SDK ليعاد تنزيلها لاحقًا.
  Future<bool> removeModels() async {
    final client = await _clientFactory();
    if (client == null) return false;
    try {
      final key = _keyFor();
      if (key.isEmpty && client is! TajweedFormerApple) {
        throw StateError('Quran Lab key is not configured');
      }
      await client.removeModels(key: key);
      return true;
    } finally {
      await client.close();
    }
  }
}
