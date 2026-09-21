import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/core/services/tasmee_model_service.dart';
import 'package:quran_library/src/tasmee/engine/recitation.dart';

void main() {
  testWidgets('محرك zipformer: تنزيل النموذج + تهيئة كاملة',
      (tester) async {
    // 1) نزّل النموذج إن لم يكن جاهزًا (73MB مرة واحدة).
    final model = TasmeeModelService();
    if (!await model.isModelReady()) {
      await model.downloadModel();
    }
    expect(await model.isModelReady(), isTrue);

    // 2) تهيئة المحرك — تطبع الاستثناء الحقيقي عند الفشل.
    try {
      await Recitation.initZipformer();
      expect(await Recitation.isEngineHealthy(), isTrue);
      expect(Recitation.isOffline, isTrue);
      // ignore: avoid_print
      print('ENGINE INIT OK — healthy + offline');
    } catch (e, s) {
      // ignore: avoid_print
      print('ENGINE INIT FAILED: $e');
      // ignore: avoid_print
      print('STACK: $s');
      rethrow;
    }
    Recitation.reset();
  }, timeout: const Timeout(Duration(minutes: 10)));
}
