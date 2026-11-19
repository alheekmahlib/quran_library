import 'package:flutter_test/flutter_test.dart';
import 'package:quran_library/src/tasmee/engine/models/tasmee_tolerance.dart';

void main() {
  test('legacy strictness is used for each missing category', () {
    final profile = TasmeeToleranceProfile.fromJson(null,
        fallback: TasmeeToleranceLevel.strict);
    expect(profile.letters, TasmeeToleranceLevel.strict);
    expect(profile.tashkeel, TasmeeToleranceLevel.strict);
    expect(profile.madd, TasmeeToleranceLevel.strict);
  });

  test('custom levels round-trip independently and reject skipped letters', () {
    const profile = TasmeeToleranceProfile(
      letters: TasmeeToleranceLevel.lenient,
      tashkeel: TasmeeToleranceLevel.skip,
      madd: TasmeeToleranceLevel.strict,
    );
    final restored = TasmeeToleranceProfile.fromJson(profile.toJson());
    expect(restored.letters, TasmeeToleranceLevel.lenient);
    expect(restored.tashkeel, TasmeeToleranceLevel.skip);
    expect(restored.madd, TasmeeToleranceLevel.strict);
    expect(TasmeeToleranceProfile.fromJson({'letters': 'skip'}).letters,
        TasmeeToleranceLevel.balanced);
  });
}
