# TajweedFormer V4 migration status

TajweedFormer V4 is selectable in Tasmee on supported web, Android, iOS and
macOS hosts. Zipformer remains the default. Teacher mode can record a single
ayah with V4; its partial result cannot establish mastery or advance a host's
mastery loop automatically. The live corrector is not implemented; Windows and
Linux bridges are not implemented.
V4 results set `assessmentComplete` to false: they do not claim to have
assessed every tajweed rule, and they cannot be used as an automatic mastery
or word-retry pass. Existing results default to true. A host that persists
V4 results must preserve this flag (`assessment_complete` when reading JSON),
so a restored partial assessment is not mistaken for a complete one.
V4 results also carry a per-category `coverage` map (JSON key `v4_coverage`)
stating, for each evaluation category, whether it was assessed, flagged for
review, or left unassessed and why; an empty error list alone never means a
rule was checked.
`RecitationResult.toJson()` and `fromJson()` preserve that flag, word spans,
positions and candidate errors for hosts that choose to save results. The UI
currently keeps V4 word states neutral and does not display its error
details: the public correct-only check below produced too many false flags.
The raw candidate errors remain in the in-memory result for developer review;
they must not be interpreted as validated learner feedback.
For a supervised developer test only, a debug build with
`TAJWEEDFORMER_SHOW_DIAGNOSTICS=true` can show those candidates with an
explicit warning. The flag has no effect in release builds and never changes
`assessmentComplete`; in that debug mode detected candidate errors use the
shared colored underline, while other words remain neutral.
Both models and their references must remain separate: their token IDs and
representations are incompatible.
The shipped V4 references are Hafs; explicitly requesting another riwaya now
fails before recording or evaluation rather than using a Hafs path silently.
The bundled canonical timing metadata also carries gemination positions from
the same pinned Quran Lab phonetic source; alternate or partial paths remain
unassessed by the timing and attribute evaluators.

| Existing behavior | Current input / setting | V4 status |
| --- | --- | --- |
| Letter substitutions, insertions, deletions | Zipformer unit alignment and token heuristics | Eligible sites are checked against calibrated V4 CTC evidence, including sites with no decoded difference. Consonant insertion is disabled in the current model calibration; unsupported decoded differences produce an incomplete result. Accuracy validation remains. |
| Vowel changes | Haraka embedded in the old token | Eligible vowel sites are checked against calibrated V4 CTC evidence. Accuracy validation remains. |
| Madd length | Old token length and timestamp gaps; `minTimedGolden=3`, `minPaceRatio=2.0`, fallback `harakaSec=0.5` | V4 timing-head alignment and calibrated cuts use public canonical phonetic metadata. The entire selected take must match the decoded path exactly, and only complete canonical verses are scored; partial verses, alternate paths and disabled classes remain unassessed. A matching decode still does not validate the timing or feedback. |
| Shadda, qalqalah, ghunna and ikhfa | Attributes embedded in old tokens | Qalqalah has an experimental attribute-head implementation available only to explicitly enabled debug diagnostics. Shadda has a separate attribute evaluator and canonical metadata but is disabled by the model's `off` calibration. Ghunna and ikhfa are declared unsupported with a documented obstacle and extension path (the SDK's reference lists an `attr_ghunna` head and the dataset carries the ghunna kinds, but this build ships no ghunna calibration section or documented class layout). None is a validated learner verdict. |
| Live tracking, range completion and partial recitation | `RangeLiveTracker`, old units and their word mapping | Settled matches appear without an immediate correctness verdict. The SDK's speech flag supplies a silence endpoint. Final evaluation selects a lattice path in the matched range. Automatic completion and live correction are not implemented for V4. |
| Single-word retry | Existing error classification and 0.85/0.75/0.70 accuracy settings | V4 respects the requested displayed-word window and selects its own reference and lattice units. Pausing a V4 take now finishes and releases it before another take; resuming opens a fresh take, and final partial results are combined without claiming completeness. Retry uses streamed PCM on supported platforms, and partial or failed V4 assessments are inconclusive, not automatically accepted or rejected. The live corrector remains blocked until there is a trustworthy learner-facing trigger and UI for inconclusive attempts. The shared strict/balanced/lenient setting selects V4 sensitive/balanced/strict evidence respectively, without reusing Zipformer thresholds. |
| Teacher recording | One ayah at a time, silence endpoint and mastery loop | The shared controls can select teacher mode, play the current ayah, record it, repeat it, and move to the next ayah by the learner's choice. V4 ends capture at a silence endpoint only after full live reference coverage. Coverage is not a correctness verdict. Incomplete results cannot establish mastery or automatically advance the host's mastery loop. Earlier ayahs' display states are retained. |
| Final reconciliation and saved results | Existing `RecitationResult` positions and completed words | Positioned V4 errors and word spans feed the existing result schema and reconciliation. Partial recitation and correction accuracy need device validation. |
| Online Muaalem engine | Server response | Unchanged. |

Web SDK 3.1.6 is bundled as an optional inference bridge. `TajweedFormerWeb`
can initialize, read the model reference and calibration, run a sample, and
push PCM into a session. `TajweedFormerRangeSession` connects the client to the
conservative tracker and returns the raw heads. Its `wordProgress` stream
projects matches onto the supplied, already verified word positions; it only
includes a word when at least one reference unit has matched and it rebuilds the
snapshot when settled tokens are revised. It is not a correctness verdict.
These lower-level APIs do not themselves activate Tasmee. The opt-in Tasmee
engine uses the bridge and its own calibrated feedback. It has not passed the
device and accuracy tests needed to replace Zipformer as the default.

`TajweedFormerAudioSession` offers an explicit experimental microphone path to
the range session, or accepts a host-provided stream of 16 kHz mono PCM16. It
returns raw heads and conservative matches only; it is not connected to the
Tasmee UI or its correction and persistence. The microphone path needs device
testing, including permission denial, interruptions and cleanup. Android SDK
3.1.5 requires API 26. The Android bridge is included only when the host sets
Gradle property `quranLibraryEnableTajweedFormer=true`; on API 24–25 it is
guarded from loading, and the existing Zipformer path remains available.
On supported Android, `TajweedFormerAndroid.isAvailable()` checks availability;
the caller supplies an app-scoped Quran Lab key to `initialize`. This is an
inference API, not a Tasmee correction engine. Android SDK 3.1.5, including its
own recording-sharing flow, retains its separate NPL-1.2 license.
`createTajweedFormerClient()` selects an available Android, iOS, macOS or web client, and
returns null on unsupported platforms; it neither initializes the SDK nor
changes the engine used by Tasmee.

To build the experimental Android bridge, add
`quranLibraryEnableTajweedFormer=true` to the host app's
`android/gradle.properties`. Keep the app-specific key in ignored configuration
and supply `QURANLAB_KEY` using `--dart-define-from-file`; do not commit it.
The development key used by the example belongs only to its test application.
For the microphone-free Android probe, run the example's
`integration_test/tajweedformer_android_sample_test.dart` with that property
and `--dart-define-from-file` pointing to the ignored key configuration.

The Apple bridge lives inside the main package as its shared Darwin source
(`darwin/quran_library/`), using Apple SDK 3.1.4 through Swift Package
Manager — hosts get it automatically (merged 2026-11-16 from the former
separate package `quran_library_tajweedformer_apple`, which was removed).
It requires Xcode 16+, iOS 15+ or macOS 12+, and
ARM64. The SDK has no Intel slice, so a host using the package must exclude
x86_64 from simulator and macOS builds. The example configures App Attest
and reads its app-specific key from ignored `Secrets.xcconfig`; the SDK owns
its iOS sharing sheet. The macOS implementation provides a full-window SwiftUI
host for the SDK's own sheet and refuses initialization without a visible
Flutter window. The SDK decides when to show its sharing sheet. The actual
SDK sheet, App Attest behavior and release distribution still need validation.

The inference contract now awaits session start and PCM pushes, as required by
the Android SDK. The audio adapter serializes pushes and drains them before
finishing, and fails the take on an asynchronous inference error. The Flutter
range session also rejects final heads after a decoded-stream error or malformed
chunk, and cancels an active take when such an error precedes finish. This does
not validate the reference mapping or establish correction accuracy. The shared
live recorder preserves PCM16 samples split across stream chunks and rejects a
capture error, unexpected stream closure or incomplete sample instead of
evaluating truncated audio. V4 also serializes take shutdown and rejects a new
take until an earlier finish or cancellation has completed. Evaluation data is
retained only after a final transcription is received, and cancellation clears
it. The
Flutter web probe was run with SDK 3.1.3 and model 4.0.0, first on an SDK sample and
then through the microphone adapter with Chrome's fake audio device; it
produced chunks and raw heads. This is not a test of a real microphone,
background interruptions, Mushaf mapping, or recognition accuracy.

On 2026-11-14 the V4 recitation engine was exercised with the web SDK's real
sample transcription and raw heads, replayed through its streaming interface
without a microphone. It returned mapped word spans and no detected errors for
that sample, with `assessmentComplete` false. One correct recording does not
establish error-detection recall or real-device behavior.

On 2026-11-13 the optional Android bridge was built with SDK 3.1.4. An Android
17 arm64 emulator loaded model 4.0.0, its reference and calibration, played an
SDK sample and processed streamed synthetic PCM. On 2026-11-14 the microphone
path also received live audio on that emulator using 3.1.4; after upgrading to
3.1.5, the sample and synthetic PCM test passed again. An Android 7 API 24
arm64 emulator rejected V4 and initialized Zipformer with 3.1.5 included.
After the Tasmee integration changes, a fresh Android 7 API 24 arm64 emulator
again rejected V4 and initialized Zipformer successfully with the optional
Android 3.1.5 bridge included. Neither check used the microphone.
The developer deferred repeating the microphone test with 3.1.5. These tests
do not cover a physical Android device, another ABI or release shrinking, and
do not establish recognition or feedback accuracy.

On 2026-11-14 an ARM64 iPhone simulator loaded the iOS bridge and SDK 3.1.4,
verified model 4.0.0, fetched the reference, ran a bundled sample and processed
streamed synthetic PCM. Diagnosis reported an accepted key and fresh config.
This did not test a physical iPhone, its microphone or App Attest.

On 2026-11-14 the developer ran the debug Tasmee UI on a physical iPhone 11
and reported six findings after reciting Al-Fatiha with deliberate mistakes.
Screenshots show the Zipformer result format and a shadda finding, which V4
does not currently implement. This take therefore does not establish a working
physical-device V4 path or its accuracy. A V4-specific test is still needed.

On 2026-11-14 a signed ARM64 macOS debug app with App Attest entitlement
initialized the bridge, accepted its separate app-scoped key, ran the SDK sample
and processed synthetic PCM. A separate generic SwiftUI sheet test checked the
hosting approach; the actual SDK sharing sheet was not triggered or verified.
Neither real microphone capture nor release distribution was tested.

On 2026-11-13, the example's Zipformer integration test downloaded the model
and initialized the offline engine on an Android 7.0 API 24 arm64 emulator.
The old emulator's trust store lacked ISRG Root X1 for GitHub's release asset
host. The Android Zipformer download client adds the official ISRG root while
retaining certificate and hostname validation. The bundled root expires on
2035-06-04 and must be maintained as server certificate chains change. This
check does not validate microphone capture, recognition accuracy, or V4.

V4 references expose token IDs, word indices and word counts. The web adapter
checks that these agree before reusing word positions; it is also necessary to
verify them against the actual Mushaf word indexing for every supported verse.
On 2026-11-13 an exploratory check compared all 6,236 canonical ayahs from
`quran-p2g` revision `233568a621d853da7969ed174ddff625ef9ace5e` to the web
SDK model 4.0.0: token sequences and the SDK's token-to-reference-word indices
matched throughout. The SDK splits 27 ayahs into more reference words than
the source's Uthmani text. The library's QPC word asset also represents 37:130
as three words where that source splits four. End-of-ayah markers are excluded
from the latter comparison. A validated map to the actual UI is still needed;
counts alone cannot establish the identity of corresponding words. The Dart
reference builder can accept an explicitly supplied adjacent-word merge map.
Generated QPC maps are now shipped but are not used by Tasmee yet.
The reproducible `tool/tajweedformer_web_probe/audit_word_mapping.py` audit
compares the pinned `quran-p2g` pronunciation-to-text word indices with QPC
word boundaries after retaining only Unicode letters. On 2026-11-14 it found
3,713 exact-letter candidate mappings, including all 27 multi-pronunciation-word
merges, and 2,523 text mismatches requiring review. It also found 1,910 exact
matches between the existing Zipformer reference text and QPC; that separate
result illustrates why a V4-to-QPC mapping alone cannot be assumed to match
the current controller's Zipformer word indices. These counts are an audit,
not validation of the mappings, recognition, or correction. A subsequent
generator accounts for script differences, with a checked spelling exception
for 2:72, and produced maps for all 6,236 verses. The loader accepted all of
them against SDK canonical paths. Device and reading accuracy remain untested.
The SDK's reference uses the pausal form at the end of each verse, so connected
verses and stops inside a verse require explicit handling and testing.
The independent Dart lattice selector enforces matching stop/connection states;
its distances match Quran Lab's benchmark scorer on the three public clips.
The generated QPC mapping has been checked against source text and the SDK
canonical paths, but needs validation against displayed words on devices.
An experimental loader now checks the canonical tokens and word boundaries of
each supplied lattice verse against the active SDK reference and preserves
stop modes and variant labels. A temporary lattice generated from `quran-p2g`
revision `233568a621d853da7969ed174ddff625ef9ace5e` passed this canonical
comparison for all 6,236 verses with web SDK 3.1.3 and model 4.0.0. This does
not validate the lattice's alternate forms, dependencies between variants, or
their mapping to the displayed Mushaf. The generated lattice is now bundled
and used in the V4 Tasmee evaluation path.

For accuracy evaluation, Quran Lab publishes the
[Quran Tajweed Benchmark](https://huggingface.co/datasets/Quran-Lab/quran-tajweed-benchmark)
under NPL-1.2. Its public recordings are correct recitations and can measure
false alarms; its labelled recordings containing mistakes are private. A public
correct-only evaluation cannot establish error-detection recall. Run both
engines on the same licensed clips and preserve each legal reference variant.

An additional public candidate is Maghraby et al.'s [Surah Al-Ikhlas error
dataset](https://data.mendeley.com/datasets/sxtmmr6mvk/1), DOI
10.17632/sxtmmr6mvk.1, CC BY 4.0. The authors describe 1,506 recordings
checked by five Quran experts. A [public mirror](https://huggingface.co/datasets/MuazAhmad7/Surah_Ikhlas-Labeled_Dataset)
provides clip labels and descriptive fields. Its filename suffix disagrees
with the metadata classification in two rows, and one error-labelled row has
no error details; exclude and independently review such inconsistencies. One
published preparation script matches spreadsheet rows by filename; another
assigns metadata by row order, so independently verify the provenance of any
specific mirror fields before using word-level annotations.

On 2026-11-14 an exploratory, non-random sample from the mirror revision
`973b5ef1d1532bcbe7e9a5a5b0dce125cc4d0dac` used two clips per verse and label,
excluding filename/label disagreements and error rows without locations. Using
the web SDK 3.1.3/model 4.0.0, replay through the current Tasmee V4 evaluator
produced at least one candidate flag for 2 of 8 error-labelled clips and 0 of
8 correct-labelled clips; all 16 matched a range. This checks only whether any
flag occurred, not whether it identified the labelled error or its location.
The tiny convenience sample, one surah, uncertain coverage, and unvalidated
metadata do not establish accuracy, recall, or readiness for learner feedback.
The preparation and replay commands are in the probe README; audio, decoded
model output and captured heads remain outside the repository.

A second exploratory sample used seed 112, ten clips per verse and binary
label, and no repeated participant across its 80 clips. The same V4 evaluator
flagged 13 of 40 error-labelled clips and 2 of 39 matched correct-labelled
clips; one additional correct-labelled clip had no matched range. The other 27
matched error-labelled clips had no candidate flag. This is an any-flag clip
count: it does not show whether a flag corresponds to the labelled mistake,
which rule was assessed, or whether the dataset labels are all accurate. The
sample covers only one surah and the test was not a blinded, representative
validation. These findings do not justify enabling learner-facing verdicts.
An audit of this sample's metadata found that all 40 error-labelled clips
mention qalqalah, and 16 name multiple locations. The model calibration marks
qalqalah experimental, and the production evaluator does not issue its
judgment. The 13 error-labelled clips with any flag had candidate consonant
flags in 9 clips and vowel flags in 6 (categories overlap); none had a tajweed
flag. These flags must not be counted as detection of the annotated qalqalah.
Conversely, an unflagged clip cannot be counted as a failed assessment of a
rule this evaluator did not attempt.

Two further candidate sources were inspected on 2026-11-14, but not used for
calibration or learner feedback:

* [IqraEval QuranMB.v2](https://huggingface.co/datasets/IqraEval/QuranMB.v2)
  has public audio under CC BY-NC 4.0. Its [ground-truth labels](https://huggingface.co/datasets/IqraEval/IqraEval_Test_GT)
  require accepting access conditions, and no authorized local sign-in was
  available. The [organizers](https://huggingface.co/spaces/IqraEval/SharedTask_ArabicNLP2025/blob/5363b8164a1d2f42ac86f0c8de5ea73315785b0e/index.html)
  describe deliberate speech errors read as standard Arabic without tajweed:
  the data could help study phoneme errors, but is not evidence of tajweed
  assessment. A reformatted public copy claims to include the gated labels;
  its provenance and reuse conditions were not established, so it was not
  used to bypass the original access conditions.
* [quran-recitation-errors](https://huggingface.co/datasets/sobolev210/quran-recitation-errors)
  revision `d196cd3132c69cd361d28cf6a8b442ae4e0bf0b4` states an MIT license
  and contains both Hafs and Qaloon rows, reviewer indicators and word-level
  categories. Its dataset card does not explain the recordings' provenance,
  review protocol, or completeness of annotations. An incomplete metadata audit
  of 842 of 1,042 rows (two pages failed) found 143 Hafs rows with a reviewer
  field other than `not reviewed`, covering 25 recording IDs; 36 rows had at
  least one annotated category. These are rows, not independent speakers or
  verified ground truth. The categories included 34 `Letters` annotations.
  None of this establishes that missing labels mean correct pronunciation.

An exploratory local run on `correct_t1w_test` (three correct clips, two
reciters; dataset revision `8f795562d4404dbfdac95ba5aac85c1dc02e4983`) gave
V3.1 35 phoneme edits against 129 selected legal units and V4 31 against 130.
V3 used the app's batch normalization and sherpa-onnx 1.13.8; V4 used the web
SDK 3.1.3 with model 4.0.0. Quran Lab's `quran-p2g` converted V3's phonetic
script into the V4 matching space and the published lattice scorer selected
legal paths. This tiny sample is not representative and measures recognition,
not the apps' error-detection or correction accuracy. The reproducible harness
and its caveats are in `tool/tajweedformer_web_probe/README.md`.

On 2026-11-14 the complete CTC site scan was also run on those same three
correct clips, using SDK 3.1.3/model 4.0.0 and the default balanced calibration.
The current selected-range evaluation returned 3, 5 and 8 flagged windows
respectively; scoring each whole verse returned 6, 5 and 9. All clips are
labelled correct, so these are false alarms on this small sample. A trial that
required agreement with the decoder reduced selected-range flags to 2, 3 and
6, but its effect on missed errors is unknown and it is not enabled. This is
not sufficient evidence for changing model thresholds or issuing judgments.

After adding the exact-decoder guard to madd timing, replaying the same three
captures produced 3, 5 and 8 selected-range candidate flags, with zero madd
flags. This is a coverage observation, not evidence that madd detection is
accurate: a mismatching or partial path is deliberately left unassessed, and
these clips alone cannot measure missed errors. Benchmark output is restricted
to aggregate counts; captured model outputs remain outside the repository.

The site scan now shares CTC forward and backward paths across single-edit
alternatives. On the same captured SDK outputs its selected-range flags remain
3, 5 and 8; the local Mac evaluation took 63, 127 and 110 ms respectively in
one run, versus approximately 800, 3400 and 2600 ms before. This measures only
the evaluator, not capture, inference or iPhone performance. Randomized tests
compare edit scores with the full CTC calculation, including repeated tokens.
Live display shows a neutral underline when at least one unit of a word is
matched. This indicates progress only, not complete recognition or correctness.

On 2026-11-15 the in-progress integration was re-verified without any voice
evaluation. `flutter analyze` reported no issues, and the full suite passed
295 tests with 4 skipped; the audio- and key-gated probes (benchmark, SDK
sample, labelled-clip replay) skip themselves when their inputs are absent.
The live-corrector block was re-checked in code and is now guarded by a
regression test, `test/tajweedformer_corrector_block_test.dart`: starting a
session in corrector mode with V4 fails with the user-facing message before
any engine or range preparation. The audit also confirmed the surrounding
guarantees: the V4 engine never invokes `onWordDone`, so live tracking issues
no correctness verdicts; V4 results always carry `assessmentComplete: false`,
keep word statuses neutral outside the debug-only diagnostics flag, and leave
`completedWords` at zero, so an incomplete assessment can neither color words
nor advance a mastery loop; a partial word-retry result stays inconclusive.
This run re-verified the wiring only; it is not a recognition or accuracy
validation, and the pinned SDK versions (Android 3.1.5, Apple 3.1.4,
web 3.1.3) matched the latest published ones on that date.

Also on 2026-11-15 a functional review of the shared Tasmee flow produced
five fixes, all covered by the expanded suite:

* Double start no longer kills a live take. The preparing guard now spans
  the whole live launch (microphone permission and V4 take registration),
  a paused or connecting session blocks `startRecording`, and a session the
  V4 engine rejects — because another session owns the active take — no
  longer cancels that take: cancellation is tied to the session that
  registered it, and every failed start still cleans up its own recorder.
  A regression test drives two sessions through one engine and finishes the
  first session normally after the second is rejected.
* The shared control bar now completes the Zipformer corrector loop. A
  frozen word opens a word-correction bottom sheet (word with its reading
  context, listen button, retry recording, expected/spoken chips); a
  correct retry offers continue-acceptance, an incorrect one shows the
  current attempt's feedback, and an inconclusive attempt stays
  non-committal. Closing the sheet resolves the word (skip on external
  dismissal) and resumes the paused session, so the default bar can no
  longer leave a session frozen with no visible way forward. TajweedFormer
  remains blocked from corrector mode.
* Changing the page during recording now rebuilds the new page's reference
  range after the stop-and-evaluate completes, instead of keeping the
  previous page's range for the next attempt.
* Operational logs no longer print the corrector's expected/predicted
  pronunciation symbols, nor the online server URL at engine
  initialization.

A second review round the same day found deeper synchronization and audio
issues in those fixes, also addressed:

* Ownership on teardown. `dispose()` and `cancelV4Live()` now cancel the
  V4 take only when this session owns it, so disposing or cancelling a
  rejected session leaves the owner's take alive; the shared
  matched-words listener is attached only after the engine accepts the
  session, so a rejected start can no longer steal the first session's
  word updates. Tests dispose and cancel a rejected session and verify
  the owner still receives its updates and finishes normally.
* Awaited retry release. A new awaited `RecitationSession.release()`
  tears the retry's recorder down (V4 or batch) without evaluating, and
  resolving a correction awaits that release before resuming the main
  microphone, so the two recorders never contend for the audio channel.
  Batch `start()` honors a release issued while permission or recording
  start is still pending. Tests hold the release future open until the
  recorder's stop completes, and prove a release during microphone setup
  prevents capture entirely.
* Speaker/microphone interplay. The correction sheet disables the listen
  button while the retry is capturing, awaits stopping word audio before
  opening the retry microphone, and stops any previous playback before
  playing the word again — the microphone cannot ingest the sheet's
  speaker audio as an attempt.
* Word-audio availability. The sheet initializes the word-audio service
  itself when the host has not, and shows a dismissible failure notice
  when playback cannot start, instead of failing silently.
* Range-build guard. `startRecording`/`startAyahRecording` await any
  in-flight range build and build for the current page before starting;
  builds are generation-numbered, so a build for a page the user already
  left (rapid flips) completes without applying its stale state.

A third review round the same day tightened the remaining races:

* Disposing an owning live V4 session previously cleared the take-ownership
  flag before its `stopLive`, sending the stop into the merge-segments
  branch that never ends the engine take — the next session was then
  rejected. Dispose now keeps ownership while it stops (or cancels
  directly when no live session exists); a test disposes a live owner,
  waits for terminal state, and starts a fresh session on the same engine.
* Batch `start()` is now memoized and awaited by `release()`: a release
  issued while the recorder's start is still pending cannot return before
  that start settles, so the main microphone is never resumed over an
  unsettled capture start. A gated-start test holds the release open until
  the start gate completes; the start path's own release guards teardown
  directly without awaiting themselves.
* The start guards in both recording paths now arm `isPreparingEngine`
  before the first `await` (range build, audio stop, engine prep) with the
  whole flow in `try/finally`, and re-check mode/session state after each
  wait, so two near-simultaneous start requests cannot both pass the guard
  and open two sessions. The teacher path also re-reads the ayah after a
  range rebuild instead of using a stale capture.
* Word playback now returns an explicit started/not-started result through
  `WordAudioService.playWord` → `WordInfoCtrl.playWordAudio` →
  `QuranLibrary.playWordAudio(ByNumbers)` (previously the service swallowed
  load/play errors), and the correction sheet shows its failure notice from
  that result. A service-level test pins the explicit-false contract on the
  uninitialized path; plugin-dependent load failures remain device tests.

A fourth round closed the last reported races:

* Teacher ayah selection now happens strictly after the newest range build
  settles. The ayah is no longer captured before awaiting `_rangeBuild`,
  because an in-flight build updates the page number at its start while the
  ayah list only changes at its end — page numbers could match with a stale
  list, recording the old page's ayah onto the new page's positions. Both
  start paths now await the newest build, await once more to catch a build
  started during the wait, verify the page number, and only then read the
  ayah/range from the completed list.
* Resolving a correction (skip, accept, or external sheet dismissal) now
  stops the word player and awaits its stop before resuming the main
  microphone, closing the speaker-into-microphone window that remained
  when skipping while the auto-played word was still sounding.
* Batch `start()` returns the in-flight start future to a second caller
  instead of starting a second permission/recorder-start sequence on the
  same recorder while the session state is still idle; a delayed-permission
  test issues two starts and asserts a single recorder start.

A fifth round closed the last page/mode-change windows:

* Range freshness is now tracked by completion markers, not by comparing
  page numbers. A build updates the page number at its start but only
  applies the range and ayah list at its end, so number equality could pass
  with a stale list (including a third build started during a second
  wait). Builds now record the page and generation that actually applied;
  a settling helper awaits the newest build and rebuilds until the applied
  range matches the current page at the newest generation, giving up only
  while the page keeps flipping. Both start paths call it before selecting
  the ayah/range, and again after engine preparation, immediately before
  launching the session; the teacher path re-reads its ayah from the
  settled list after engine prep instead of using the pre-prep capture.
* After engine preparation the general start path now re-checks the mode:
  a start that began in recitation mode cancels if the user switched to
  teacher mode (wrong path) or to the blocked V4+corrector combination
  during the wait, rather than launching the old path's session.
* A controller-level settling test (successive build gates, page change
  during engine prep) was attempted and dropped: driving the controller
  initializes the audio stack (AudioCtrl → audio_service → cache manager →
  sqflite), which has no test seams and fails in the VM test environment.
  The settling logic is verified by review; it needs injection seams
  (AudioCtrl/QuranCtrl page state) before it can be pinned by a test.

A sixth round closed the exit-during-settle window: `exitTasmeeMode` now
bumps the build generation and clears the applied-range markers, so a
range build that was in flight when the user left recitation mode
completes without re-applying its reference over the cleared state; and
both start paths re-check that recitation mode is still active (and the
right mode/session state) after their final settling wait, immediately
before launching, so a start request that was awaiting the range when the
user exited or switched modes is cancelled instead of recorded. The same
controller-injection limitation noted above applies to a test for this
window.

A seventh round closed the replacement-build hole in that same exit path:
exit now also bumps a recitation-cycle number, each start request
captures its cycle at launch, and the settling helper aborts — before
starting any replacement build — when its request's cycle has ended or
recitation mode is no longer active. A pending build is still dropped by
the generation guards, but the settling loop can no longer notice the
invalid reference after exit and rebuild a fresh one over the exited
state. The controller-injection limitation still applies to a direct test
of this window.

On 2026-11-16 the remaining V4 integration work was implemented without
any voice, accuracy or calibration testing (all deferred by the
developer). `flutter analyze` reported no issues and the suite passed 333
tests with 4 skipped (the audio- and key-gated probes skip themselves
when their inputs are absent). What changed:

* **Per-category assessment coverage.** A new serializable model
  (`lib/src/tasmee/engine/tajweedformer_coverage.dart`, exported by the
  package) records, for each evaluation category of a V4 take, one of
  `notEvaluated`, `evaluatedNoCandidate`, `candidateNeedsReview` or
  `inconclusive`, plus a reason for every non-decision (missing head,
  missing reference, missing/disabled/experimental calibration, path not
  eligible, unsupported decoded difference, too few sites, no usable
  signal, evaluator not implemented, no matched path). Coverage is
  attached to `RecitationResult` (`coverage` field, JSON key
  `v4_coverage`), survives `toJson`/`fromJson` round-trips, and old JSON
  without the key still restores with `coverage: null` while keeping its
  `assessment_complete` flag — a stored partial V4 result can still never
  be mistaken for a complete one. An empty error list no longer implies a
  rule was checked.
* **Evaluators report coverage.** `evaluateTajweedFormerTake` now returns
  per-site-class coverage and preserves its `incomplete` flag as the
  `unsupported_differences` category instead of dropping it when the
  result is built. The madd, qalqalah and gemination evaluators return
  `(errors, coverage)` records explaining why the category stayed
  unassessed (path mismatch, missing head, calibration absent/`off`/
  experimental-not-enabled, too few normalization sites, missing or
  non-canonical timing reference). Experimental qalqalah still requires
  the explicit debug diagnostics flag and gemination's `off` calibration
  is still never bypassed; both are only more visible now.
* **Ghunna and ikhfa stay declared-unsupported, with a documented
  obstacle and extension path.** The SDK's public reference page
  (`skills/quranlab-sdk ref/reference.md`) lists `attr_ghunna` among the
  model heads and the public phonetics dataset carries the ghunna kinds
  (`asl`, `mushaddadah`, `ikhfa`, `idgham`) with lengths. The calibration
  served with the current model build has no ghunna section and the
  head's class layout is undocumented for this build, so no judgment is
  implemented and none may be inferred from a written reference or from
  the nasal token alone. `describeTajweedFormerGhunnaCoverage` reports
  `signalUnsupported` today and flips to `evaluatorNotImplemented` if a
  calibration section ever ships — the point at which an evaluator must
  be written against that documented layout. The take-window cropper now
  also windows `attr_ghunna` consistently whenever a head with that name
  is present.
* **No-match and failed takes carry their reasons.** Every early
  no-evaluation path of the V4 engine (no heads, no matched range, no
  lattice path, no aligned spans, undecodable WAV, missing range,
  non-Hafs request) returns a result whose coverage states the cause per
  category. `mergePartialV4Results` merges segment coverages with the
  precedence flagged > checked-clear > inconclusive > not evaluated, so
  an unassessed or failed segment can never mask one that did assess a
  category, and merging still never produces `assessmentComplete: true`.
* **MuaalemConfig settings are explicit, not silently ignored.** V4 reads
  only `rewaya` (Hafs only — anything else is rejected before recording)
  and `tajweedFormerPreset`. Every other field is now rejected before the
  microphone opens when set beyond its Hafs default, with the setting
  names in the error (`MuaalemConfig.unsupportedTajweedFormerSettings()`,
  checked in `RecitationSession._verifyEngineConfig` for both the batch
  and live paths). The classification table follows below.
* **Word-retry acceptance is a policy.** The inline decision in the
  controller became `WordRetryAcceptancePolicy`
  (`lib/src/tasmee/controller/word_retry_policy.dart`): Zipformer keeps
  the exact `isContextWordRetryAcceptable` ratio contract, and V4 uses
  `InconclusiveWordRetryPolicy` — every attempt stays inconclusive until
  a proven verdict source covers the target word. Wiring the interface is
  explicitly not a verdict source. Sheet cancel/skip/retry and release
  behavior are unchanged from the earlier rounds.
* **Teacher loop ends in an explicit decision, not an inference.**
  `TasmeeTeacherPhase` gained `awaitingDecision`: after capture and
  evaluation the phase is `awaitingDecision` unless a host-set hook
  (`TasmeeCtrl.teacherAdvancePolicy`) accepts a *complete* result
  (`assessmentComplete` with a match) — then, and only then, the loop
  advances to the next ayah or reports `pageDone`. Without the hook the
  decision stays manual via `selectTeacherAyah`; ending capture or
  covering words is never mastery. The transition logic is a pure
  function (`tasmeeTeacherDecisionAfterEvaluation`) tested without the
  controller's audio dependencies.
* New and extended tests (all mock-only, no microphone): coverage model
  round-trip/merge/legacy-JSON (`test/tajweedformer_coverage_test.dart`),
  evaluator coverage reasons (`tajweedformer_evaluation_test.dart`,
  `tajweedformer_madd_test.dart`, `tajweedformer_qalqalah_test.dart`,
  `tajweedformer_gemination_test.dart`), engine coverage propagation
  (`tajweedformer_recitation_engine_test.dart`), unsupported-config
  refusal before capture (`test/recitation_session_v4_config_test.dart`,
  `test/muaalem_config_v4_test.dart`), retry policies
  (`test/word_retry_policy_test.dart`), and the teacher decision
  (`test/tasmee_teacher_decision_test.dart`). These verify conditions and
  plumbing on synthetic data only; they say nothing about recognition or
  judgment accuracy.

### MuaalemConfig settings versus TajweedFormer V4

| Setting | V4 status |
| --- | --- |
| `rewaya` | Affects the reference only. Hafs is the only riwaya with bundled references; any other value is rejected before recording or evaluation (session check and engine check) instead of falling back to Hafs. |
| `tajweedFormerPreset` | Actually supported: selects V4's own evidence preset (sensitive/balanced/strict) from the shared strictness setting. It is an evidence-preset choice, not a validated feedback guarantee. |
| `recitationSpeed` | Unsupported; rejected when non-default. |
| `maddMonfaselLen`, `maddMottaselLen`, `maddAaredLen`, `maddLazemLen`, `maddLeenLen`, `maddMottaselSukoonLen` | Unsupported; rejected when non-default. V4 madd classes and allowed lengths come from the model calibration's cuts and the timing reference's `allowed` lists; host lengths are never read. |
| `takbeer`, `ghonnaLamAndRaa`, `ghonnaNaqis`, `sakenBeforeHamz`, `medOomMadd`, `dtaah`, `dghnmkhfaa`, `naqlHamzatWassel`, `isbaal`, `bslamYaa`, `naskhStyle`, `haaPronunciation`, `tafkheemLetters`, `istitala`, `tafashie`, `safeer`, `qalqla`, `ghonna`, `tikraar`, `hamsOrJahr`, `shiddaOrRakhawa`, `tafkheemOrTaqeeq`, `itbaq` | Unsupported; rejected when non-default. V4 follows the SDK's fixed canonical Hafs path (Hafs 'an 'Asim via tariq al-Shatibiyyah, per the SDK's published reference); no host-adjustable variant exists in the current model build. |

A field's presence in the shared interface is not support: hosts that
need a variant setting must wait for a documented V4 source for it.

A review of that work the same day closed five correctness gaps in the
coverage model and the session lifecycle, each pinned by a test:

* **Partial coverage is represented, never absorbed.** Merging segments no
  longer lets an assessed segment hide that another segment failed the
  same category: a category assessed in some segments and blocked in
  others merges to `inconclusive` carrying the first blocking reason, its
  assessed site count, and a new `unassessed` counter (assessment units —
  skipped sites, or whole segments/verses when sites cannot be counted).
  A flagged candidate still wins the state, but the unassessed units of
  the other segments are counted on the entry; only a category clear in
  every segment that mentions it stays `evaluatedNoCandidate`. The
  counter serializes with the entry (`unassessed` key).
* **Madd and the attribute evaluators never report "clear" over skipped
  sites.** Madd tracks sites skipped for disabled cuts or unmeasurable
  alignment and verses that could not be compared with the canonical
  timing reference; any skip makes the category `inconclusive` with the
  cause (or `candidateNeedsReview` with an `unassessed` count when a
  candidate was flagged elsewhere). Qalqalah and gemination count their
  skipped letters, out-of-range windows and verses without position lists
  the same way.
* **Every standard site class appears in a take's coverage.** Classes
  with no candidate in the reference path are reported
  `notEvaluated`/`noEligibleSites` (or `missingCalibration` when the
  served calibration has no section for the class) instead of being
  absent from the map. `sites` now counts distinct candidate positions,
  not alternatives: a consonant-substitution class covering one position
  with 27 alternatives reports one site.
* **A stale range-completion timer cannot stop a replacement session.**
  The 800 ms deferred stop after `onRangeComplete` now checks that its
  issuing session is still the controller's current one
  (`tasmeeDeferredStopAppliesToCurrentSession`, a pure predicate tested
  in `test/tasmee_deferred_stop_test.dart`); a callback from a session
  that ended and was replaced within the delay no longer stops the new
  recording. The teacher-endpoint and retry callbacks already carried
  this identity guard.
* **The display copy of a result keeps its coverage.**
  `_resultWithoutAcceptedErrors` now copies `coverage` alongside the
  other fields, so filtering accepted corrections cannot drop the
  assessment reasons from a displayed or saved result.

That first review round closed with `flutter analyze` clean and the
suite at 339 tests passed, 4 skipped.

A second review round the same day tightened how coverage detail
survives merging and how absent calibration and site-level failures are
recorded:

* **Both counters survive any merge.** `sites` and `unassessed` are now
  summed from every entry that carries them regardless of its state: an
  `inconclusive` segment keeps the sites it did assess, and a
  `candidateNeedsReview` segment keeps its unassessed units and their
  cause — even when merging a single segment, which is what the session
  path does. A blocked segment with no explicit counter still counts as
  one unassessed unit.
* **A candidate class with no calibration section no longer fails the
  take.** `tryReadTajweedFormerSiteCalibration` returns null for a class
  the served calibration does not know (anything else malformed still
  throws). The difference loop records the decoded difference as
  `inconclusive`/`missingCalibration` (or `calibrationDisabled`/
  `calibrationExperimental` for a present-but-unvalidated class) instead
  of throwing, and the scoring loop skips the class with its coverage
  entry already stating why.
* **Site-level and verse-level causes are distinct.** The madd, qalqalah
  and gemination evaluators separate verses that could not be compared
  with the canonical reference (`missingReference`) from sites inside a
  compared verse that could not be measured — unaligned timing spans or
  evidence windows past the head frames (`pathNotEligible`), and madd
  cuts disabled by calibration (`calibrationDisabled`). A flagged
  category carries its unassessed count **and** the precise cause on the
  entry (`reason` may now accompany an assessed state to explain its
  `unassessed` units; it serializes with it).

With these fixes `flutter analyze` stays clean and the suite passes 344
tests with 4 skipped. As before, controller-level coordination windows
(page/mode change during settle) are covered by the pure predicates
above rather than controller-driven tests, because driving the
controller initializes the audio stack with no injection seams — the
limitation already recorded for the settling logic.

A third review round closed the last two coverage-diagnosis gaps:

* **Flagged madd and qalqalah keep their measured site count.** Their
  `candidateNeedsReview` branches now carry `checkedSites` beside the
  `unassessed` count and its reason (gemination already did), so the
  number of assessed sites exists before the merge is ever asked to keep
  it. Tests pin the evaluators' own output — not a synthetic entry — both
  directly and through a single-segment merge, which is what the session
  path does.
* **`tryReadTajweedFormerSiteCalibration` separates absence from
  corruption.** It validates the calibration envelope (`format`,
  contexts, the selected context, and a `sites` map) before answering,
  and returns null only for a genuinely absent class key; a key present
  with a wrong type — or any malformed structure — throws exactly like
  the strict read, never surfacing as `missingCalibration`. Tests cover
  the absent key, the wrong-typed key, missing `format`, missing `sites`,
  a non-map `sites`, and an unknown context.

With this round `flutter analyze` stays clean and the suite passes 347
tests with 4 skipped.

A fourth review round closed one last edge case in the same reader: when
the class key is absent, `tryReadTajweedFormerSiteCalibration` now
validates the shared structure — including `fusion` — before answering,
through a shared `_validateSharedCalibrationStructure` used by both the
strict read and the tolerant one. A calibration whose `fusion` is missing
or corrupted can no longer surface as `missingCalibration` for an absent
class; it throws, as the contract states. The new test combines an
absent class key with a missing `fusion`, wrong `heads` and an invalid
`inter1_prep`. With this round `flutter analyze` stays clean and the
suite passes 348 tests with 4 skipped.

A fifth review round completed the shared `fusion` validation: the clip
values themselves (numeric, finite, ordered) moved into
`_validateSharedCalibrationStructure`, so an absent class key can no
longer mask a corrupted clip (`['bad', 30]`, `[30, -30]` or a non-finite
bound) — the reader throws for the corrupted structure instead of
answering `missingCalibration`. With this round `flutter analyze` stays
clean and the suite passes 349 tests with 4 skipped.

SDK pin status on 2026-11-16: Android 3.1.5 and Apple 3.1.4 match the
latest published releases; web SDK 3.1.6 was published after the bundled
3.1.3 (severity: recommended, no call changed) and has not been upgraded
without the developer's approval.

On 2026-11-16 a second pass worked through the remaining V4 plan stages
with mock engines and recorders only (no microphone, no accuracy testing,
all deferred by the developer). Stages 3–8 of the plan were re-audited
against the code and the suite; no new gaps were found beyond the three
lifecycle holes below, which were fixed and pinned by tests:

* **Repeated and overlapping stops no longer double-evaluate.** The batch
  `RecitationSession.stop()` is now memoized like `stopLive()`: two
  overlapping stop requests (silence timer + duration cap + a manual stop)
  evaluate the recording once, and stopping again after completion returns
  the completed future instead of re-reading the deleted file and flipping
  a finished session to `error`. A new recording start clears the memo, and
  `release()` now also awaits an in-flight stop, so a release issued while
  a stop is evaluating waits for it instead of tearing the recorder down
  under the file read. `test/recitation_session_stop_test.dart` pins all
  three behaviors with a counting engine and a gated file recorder.
* **`TasmeeCtrl.stopRecording()` is memoized.** Concurrent stop requests —
  the teacher silence endpoint, the deferred range-complete stop, the stop
  button, and page/mode changes during recording — could previously both
  run to completion: the result was applied twice and, in teacher mode,
  `_applyTeacherDecision` ran twice, advancing the teacher loop two ayahs
  for one recitation when a host `teacherAdvancePolicy` accepts a complete
  Zipformer result (V4 results can never satisfy it). A second call now
  returns the in-flight future; the memo clears on completion so an
  independent later stop proceeds normally. As with the earlier controller
  guards, this is verified by review — driving the controller still
  requires audio-stack injection seams that do not exist (the limitation
  already recorded above); the session-level half of the guarantee is
  covered by the new tests.
* **`TasmeeCtrl.onClose()` disposes the word-retry session.** Closing the
  controller mid-retry previously leaked the retry recorder and its timer;
  `onClose` now disposes them through the same awaited-release path as
  every other exit.

With this round `flutter analyze` stays clean and the suite passes 352
tests with 4 skipped. Plan stage 9 (real-device and platform testing)
remains partially done as documented above — no physical Android device,
no physical-iPhone V4 take, no release build or App Attest validation —
and the developer has deferred microphone and accuracy work (stage 10)
until explicitly requested. Stage 11 (making V4 the default engine)
remains blocked on measurable acceptance criteria agreed with the
developer plus passing device tests; V4 stays opt-in and Zipformer stays
the default.

Later the same day a developer review found three more defects in the
stop lifecycle and the V4 failure-result contract. All three were fixed
and each fix is pinned by a test that fails without it:

* **A stale stop completion can no longer touch a replacement session.**
  `_stopRecordingImpl` now ties result application, the teacher
  decision, and session cleanup to the identity of the session it
  stopped: a stop that is still awaiting engine evaluation when the user
  exits recitation mode and starts a new recording completes without
  applying the old result to the new state, without running the teacher
  decision, and — the damaging part — without `_cancelSession()` killing
  the replacement recording. Session launch was refactored into
  `_attachSession` (which also disposes a previous state worker on
  reattach), with a `@visibleForTesting attachSessionForTesting` seam so
  the real controller can be driven without initializing the audio
  stack. `test/tasmee_ctrl_stop_lifecycle_test.dart` suspends the old
  stop at a gated client finish, attaches and starts a replacement
  session on a separate engine, then opens the gate: the old completion
  leaves the new session recording with `lastResult` untouched, and the
  new session remains stoppable afterwards.
* **A stop request without a session can no longer poison later stops.**
  `stopRecording()` with no session returns immediately without storing
  a completed stop in the memo, and the memo is cleared through
  `whenComplete` on every path (early returns included), so a later
  session's stop always runs its own full path instead of inheriting a
  stale completed future. The companion test calls stop with no session,
  then attaches, starts and stops a real session.
* **Every V4 failure result now states `assessmentComplete: false`
  explicitly, with its coverage reason.** The default-`true` constructor
  leaked into ten early-return paths of `evaluateLive` and
  `correctRecitation` (non-Hafs, missing heads, no matched range or
  path, empty lattice window, empty decoded tokens, no aligned spans,
  undecodable WAV, missing range); a host saving or restoring such a
  result could read an unassessed take as complete. The non-Hafs live
  path also gained its `missingReference` coverage. A new coverage
  reason, `noUsableSignal`, marks a take that carried no audio at all:
  the live silence path (zero peak) keeps the V4 result incomplete with
  that reason across every category instead of silently dropping
  coverage; non-V4 engines keep their existing result contract on that
  shared path. `test/tajweedformer_failure_results_test.dart` covers the
  non-Hafs, undecodable-WAV, missing-range and silence cases, each with
  a `toJson`/`fromJson` round-trip asserting the flag and reason
  survive saving.

With these fixes `flutter analyze` stays clean and the suite passes 358
tests with 4 skipped. All of this is wiring and contract verification on
synthetic data; none of it measures recognition or feedback accuracy,
which remains deferred with the device tests.

A follow-up review of that fix found one more overlap hole, closed the
same day: the memoized stop request was not tied to the session it
stopped, so when a replacement session started while the old stop was
still awaiting evaluation, a stop request for the *new* session returned
the old session's pending future — the new recording's stop was silently
swallowed and could keep recording with nothing able to stop it. The
stored request now records its session (`_stopRecordingSession`) and is
returned only while that session is still the current one; a stop
requested for a replacement session replaces the stale entry and runs
its own full path, and with no current session the caller still awaits
a draining old stop instead of starting a new one. The new test in
`test/tasmee_ctrl_stop_lifecycle_test.dart` stops the replacement
session while the old stop is still gated: the replacement finishes and
produces its result, the old request stays pending at its gate, and
completing it afterwards cannot overwrite the replacement's result or
state. Without the identity binding the test fails with the replacement
session still recording. With this round `flutter analyze` stays clean
and the suite passes 359 tests with 4 skipped.



## Per-category V4 sensitivity and web SDK 3.1.6

The optional web bridge is built with SDK 3.1.6. The build and the SDK's own
sample through the bundled bridge ran without a microphone; this is not a
real-device microphone or accuracy test.

V4 settings now offer independent letter, vowel and madd sensitivity, with
vowel and madd assessment optionally skipped. They select the corresponding
model calibration presets for experimental candidate evidence; skipped classes
are recorded as `skippedByUser`. Older saved global strictness supplies the
initial values where category settings do not exist. Existing callers supplying
only `tajweedFormerPreset` retain the previous behavior. These controls do not
change Zipformer or the online engine. V4 remains an incomplete assessment;
candidates remain hidden from learners in release builds.

The learner-facing settings sheet (shown only while the TajweedFormer engine is
selected) now mirrors the nahtadi tolerance panel where the behavior actually
exists in this library: three general presets (مُيسّر / متوازن / متقن) with a
one-line description, a "مخصّص" badge plus description once any axis deviates
from a preset, and the three axes (الحروف والكلمات, التشكيل والحركات, المدود)
each with its subtitle and level chips including تجاهل where skipping is
allowed. A scope note states these controls affect the experimental V4
indicators only and never issue a final correctness verdict. Nahtadi's flexible
waqf-and-wasl and experimental qalqalah toggles were deliberately not copied:
the waqf path here relies on lattice paths and qalqalah is not cleared for
display, so a toggle would not change real behavior. The sheet UI and behavior
are covered by `test/tasmee_tolerance_settings_test.dart` (independent axis
changes, preset application including the legacy strictness used by Zipformer
word acceptance, custom badge round trip, and madd skip); tolerance wiring and
coverage are covered by the tolerance profile, evaluation, madd and engine
tests. No new audio evidence exists in this round, so the field-evaluation
prerequisites in the comparison plan remain open.

## Runtime V4 model download (user-triggered prefetch)
The V4 neural model is not bundled with the app; the Quran Lab SDK fetches its
protected files itself. Until now that happened invisibly inside the first
`model()` call. Following the nahtadi pattern (`TajweedFormerFlutter.prefetch`
with an unmetered-only option), the model is now a runtime download the user
controls:

- The inference client contract gained `prefetch(key, unmeteredOnly)`,
  `prefetchProgress` (byte counters) and `removeModels(key)`. The Android and
  Apple clients route native `prefetchProgress` callbacks through their method
  channels (the handler now installs in the constructor so a short-lived
  download client works before `initialize`), and the web client calls the
  bridge's new `prefetch`/`removeModels` exports (web bridge rebuilt with the
  wrapper in `tool/tajweedformer_web_probe/bridge.js`).
- The native bridges open a dedicated, kept-alive download client so prefetch
  works before initialize: Android `TajweedClient.prefetch(unmeteredOnly)`
  (`android/src/tajweedformer/.../TajweedFormerAndroidBridge.kt`) and Apple
  `TajweedClient.prefetch(unmeteredOnly:onProgress:)` plus `removeModels()`
  (`darwin/quran_library/Sources/quran_library/QuranLibraryTajweedFormerApplePlugin.swift`).
  The SDK keeps the files in its own storage (NPL-1.2; nothing is read outside
  it).
- `TajweedFormerPrefetchService` (`core/services/`) wraps this with a
  replaceable client factory; the app key comes from `QURANLAB_KEY` (dart
  define) or the Apple host's Info.plist. `TasmeeCtrl.downloadV4Model` /
  `removeV4Model` / `setV4WifiOnly` drive it, persist readiness
  (`TASMEE_V4_MODEL_READY`) and the Wi-Fi-only choice
  (`TASMEE_V4_WIFI_ONLY`), and `_ensureEngineReady` downloads on the first V4
  session when the user has not — exactly like the Zipformer
  `downloadModelIfNeeded` gate.
- The settings sheet shows, under the TajweedFormer engine: a download button
  with "التنزيل عبر Wi-Fi فقط" and a live percentage while downloading, an
  offline-ready row with "حذف النموذج" once downloaded, and the Arabic key /
  bridge errors when they occur.

What deliberately did not change: the SDK engine code itself still ships at
build time (Gradle `ai.quranlab:tajweedformer`, the Apple Swift package, the
bundled web bridge) — this is identical to nahtadi, whose plugin also compiles
the SDK in; only the model files are a runtime download. The library's own
V4 reference assets (`assets/quran_lab/*.gz`, ~2.3 MB of lattice/QPC-map/
timing data) also stay bundled; they are the library's evaluation data, not
the model. Verification this round: 381 unit/widget tests pass (prefetch
service, controller flows, settings sheet states), `flutter analyze` clean,
`:quran_library:compileDebugKotlin` succeeds with the TajweedFormer source
set enabled, the Apple probe `xcodebuild` succeeds, and the web bridge
rebuilds. No real-device download or microphone test has been run yet.

### Host API keys (QuranLabKeys)

## Field validation 2026-11-16 and result display enabled

Real labelled audio from the developer (Al-Fātiḥa 1–7, teacher mode, captured
with the debug-only `TAJWEEDFORMER_CAPTURE` hook in `evaluateLive`) drove the
first accuracy measurement of the site evaluation:

- Correct complete takes (5, including one joined into the next ayah by wasl
  and one joined from the tail of the previous): **zero false flags at all
  three tolerance presets**.
- Deliberate labelled errors (8 takes: letter substitution, vowel change,
  word deletion, short madd, and a repeat of the vowel error): the **متقن
  (strict/sensitive) preset catches 7/7**; the default متوازن catches 4/7
  (it misses the acoustically-close د→ت, the short madd, and one vowel-error
  take).

Three real bugs surfaced and were fixed with unit tests: forced alignment
stretched the reference over continued speech (false م→ر/م→ب substitutions on
the last word) — replaced by a free-end alignment that crops it; a forced
connected boundary form flagged the boundary kasra the decoder drops — both
boundary forms are now tried and the cheaper wins; a hamzat al-wasl deletion
at a connected (cropped) start was flagged although elision is the correct
recitation there — such candidates are now skipped.

**Display is therefore enabled**: `assessmentComplete` now reflects the
evaluation's actual completeness, so a fully evaluated V4 take shows its
error summary and cards in the result sheet exactly like the Zipformer
engine. Still outside the validated scope and deliberately conservative:
single-word retry takes (`InconclusiveWordRetryPolicy` stays), the resumed
take after a word retry (still incomplete), and nahtadi's own evaluator
(not ported). The capture hook and the labelled-clip probe
(`TAJWEED_LABELLED_PATH`) remain available for future re-measurement.

### Host API keys (QuranLabKeys)

Key resolution is now a single host-facing API instead of dart-define-only:
`QuranLibrary.init(quranLabKeys: QuranLabKeys(android:, apple:, web:,
desktop:))` stores the host's per-platform keys in memory only (never
persisted, never logged). `resolveQuranLabKeyForPlatform()`
(`engine/tajweedformer_key_source.dart`) picks the field for the current
platform, then falls back to the `QURANLAB_KEY` dart-define; the Apple
Info.plist fallback stays inside `initTajweedFormer`. Both
`TasmeeCtrl._ensureEngineReady` and the prefetch service read the key through
this resolver (the service keeps a test-only override). No end-user key field
was added to the settings sheet: the key belongs to the host developer, not
the learner. README gained the full opt-in section (bridge flags, key
registration at sdk.quranlab.ai, resolution order, download behavior,
troubleshooting).


## Bridges are built in (2026-11-16)

The library is public, so the bridges now ship inside it and hosts add
nothing manually: the Apple bridge moved from the separate
`quran_library_tajweedformer_apple` package into the main package's shared
Darwin source (`darwin/quran_library/`, declared in `pubspec.yaml` under
`ios`/`macos` with `sharedDarwinSource`), and Android flipped to
enabled-by-default — `quranLibraryDisableTajweedFormer=true` opts out for
hosts that do not want the ~3.6 MB engine code. The web bridge was already
bundled. The only remaining host step is the app's own QuranLabKeys.
Verified: example iOS simulator build succeeds with the plugin compiled in
(class symbols in the Runner dylib), `:quran_library:compileDebugKotlin`
succeeds with no gradle property, and the full suite passes.
