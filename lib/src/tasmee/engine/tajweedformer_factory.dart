import 'package:flutter/foundation.dart';

import 'tajweedformer_android.dart';
import 'tajweedformer_apple.dart';
import 'tajweedformer_client.dart';
import 'tajweedformer_web.dart';

/// Creates an optional V4 inference client, or returns null where unavailable.
///
/// The caller chooses whether to use it and supplies an app-scoped key. This
/// does not initialize V4 or change the existing Zipformer Tasmee engine.
Future<TajweedFormerInferenceClient?> createTajweedFormerClient() async {
  if (kIsWeb) return TajweedFormerWeb();
  if (defaultTargetPlatform == TargetPlatform.android &&
      await TajweedFormerAndroid.isAvailable()) {
    return TajweedFormerAndroid();
  }
  if ((defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) &&
      await TajweedFormerApple.isAvailable()) {
    return TajweedFormerApple();
  }
  return null;
}
