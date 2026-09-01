import 'dart:developer' show log;

import 'madd_timing.dart';
import 'models/muaalem_config.dart';
import 'muaalem_client.dart';
import 'recitation_engine.dart';
import 'recitation_session.dart';
// شرطي: يستبعد sherpa_onnx (dart:ffi) من بناء الويب.
// Conditional: keeps sherpa_onnx (dart:ffi) out of web builds.
import 'sherpa_factory.dart';

/// نقطة الدخول العامة لِميزة التسميع (تصحيح التلاوة).
///
/// Facade for the recitation-correction feature.
///
/// تدعم الوحدة محرّكَين:
/// - **Online** (افتراضي): خادم [quran-muaalem](https://github.com/obadx/quran-muaalem)
///   عبر [init] + [serverUrl].
/// - **Offline**: نموذج Quran-Lab zipformer v3.1 محلي (73MB) عبر
///   [initZipformer] — لا يحتاج خادماً ولا إنترنت.
///
/// هذه الوحدة **اختيارية تماماً**: لا تُحمّل ولا تستهلك موارداً حتى تستدعي
/// [init] أو [initZipformer].
///
/// ## Online / Setup
///
/// ```bash
/// pip install "quran-muaalem[engine]"
/// quran-muaalem-engine  # منفذ 8000 (النموذج)
/// quran-muaalem-app     # منفذ 8001 (HTTP API)
/// ```
///
/// ```dart
/// Recitation.init(serverUrl: 'http://localhost:8001');
/// final session = Recitation.createSession();
/// await session.start();
/// // ... تلاوة ...
/// await session.stop();
/// print(session.result.value?.errors);
/// ```
///
/// ## Offline / Setup
///
/// ```dart
/// await Recitation.initZipformer();  // النموذج يُنزَّل من GitHub Release
/// final session = Recitation.createSession();
/// await session.start();
/// // ... تلاوة (بدون إنترنت!) ...
/// await session.stop();
/// print(session.result.value?.predictedPhonemes);
/// ```
class Recitation {
  Recitation._();

  static RecitationEngine? _engine;
  static String? _serverUrl;
  static bool _isOffline = false;

  /// هل الوحدة مهيّأة؟
  /// Is the module initialized?
  static bool get isInitialized => _engine != null;

  /// هل المحرّك offline (ONNX)؟
  /// Is the engine offline (ONNX)?
  static bool get isOffline => _isOffline;

  /// عنوان الخادم (online) أو null.
  /// The server URL (online) or null.
  static String? get serverUrl => _serverUrl;

  // ── Online ──────────────────────────────────────────────────

  /// هيّئ وحدة التسميع بِخادم quran-muaalem (online).
  ///
  /// Initialize the recitation module with a quran-muaalem server (online).
  ///
  /// [serverUrl] - عنوان الخادم (مثل `http://localhost:8001`).
  static void init({required String serverUrl}) {
    final trimmed = serverUrl.trim();
    if (trimmed.isEmpty) {
      log('Recitation.init: empty server URL — module stays uninitialized.',
          name: 'Recitation');
      return;
    }
    _engine?.dispose();
    _engine = MuaalemClient(baseUrl: trimmed);
    _serverUrl = trimmed;
    _isOffline = false;
    log('Recitation initialized (online). serverUrl=$trimmed',
        name: 'Recitation');
  }

  // ── Offline ─────────────────────────────────────────────────

  /// هيّئ وحدة التسميع بِنموذج Quran-Lab zipformer v3.1 (offline — لا إنترنت).
  ///
  /// Initialize with the Quran-Lab zipformer model (offline).
  ///
  /// [modelPath] مسار نموذج ONNX ‏(73MB — إن null يُبحث في مجلد التطبيق).
  /// [tokensPath]/[referencePath] مسارات بديلة (الافتراضي: أصول الحزمة).
  /// [maddTimingConfig] معايرة الحكم الزمني على المدود.
  static Future<void> initZipformer({
    String? modelPath,
    String? tokensPath,
    String? referencePath,
    MaddTimingConfig maddTimingConfig = const MaddTimingConfig(),
  }) async {
    _engine?.dispose();
    _engine = await createSherpaZipformerEngine(
      modelPath: modelPath,
      tokensPath: tokensPath,
      referencePath: referencePath,
      maddTimingConfig: maddTimingConfig,
    );
    _serverUrl = null;
    _isOffline = true;
    log('Recitation initialized (offline, zipformer v3.1).',
        name: 'Recitation');
  }

  // ── مشترك ───────────────────────────────────────────────────

  /// أعد ضبط الوحدة (نسيان المحرّك).
  /// Reset the module (forget the engine).
  static void reset() {
    _engine?.dispose();
    _engine = null;
    _serverUrl = null;
    _isOffline = false;
  }

  /// تحقّق من جاهزية المحرّك.
  ///
  /// Check engine health (server online / model offline).
  static Future<bool> isEngineHealthy() async {
    if (_engine == null) return false;
    return _engine!.isHealthy();
  }

  /// (offline) نصّ آية عثماني من DB المرجعية.
  /// يُعيد null في الوضع online أو إن لم تُوجد الآية في DB.
  static String? getVerseText({required int suraIdx, required int ayaIdx}) {
    if (_engine == null) return null;
    return _engine!.getVerseText(suraIdx: suraIdx, ayaIdx: ayaIdx);
  }

  /// تحقّق من صحة الخادم (متوافق مع الإصدارات السابقة — للـ online).
  ///
  /// Check server health (backward-compatible alias for [isEngineHealthy]).
  static Future<bool> isServerHealthy() => isEngineHealthy();

  /// أنشئ جلسة تسميع جديدة.
  ///
  /// Create a new recitation session.
  ///
  /// تتطلّب تهيئة مسبقة عبر [init] أو [initZipformer].
  ///
  /// [suraIdx]/[ayaIdx] (offline) رقم السورة والآية — يُمكّن المحرّك
  ///   offline من جلب المرجع من DB ومقارنة الفونيمات + كشف أخطاء التجويد.
  /// [referenceText] (offline، بديل) نصّ الآية العثماني.
  static RecitationSession createSession({
    MuaalemConfig config = const MuaalemConfig(),
    int? suraIdx,
    int? ayaIdx,
    String? referenceText,
  }) {
    _ensureInitialized();
    return RecitationSession(
      config: config,
      engine: _engine!,
      suraIdx: suraIdx,
      ayaIdx: ayaIdx,
      referenceText: referenceText,
    );
  }

  static void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError(
        'Recitation is not initialized. Call one of:\n'
        '  Recitation.init(serverUrl: "http://localhost:8001")  // online\n'
        '  await Recitation.initZipformer()                     // offline\n'
        '\n'
        'Online server setup:\n'
        '  pip install "quran-muaalem[engine]"\n'
        '  quran-muaalem-engine && quran-muaalem-app\n'
        'Offline model: download zipformer v3.1 (73MB) from GitHub Release\n'
        '  tag zipformer-model-v1 into the app-support directory.',
      );
    }
  }
}
