/// Conservative progress tracking for settled TajweedFormer V4 tokens.
/// This reports matches only; it does not decide whether recitation is correct.
library;

import 'tajweedformer_reference.dart';

class TajweedFormerLiveProgress {
  const TajweedFormerLiveProgress({
    required this.matchedUnitIndices,
    required this.currentUnitIndex,
    required this.revised,
  });

  /// Reference indices actually matched; skipped units are not included.
  final Set<int> matchedUnitIndices;
  final int? currentUnitIndex;

  /// The SDK revised a previously settled prefix (e.g. backend replacement).
  /// Consumers must rebuild their display from this snapshot when true.
  final bool revised;
}

/// Tracks exact V4 token matches against a verified, word-mapped reference.
///
/// Unique runs anchor the reader; ambiguous repeats and tentative tokens never
/// advance progress. Differences are not errors and need calibrated scoring.
class TajweedFormerLiveTracker {
  TajweedFormerLiveTracker({
    required List<TajweedFormerReferenceUnit> reference,
    required this.wordBarId,
    required this.blankId,
    this.anchorLength = 3,
    this.maxForwardSkip = 24,
  }) : reference = List.unmodifiable(reference) {
    if (wordBarId < 0 ||
        blankId < 0 ||
        wordBarId == blankId ||
        anchorLength < 2 ||
        maxForwardSkip < 0) {
      throw ArgumentError('Invalid V4 tracker configuration');
    }
    if (reference.any((u) =>
        u.tokenId < 0 || u.tokenId == blankId || u.tokenId == wordBarId)) {
      throw ArgumentError('Reference contains an invalid V4 unit');
    }
  }

  final List<TajweedFormerReferenceUnit> reference;
  final int wordBarId;
  final int blankId;
  final int anchorLength;
  final int maxForwardSkip;
  final List<int> _settled = [];
  final List<int> _pending = [];
  final Set<int> _matched = {};
  int? _next;

  /// Parses the `tokens` and `settled` fields emitted by the web bridge.
  TajweedFormerLiveProgress updateDecodedChunk(Map<String, dynamic> chunk) {
    final raw = chunk['tokens'];
    final settled = chunk['settled'];
    if (raw is! List || settled is! int) {
      throw const FormatException('Invalid V4 decoded chunk');
    }
    final tokens = <int>[];
    for (final value in raw) {
      if (value is! Map || value['id'] is! int) {
        throw const FormatException('Invalid V4 decoded token');
      }
      tokens.add(value['id'] as int);
    }
    return update(tokens, settled);
  }

  /// The SDK's complete token list for the take and its settled prefix length.
  TajweedFormerLiveProgress update(List<int> tokens, int settledCount) {
    if (settledCount < 0 ||
        settledCount > tokens.length ||
        tokens.take(settledCount).any((id) => id < 0 || id == blankId)) {
      throw ArgumentError('Invalid settled V4 token prefix');
    }
    final stable = tokens.take(settledCount).toList(growable: false);
    var revised = stable.length < _settled.length;
    if (!revised) {
      for (var i = 0; i < _settled.length; i++) {
        if (_settled[i] != stable[i]) {
          revised = true;
          break;
        }
      }
    }
    if (revised) {
      _settled.clear();
      _pending.clear();
      _matched.clear();
      _next = null;
    }
    for (var i = _settled.length; i < stable.length; i++) {
      final token = stable[i];
      if (token != wordBarId) _consume(token);
    }
    _settled
      ..clear()
      ..addAll(stable);
    return TajweedFormerLiveProgress(
      matchedUnitIndices: Set.unmodifiable(_matched),
      currentUnitIndex: _matched.isEmpty ? null : _matched.last,
      revised: revised,
    );
  }

  void _consume(int token) {
    final next = _next;
    if (next != null &&
        next < reference.length &&
        reference[next].tokenId == token) {
      _matched.add(next);
      _next = next + 1;
      _pending.clear();
      return;
    }
    _pending.add(token);
    // Bounded search; an ambiguous tail remains tentative until more evidence.
    const maxAnchorWindow = 32;
    if (_pending.length > maxAnchorWindow) _pending.removeAt(0);
    // A two-unit selection cannot ever produce the usual three-unit anchor.
    // Require its whole reference; never anchor a single-unit selection.
    final requiredAnchor = reference.length == 2 && anchorLength == 3
        ? 2
        : anchorLength;
    if (_pending.length < requiredAnchor) return;
    final lower = next ?? 0;
    final upper = next == null
        ? reference.length
        : (next + maxForwardSkip + anchorLength).clamp(0, reference.length);
    for (var length = _pending.length; length >= requiredAnchor; length--) {
      int? candidate;
      var ambiguous = false;
      for (var start = lower; start + length <= upper; start++) {
        var match = true;
        for (var j = 0; j < length; j++) {
          if (reference[start + j].tokenId !=
              _pending[_pending.length - length + j]) {
            match = false;
            break;
          }
        }
        if (match) {
          if (candidate != null) {
            ambiguous = true;
            break;
          }
          candidate = start;
        }
      }
      if (candidate != null && !ambiguous) {
        for (var j = 0; j < length; j++) {
          _matched.add(candidate + j);
        }
        _next = candidate + length;
        _pending.clear();
        return;
      }
      // A longer ambiguous match must not be broken by a shorter coincidence.
      if (ambiguous) return;
    }
  }
}
