# TajweedFormer Apple probe

This development-only app tests the optional iOS and macOS inference bridge
with app-scoped Quran Lab development keys and the SDK's own sample clip. It
does not judge recitation or activate Tasmee. Use Swift Package Manager and an
ARM64 iOS simulator or ARM64 Mac.

Place `QURANLAB_KEY = <your development key>` in the ignored configuration
for each platform: `ios/Flutter/Secrets.xcconfig` or
`macos/Runner/Configs/Secrets.xcconfig`. Use a separate key scoped to each
probe bundle ID. For macOS, provide an Apple Development signing team and
identity in the ignored `macos/Runner/Configs/Signing.xcconfig` and configure
App Attest for the app and provisioning profile.

Run on the ARM64 simulator or replace the device ID with `macos`:

```sh
FLUTTER_SWIFT_PACKAGE_MANAGER=true flutter test -d <device-id> \
  --dart-define=QURANLAB_RUN_SAMPLE=true \
  integration_test/tajweedformer_apple_sample_test.dart
```

The sample integration test uses synthetic PCM, not a real microphone. To run
the Tasmee UI for a supervised physical iPhone test, use its app-scoped iOS key
and signing configuration in the ignored `ios/Flutter/Secrets.xcconfig` and
`ios/Flutter/Signing.xcconfig`, then run:

```sh
FLUTTER_SWIFT_PACKAGE_MANAGER=true flutter run --debug -d <iphone-id> \
  -t lib/tasmee_probe.dart --dart-define=TAJWEEDFORMER_SHOW_DIAGNOSTICS=true
```

The debug-only flag reveals unverified candidate feedback with a warning; it
does not enable it in release builds or mark words correct/incorrect. Do not
use it for learner-facing judgments. Request microphone permission on the
device and let the SDK manage its own sharing prompt. A physical device is
needed to exercise App Attest. The signed macOS sample test did not trigger or
verify the SDK's actual sharing sheet, and does not validate release builds.
