// A real Flutter web host for exercising the package asset and JS bridge.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, implementation_imports
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/widgets.dart';
import 'package:quran_library/quran_library.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_calibration.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_head.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_site_evidence.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_site_candidates.dart';
import 'package:quran_library/src/tasmee/engine/tajweedformer_window_evaluation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final TajweedFormerInferenceClient sdk = TajweedFormerWeb();
  try {
    final info =
        await sdk.initialize(const String.fromEnvironment('QURANLAB_WEB_KEY'));
    final calibration = sdk.calibration();
    final diagnosis = await sdk.diagnose();
    final calibrationData =
        Map<String, dynamic>.from(calibration['data'] as Map);
    final validatedSite = readTajweedFormerSiteCalibration(
      calibration: calibrationData,
      context: info['defaultContext'] as String,
      preset: calibrationData['default_preset'] as String,
      siteClass: 'cons_sub',
    );
    final disabledSite = readTajweedFormerSiteCalibration(
      calibration: calibrationData,
      context: info['defaultContext'] as String,
      preset: calibrationData['default_preset'] as String,
      siteClass: 'insertion',
    );
    final reference = await sdk.reference(1, 1);
    final sample = await sdk.sample();
    final sampleHeads = sample['heads'] as Map;
    final mainHead = TajweedFormerCtcHead.fromMap(
        Map<String, dynamic>.from(sampleHeads['log_probs'] as Map));
    final interHead = TajweedFormerCtcHead.fromMap(
        Map<String, dynamic>.from(sampleHeads['inter1_log_probs'] as Map));
    final expected = (reference['units'] as List).cast<int>();
    final names = (info['tokens'] as List).cast<String>();
    final letter = RegExp(r'^[\u0621-\u064a]$');
    final index = expected.indexWhere((id) => letter.hasMatch(names[id]));
    if (index < 0) throw StateError('No consonant in the sample reference');
    final alternativeId = names.indexWhere((name) =>
        letter.hasMatch(name) && names.indexOf(name) != expected[index]);
    if (alternativeId < 0) throw StateError('No alternative consonant');
    final alternative = List<int>.of(expected)..[index] = alternativeId;
    final evidence = evaluateCalibratedTajweedFormerSite(
      logProbs: mainHead.toRows(),
      inter1LogProbs: interHead.toRows(),
      expected: expected,
      alternatives: [alternative],
      blankId: info['blank'] as int,
      wordBarId: info['wordBar'] as int,
      calibration: validatedSite,
    );
    final verse = TajweedFormerReferenceVerse.fromWebReference(
      surah: 1,
      ayah: 1,
      reference: reference,
      blankId: info['blank'] as int,
      wordBarId: info['wordBar'] as int,
    );
    final tracker = TajweedFormerLiveTracker(
      reference: buildTajweedFormerReference(
        verses: [verse],
        blankId: info['blank'] as int,
        wordBarId: info['wordBar'] as int,
      ),
      blankId: info['blank'] as int,
      wordBarId: info['wordBar'] as int,
    );
    final windows = tajweedFormerSiteWindows(
      reference: tracker.reference,
      tokenNames: names,
    );
    final timer = Stopwatch()..start();
    final windowEvidence = evaluateTajweedFormerWindow(
      window: windows.first,
      referencePath: tracker.reference.map((unit) => unit.tokenId).toList(),
      logProbs: mainHead.toRows(),
      inter1LogProbs: interHead.toRows(),
      blankId: info['blank'] as int,
      wordBarId: info['wordBar'] as int,
      calibration: calibrationData,
      context: info['defaultContext'] as String,
      preset: calibrationData['default_preset'] as String,
    );
    timer.stop();
    final sampleTokens = sample['tokens'] as List;
    final progress = tracker.updateDecodedChunk({
      'tokens': sampleTokens,
      'settled': sampleTokens.length,
    });
    var chunks = 0;
    final take = TajweedFormerRangeSession(
      client: sdk,
      reference: tracker.reference,
      blankId: info['blank'] as int,
      wordBarId: info['wordBar'] as int,
    );
    final subscription = take.progress.listen((_) => chunks++);
    final audio = TajweedFormerAudioSession.microphone(take);
    await audio.start();
    await Future<void>.delayed(const Duration(seconds: 2));
    final heads = await audio.finish();
    await subscription.cancel();
    await sdk.close();
    html.document.body!.setAttribute(
        'data-result',
        jsonEncode({
          'ok': true,
          'version': info['version'],
          'tokenCount': (info['tokens'] as List).length,
          'calibrated': calibration['data'] != null,
          'validatedSite': validatedSite.isValidated,
          'insertionStatus': disabledSite.status,
          'evidenceFinite': evidence?.llr.isFinite == true,
          'windowClasses': windowEvidence.map((e) => e.siteClass).toList(),
          'windowMs': timer.elapsedMilliseconds,
          'diagnosis': diagnosis['model'] != null,
          'units': (reference['units'] as List).length,
          'sample': (sample['tokens'] as List).length,
          'matched': progress.matchedUnitIndices.length,
          'chunks': chunks,
          'heads': heads.keys.toList(),
        }));
  } catch (error) {
    await sdk.close();
    html.document.body!.setAttribute(
        'data-result', jsonEncode({'ok': false, 'error': error.toString()}));
  }
}
