# Tasmee Mode (AI Recitation Checking) — Design

Date: 2026-08-31
Branch: `feature/ai-tasmee-mode`
Source of ported engine: `quran_audio/lib/src/recitation/` (commit on main at port time)

## Goal

Add an AI recitation-checking mode ("التسميع") to `quran_library`. Entering the mode from
`_QuranTopBar` hides all mushaf words (ayah-end numbers stay visible), replaces the ayah-audio
bar with a record/stop control, and hides the other overlay controls. While the user recites,
words are revealed progressively: the current word is highlighted, and each completed word is
colored green (correct) or red (incorrect) after its pronunciation completes. Stopping opens a
bottom sheet with results and corrections.

## Decisions (approved by maintainer)

- **Engines**: both — offline Quran-Lab zipformer v3.1 (default, live streaming) AND optional
  quran-muaalem server (batch only, no live reveal).
- **Scope**: the current mushaf page (multi-ayah, possibly multi-surah).
- **Live feedback**: neutral progressive reveal + current-word highlight; correctness coloring
  fires only after the word is fully pronounced (`onWordDone`).
- **Local model is NOT bundled in assets** — downloaded at runtime (73MB, GitHub Release
  `zipformer-model-v1`) into the app-support directory; validity = size > 60MB.
- **Git**: all work on `feature/ai-tasmee-mode`; commits per milestone; main untouched.

## Architecture

New self-contained module `lib/src/tasmee/` (own barrel `tasmee.dart`, like `audio/` and
`tafsir/`), exported from `lib/quran_library.dart`:

- `engine/` — ported near-verbatim from quran_audio (interfaces, session, muaalem client,
  sherpa engine, units/reference/aligner/error-detector/madd-timing, wav decoder,
  asset loader, DTOs).
- `core/services/tasmee_model_service.dart` — model presence check + dio download w/ progress.
- `controller/` — `TasmeeCtrl` (GetX singleton, `GetInstance().putOrFind`) + `TasmeeState`.
- `constants/tasmee_storage_constants.dart` — GetStorage keys (engine mode, server URL).
- `data/models/styles_models/` — `TasmeeStyle`, `TasmeeResultStyle` (nullable-label pattern).
- `presentation/widgets/` — control widget, result sheet, settings sheet, model download dialog.

## Engine extensions beyond the verbatim port

1. `QuranReferenceRange` — concatenates a page's ayah references: `units`, `unitVerseIdx`,
   `unitWordIdx`, `wordCount/wordText(verseIdx, wordIdx)`; cached per page.
2. Windowed live alignment — align growing predicted units against a sliding window around the
   last matched reference index (keeps Wagner-Fischer cheap at page scale, ~300 units).
3. `onWordDone(verseIdx, wordIdx, correct)` — emitted when alignment passes a word's last unit;
   derived from that word's ops slice (all-match = correct).
4. Final evaluation over the full range; `RecitationError`s mapped to (surah, ayah, word) and
   then to `ayahUq` via page data.
5. Leading-insert tolerance (default on in range mode) — ignores predicted units before the
   first matched reference unit (basmalah / mid-page start).

## UI integration points

- `_QuranTopBar`: mic button (`showTasmeeButton` on `QuranTopBarStyle`, `assets/svg/mic.svg`,
  `!kIsWeb` gate) — toggles `TasmeeCtrl.toggleTasmeeMode`.
- `_ControlWidget` (both `QuranLibraryScreen` and `QuranPagesScreen`): in tasmee mode replace
  `AyahsAudioWidget` with `TasmeeControlWidget`; hide `JumpingPageControllerWidget`,
  `QuranOrTenRecitationsTabBar`, `DisplayModeBar`, `AutoScrollSpeedSlider`.
- `QpcV4RichTextLine` (+ zoomed `QpcV4FlowingText`): `TasmeeWordFilter.apply(segments)` drops
  hidden-word glyph spans (ayah-end number spans stay); current word highlighted via the
  existing word-selection painting; done words tinted green/red. Tasmee state added to
  `_computeFingerprint`; nested `GetBuilder<TasmeeCtrl>` with per-page id.
- Entering the mode stops `AudioCtrl` playback and auto-scroll; page swiping locked while
  recording; page change (idle) rebuilds the range.

## Assets, deps, permissions

- Assets (`assets/quran_lab/`, all small): `tokens.txt`, `ordered_quran_phonemes.json.gz`
  (858KB), `LICENSE-QuranLab-NPL-1.2.txt`. No ONNX model in assets.
- pubspec: `record: ^6.0.0`, `sherpa_onnx: ">=1.12.40 <1.13.0"`.
- example: `dependency_overrides` pinning `sherpa_onnx_*` endorsers to 1.12.40.
- Package AndroidManifest: `RECORD_AUDIO` (merges into hosts). Example: iOS
  `NSMicrophoneUsageDescription`, macOS mic entitlement. README documents host requirements.
- NPL-1.2: license file shipped + disclaimer shown in the results sheet and documented.

## Testing

- Ported pure-Dart tests: quran_units, quran_reference, phoneme_aligner, error_detector,
  madd_timing, pcm16_to_floats.
- New: `QuranReferenceRange` multi-verse build, `onWordDone` correct/incorrect, leading-insert
  tolerance, model validity check, widget test (words hidden, ayah numbers remain).

## Known trade-offs

- App size grows (sherpa native libs per ABI). First offline use needs internet (model
  download) + a few seconds of model init. Web unsupported (button hidden). Server mode has no
  live reveal (batch nature) — surfaced in the settings UI.
