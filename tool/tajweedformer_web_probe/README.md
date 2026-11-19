# TajweedFormer web probe

This isolated developer probe runs the official SDK and its sample clip. It is
not the Flutter integration or a recitation judge. Use a Quran Lab **web
development** key whose allowed origins include `http://localhost:*`.

The Flutter inference bridge is exposed as `TajweedFormerWeb` through
`package:quran_library/quran_library.dart`. Initialize it with the host app's
origin-scoped web key, use `sample()` for a microphone-free check, and use
`reference()`, `calibration()`, `start()`, `push()` and `finish()` for the
model's verified data and raw output. `chunks` supplies incremental decoded
output. Call `close()` when finished. Tasmee can select V4 explicitly; its
regular mode uses the available platform bridge, while V4's live corrector and
teacher modes are not yet supported.

After changing `bridge.js`, run `npm ci` and `npm run build:bridge` from this
directory to regenerate `assets/tajweedformer_web/`. The embedded web SDK is
licensed under NPL-1.2; see the repository NOTICE and third-party license.

Run `npm install`, set `VITE_QURANLAB_KEY` in your shell or an ignored
`.env.local`, then run `npm run dev` and open the displayed localhost URL. The
first run downloads the model. The page shows the final decoded sample and a
small diagnostic report; it does not request microphone access.

Do not commit the key. A production web key requires a deployed HTTPS origin
and cannot be used for this localhost probe.

## Public correct-recitation benchmark

For a small reproducible smoke comparison, Quran Lab's
[`correct_t1w_test` dataset](https://huggingface.co/datasets/Quran-Lab/quran-tajweed-benchmark)
contains three correct clips by two women under NPL-1.2. This is too small to
represent overall accuracy. It measures phoneme recognition on correct audio,
not error-detection recall or the app's correction verdicts.

Use dataset revision `8f795562d4404dbfdac95ba5aac85c1dc02e4983`, and download
`data/correct_t1w_test/test-00000-of-00001.parquet` and
`scorer/score_v4_bench.py` from that same revision to a temporary directory.
Install `pyarrow` and `numpy` in a Python environment and have `ffmpeg` on PATH.
Then run:

```sh
python prepare_benchmark.py /path/to/test.parquet /path/to/working-directory
# Set QURANLAB_WEB_KEY privately and set CHROME_EXECUTABLE to a Chrome binary.
node benchmark.cjs /path/to/working-directory
python score_benchmark.py /path/to/working-directory /path/to/score_v4_bench.py
python check_lattice.py /path/to/working-directory /path/to/score_v4_bench.py /tmp/lattice-fixtures.json
# From the repository root:
dart run tool/tajweedformer_web_probe/check_lattice.dart /tmp/lattice-fixtures.json
```

The scoring script invokes Quran Lab's published lattice scorer and rejects a
clip whose stated reference is outside its lattice. Audio and hypotheses stay
in the chosen working directory; do not put a key or benchmark files in Git.
The optional lattice check compares the Dart selector's edit costs against the
published scorer for these hypotheses. It does not establish that every Quran
reference or Mushaf word mapping is correct.

To compare the current Zipformer recognizer on the same prepared clips, install
`sherpa-onnx==1.13.8`, `numpy`, and Quran Lab's `quran-p2g` at commit
`233568a621d853da7969ed174ddff625ef9ace5e`. Download the same V3.1 ONNX model
used by the library, then run:

```sh
python compare_zipformer.py /path/to/working-directory \
  --model /path/to/zipformer.onnx \
  --tokens ../../assets/quran_lab/tokens.txt \
  --scorer /path/to/score_v4_bench.py
```

The V3 model used for the initial run had SHA-256
`31755836528da336a6192121cd7bc82cb41752dddb65566fd000b89c8686da6b`.
V3 uses the library's batch amplitude normalization and silence padding; V4
uses the SDK's batch path. `quran-p2g` converts the distinct phonetic alphabets
to a shared space. The report is not a comparison of the apps' correction
logic, and legal reference-path lengths may differ between the two hypotheses.

To replay actual SDK output and CTC heads through the V4 Tasmee evaluator:

```sh
node benchmark.cjs /path/to/working-directory --capture-heads
# From the repository root:
flutter test --no-pub --dart-define=TAJWEED_BENCHMARK_PATH=/path/to/working-directory/sdk-captures.json test/tajweedformer_correct_benchmark_test.dart
```

This prints aggregate false-alarm counts for each correct clip, a full-verse
comparison, timing-flag counts, and processing time, without printing decoded
phonemes or acoustic outputs. It cannot measure missed errors without labelled
incorrect recitations. Keep captured audio and outputs outside Git.

An exploratory clip-level check can also use the independently annotated
[Surah Al-Ikhlas dataset](https://data.mendeley.com/datasets/sxtmmr6mvk/1)
by Maghraby et al. (DOI 10.17632/sxtmmr6mvk.1, CC BY 4.0). This sample uses
the public mirror at a pinned revision and selects two clips for each
verse/label pair; it is a convenience sample, not a representative test set.
The preparer excludes filename/label disagreements and error rows with no
location. It does not establish that the labelled error is within the portion
evaluated, or that a candidate flag corresponds to the labelled error.

```sh
python prepare_ikhlas_probe.py /tmp/quran-ikhlas-probe
# Set QURANLAB_WEB_KEY privately and CHROME_EXECUTABLE to a Chrome binary.
node benchmark.cjs /tmp/quran-ikhlas-probe --capture-heads
flutter test --no-pub --dart-define=TAJWEED_LABELLED_PATH=/tmp/quran-ikhlas-probe test/tajweedformer_labelled_clip_probe_test.dart
```

For the 80-clip exploratory sample, use `--per-stratum 10 --seed 112` with
the preparer. A seeded sample excludes a participant already selected in any
other stratum. The default preserves the earlier 16-clip convenience sample;
its participants can recur across strata.
`python audit_ikhlas_probe.py` summarizes the labelled sample's qalqalah and
multiple-location annotations without reading or printing model output.
Because qalqalah is not implemented in the current evaluator, neither an
unflagged clip nor an unrelated flag establishes its detection performance.

The final command runs from the repository root. It counts clips containing any
flag against binary labels and separately reports unmatched clips. It cannot
measure correct error localization or category-specific detection. The mirror
contains alternative preparation scripts with different metadata matching
methods; verify provenance and labels before using individual error details.
Keep the audio, labels, and model outputs outside Git.

For a separately reviewed labelled dataset, `score_labelled_feedback.py`
computes word/category-level counts and precision and recall from a local JSON
file. Each row records one independently annotated case, verse, zero-based
displayed word and category, plus boolean `expected`, `flagged` and `assessed`:

```json
{"observations": [{"case": "example", "verse": "1:1", "word": 0,
  "category": "letters", "expected": true, "flagged": false,
  "assessed": true}]}
```

Run `python score_labelled_feedback.py /path/outside/git/observations.json`;
only aggregated counts are printed. Supply reviewed negative examples too.
Set `assessed` only when that particular category was actually evaluated at that
word; a matched word or `matchedWordSpans` does not establish this coverage.
The current engine does not expose verified per-category coverage, so this
field requires independent review and must not be inferred from an empty error
list. Unassessed rows are counted separately; `recall` excludes them, while
`end_to_end_recall` counts labelled unassessed errors as misses. These are
word/category metrics, not phoneme-level accuracy; their validity depends on
complete, independent labels and coverage. This tool does not create labels or
establish that a threshold is suitable for learner feedback.

To compare all canonical references with the model's actual reference table,
use the same pinned `quran-p2g`, prepare the temporary data and run the SDK
with an origin-scoped development key:

```sh
python prepare_reference_check.py /tmp/canonical-references.json
# Set QURANLAB_WEB_KEY privately and CHROME_EXECUTABLE to a Chrome binary.
node check_references.cjs /tmp/canonical-references.json
```

The word-count mismatch count compares the SDK's pronunciation-word breaks
with Uthmani whitespace, not the host UI; a mismatch needs a verified mapping.
The script checks canonical forms only, not all legal stop/connection forms.

To audit candidate mappings against this package's QPC word asset and its
existing Zipformer reference text, using the same pinned `quran-p2g`:

```sh
python audit_word_mapping.py --details /tmp/quran-v4-word-audit.json
python -m unittest test_audit_word_mapping.py
```

The audit uses the source's pronunciation-word-to-text-word indices, then
compares the concatenated letters and word boundaries to QPC. It also checks
the separate Zipformer text against QPC. It removes non-letter marks but does
not normalize different letters; `text_mismatch` includes spelling and script
differences and is not proof of an incorrect verse. It permits multiple source
words per displayed word, but rejects a source word spanning displayed words.
The output is a review aid, not a validated mapping: the actual SDK reference,
the displayed Mushaf variant, verse boundary forms, and the candidate maps
must all be verified before using them in Tasmee.

To prepare the separate experimental lattice and check its canonical paths
against the live SDK reference, use the same pinned `quran-p2g` and web key:

```sh
python prepare_lattice.py /tmp/tajweed-lattice.json
python prepare_display_maps.py /tmp/tajweed-maps.json
python prepare_reference_check.py /tmp/canonical-references.json
node check_references.cjs /tmp/canonical-references.json /tmp/sdk-references.json
# From the repository root:
dart run tool/tajweedformer_web_probe/check_lattice_loader.dart /tmp/tajweed-lattice.json /tmp/sdk-references.json /tmp/tajweed-maps.json
```

The exported source data is under Quran Lab's NPL-1.2; compressed copies of
the lattice and word maps are bundled in `assets/quran_lab/`. They are not SDK
models. The loader
compares every canonical token and word boundary to the active SDK reference
and retains each form's mode and variant. The maps normalize script differences
and handle one reviewed spelling difference in 2:72. The canonical
comparison also does not validate alternative forms or any cross-word variant
constraints. The selected path is used by the opt-in V4 Tasmee evaluator;
device and correction accuracy validation remain necessary.

To check the Flutter bridge itself, build `example` with
`flutter build web --debug -t ../tool/tajweedformer_web_probe/flutter_probe.dart`
and supply `QURANLAB_WEB_KEY` through `--dart-define-from-file` pointing to a
git-ignored `.env` file. Serve `example/build/web` at localhost and inspect the
body's `data-result` attribute. This uses the SDK sample and then records a
short microphone take through the experimental audio session. For automated
testing, Chrome can use its fake media device and fake permission UI; manual
testing needs an explicit microphone permission and a test recitation.
