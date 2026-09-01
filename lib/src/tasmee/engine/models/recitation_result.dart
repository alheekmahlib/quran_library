/// نتيجة تصحيح تلاوة من خادم quran-muaalem.
///
/// Recitation correction result from the quran-muaalem server.
///
/// البنية مطابقة لِاستجابة `/correct-recitation` من quran-muaalem. الخادم
/// يحوّل الصوت إلى فونيمات، يبحث عن أفضل تطابق في القرآن، ثم يُحدّد الأخطاء.
///
/// Structure matches the `/correct-recitation` response from quran-muaalem.
class RecitationResult {
  const RecitationResult({
    this.start,
    this.end,
    this.predictedPhonemes,
    this.referencePhonemes,
    this.uthmaniText,
    this.errors = const [],
    this.noMatchMessage,
  });

  /// موضع بداية التطابق في المصحف (سورة، آية، كلمة، حرف).
  /// Start position of the match in the moshaf.
  final SurahAyahPosition? start;

  /// موضع نهاية التطابق.
  /// End position of the match.
  final SurahAyahPosition? end;

  /// الفونيمات التي نطقها المستخدم فعلاً (Phonetic Script).
  /// Phonemes actually recited by the user.
  final String? predictedPhonemes;

  /// الفونيمات المرجعية الصحيحة.
  /// Correct reference phonemes.
  final String? referencePhonemes;

  /// النص العثماني للآية المُطابَقة.
  /// Uthmani text of the matched verse.
  final String? uthmaniText;

  /// أخطاء التجويد والنطق.
  /// Tajweed and pronunciation errors.
  final List<RecitationError> errors;

  /// رسالة إن لم يُعثر على تطابق (HTTP 404).
  /// Message when no match found (HTTP 404).
  final String? noMatchMessage;

  /// هل وُجد تطابق في القرآن؟
  /// Was a match found in the Quran?
  bool get hasMatch => noMatchMessage == null && uthmaniText != null;

  /// هل التلاوة صحيحة تماماً (لا أخطاء)؟
  /// Is the recitation fully correct (no errors)?
  bool get isFullyCorrect => hasMatch && errors.isEmpty;

  /// أخطاء التجويد فقط.
  /// Tajweed errors only.
  List<RecitationError> get tajweedErrors =>
      errors.where((e) => e.errorType == 'tajweed').toList();

  /// الأخطاء العادية (نطق كلمة خاطئة).
  /// Normal errors (wrong word pronunciation).
  List<RecitationError> get normalErrors =>
      errors.where((e) => e.errorType == 'normal').toList();

  /// أخطاء التشكيل.
  /// Tashkeel errors.
  List<RecitationError> get tashkeelErrors =>
      errors.where((e) => e.errorType == 'tashkeel').toList();

  factory RecitationResult.fromJson(Map<String, dynamic> json) {
    final uthmani = json['uthmani_text'] as String?;
    return RecitationResult(
      start: json['start'] != null
          ? SurahAyahPosition.fromJson(
              Map<String, dynamic>.from(json['start'] as Map))
          : null,
      end: json['end'] != null
          ? SurahAyahPosition.fromJson(
              Map<String, dynamic>.from(json['end'] as Map))
          : null,
      predictedPhonemes: json['predicted_phonemes'] as String?,
      referencePhonemes: json['reference_phonemes'] as String?,
      uthmaniText: uthmani,
      noMatchMessage: json['message'] as String?,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => RecitationError.fromJson(
                    Map<String, dynamic>.from(e as Map),
                    uthmaniText: uthmani,
                  ))
              .toList() ??
          const [],
    );
  }

  @override
  String toString() =>
      'RecitationResult(match: ${start?.suraIdx}:${start?.ayaIdx}, '
      'errors: ${errors.length}, fullyCorrect: $isFullyCorrect)';
}

/// خطأ واحد في التلاوة.
///
/// A single recitation error.
class RecitationError {
  const RecitationError({
    required this.errorType,
    required this.speechErrorType,
    this.uthmaniPos = const [0, 0],
    this.phPos = const [0, 0],
    this.expectedPh,
    this.predictedPh,
    this.expectedLen,
    this.predictedLen,
    this.wordText,
    this.refTajweedRules = const [],
    this.insertedTajweedRules = const [],
    this.replacedTajweedRules = const [],
    this.missingTajweedRules = const [],
  });

  /// نوع الخطأ: 'tajweed' أو 'normal' أو 'tashkeel'.
  /// Error type: 'tajweed', 'normal', or 'tashkeel'.
  final String errorType;

  /// نوع خطأ النطق: 'insert' (زيادة) أو 'delete' (نقص) أو 'replace' (استبدال).
  /// Speech error: 'insert', 'delete', or 'replace'.
  final String speechErrorType;

  /// الموضع في النص العثماني [start, end].
  /// Position in Uthmani text [start, end].
  final List<int> uthmaniPos;

  /// الموضع في الفونيمات [start, end].
  /// Position in phonemes [start, end].
  final List<int> phPos;

  /// الفونيمات المتوقَّعة الصحيحة.
  /// Expected (correct) phonemes.
  final String? expectedPh;

  /// الفونيمات التي نطقها المستخدم فعلاً.
  ///
  /// ملاحظة: المفتاح في استجابة quran-muaalem هو 'preditected_ph' (typo
  /// في الكود الأصلي)، لكنّنا نُطبّعه هنا إلى predictedPh.
  ///
  /// Phonemes actually recited. Note: the key in quran-muaalem's response is
  /// 'preditected_ph' (typo in original), normalized here to predictedPh.
  final String? predictedPh;

  /// الطول المتوقَّع (عدد الحركات لِلمدود).
  /// Expected length (harakat count for madds).
  final int? expectedLen;

  /// الطول الفعلي الذي نطقه المستخدم.
  /// Actual length recited by the user.
  final int? predictedLen;

  /// الكلمة القرآنية المتأثّرة بِهذا الخطأ (مثل "ٱلرَّحْمَٰنِ").
  ///
  /// يُملأ من الخادم بِاستخراج الكلمة من [RecitationResult.uthmaniText] عند
  /// موضع [uthmaniPos]. في الوضع offline يُقدَّر نسبيّاً من `referenceText`.
  /// null يعني أنّ الكلمة غير معروفة (لا يُعرض شيء).
  ///
  /// The Quranic word affected by this error (e.g. "ٱلرَّحْمَٰنِ"). Populated by
  /// the server by extracting the word from [RecitationResult.uthmaniText] at
  /// [uthmaniPos]. In offline mode it's estimated relatively from
  /// `referenceText`. null means unknown (nothing shown).
  final String? wordText;

  /// قواعد التجويد المرجعية المُطبَّقة على هذا الموضع.
  /// Reference tajweed rules applied at this position.
  final List<TajweedRule> refTajweedRules;

  /// قواعد التجويد الزائدة (أضافها المستخدم بدون داعٍ).
  /// Extra tajweed rules (incorrectly added by the user).
  final List<TajweedRule> insertedTajweedRules;

  /// قواعد التجويد المُستبدَلة (طبّق القاعدة الخطأ).
  /// Replaced tajweed rules (wrong rule applied).
  final List<TajweedRule> replacedTajweedRules;

  /// قواعد التجويد المفقودة (لم يُطبّقها).
  /// Missing tajweed rules (not applied).
  final List<TajweedRule> missingTajweedRules;

  /// وصف مختصر لِلخطأ بِالعربية واضح وَمفهوم (مثل الخادم).
  ///
  /// لا يُظهر قيمَين إنجليزيّة خام (insert/delete/replace) أبداً —
  /// بل يُترجمها لِعربية واضحة بِناءً على نوع الخطأ + القاعدة.
  ///
  /// Clear, reader-friendly Arabic description (server-style). Never shows
  /// raw English enum values; translates them based on type + rule.
  String get description {
    // اجمع كلّ القواعد المُتاحة.
    // Gather all available rules.
    final allRules = [
      ...refTajweedRules,
      ...insertedTajweedRules,
      ...replacedTajweedRules,
      ...missingTajweedRules,
    ];
    final ruleName = allRules.isNotEmpty ? allRules.first.nameAr : null;

    // فعل الخطأ بِالعربية حسب نوع الكلام (insert/delete/replace).
    // Arabic verb for the error based on speech_error_type.
    final verb = switch (speechErrorType) {
      'insert' => 'زائد',
      'delete' => 'مفقود',
      'replace' => 'استبدال',
      _ => speechErrorType,
    };

    // 1) أخطاء التجويد (tajweed): اعرض القاعدة + الأطوال (إن كانت مدوداً).
    // Tajweed errors: show rule name + lengths (for madds).
    if (errorType == 'tajweed') {
      if (ruleName != null) {
        // مدّ: اعرض الطول المتوقَّع vs الفعلي.
        // Madd: show expected vs actual length.
        if (expectedLen != null && predictedLen != null) {
          return '$ruleName: المتوقع $expectedLen، الفعلي $predictedLen';
        }
        // قاعدة بِلا أطوال: قل "زائد/مفقود: <القاعدة>" أو "<القاعدة>".
        // Rule without lengths: "extra/missing: <rule>" or just "<rule>".
        if (speechErrorType == 'replace') return ruleName;
        return '$verb: $ruleName';
      }
      // tajweed بِلا قاعدة (نادر): استخدم فعل الخطأ.
      // Tajweed without a rule (rare): fall back to the verb.
      return 'خطأ تجويد ($verb)';
    }

    // 2) أخطاء التشكيل (tashkeel): "تشكيل <زائد/مفقود>".
    // Tashkeel errors: "haraka <extra/missing>".
    if (errorType == 'tashkeel') {
      return 'تشكيل $verb';
    }

    // 3) أخطاء النطق (normal): "حرف <زائد/مفقود>" أو "نطق خاطئ".
    // Normal errors: "letter <extra/missing>" or "wrong pronunciation".
    return switch (speechErrorType) {
      'insert' => 'حرف زائد',
      'delete' => 'حرف مفقود',
      _ => 'نطق خاطئ',
    };
  }

  factory RecitationError.fromJson(
    Map<String, dynamic> j, {
    String? uthmaniText,
  }) {
    final uthmaniPos = (j['uthmani_pos'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const [0, 0];
    return RecitationError(
      errorType: (j['error_type'] as String?) ?? 'normal',
      speechErrorType: (j['speech_error_type'] as String?) ?? 'replace',
      uthmaniPos: uthmaniPos,
      phPos: (j['ph_pos'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [0, 0],
      expectedPh: j['expected_ph'] as String?,
      // ملاحظة: المفتاح في quran-muaalem يحوي typo متعمّد.
      predictedPh: (j['preditected_ph'] ?? j['predicted_ph']) as String?,
      expectedLen: (j['expected_len'] as num?)?.toInt(),
      predictedLen: (j['predicted_len'] as num?)?.toInt(),
      // استخرج الكلمة المتأثّرة من النصّ العثماني عند موضع الخطأ.
      wordText: uthmaniText != null
          ? _extractWordFromUthmani(uthmaniText, uthmaniPos)
          : null,
      refTajweedRules: _parseRules(j['ref_tajweed_rules']),
      insertedTajweedRules: _parseRules(j['inserted_tajweed_rules']),
      replacedTajweedRules: _parseRules(j['replaced_tajweed_rules']),
      missingTajweedRules: _parseRules(j['missing_tajweed_rules']),
    );
  }

  /// يستخرج الكلمة العثمانية المحيطة بِموضع حرفي.
  ///
  /// [uthmani] النصّ العثماني الكامل.
  /// [pos] موضع [بداية، نهاية] كَـ فهارس حرفية في النصّ.
  /// يُعيد الكلمة المحيطة (بين فراغَين) أو null إن فشل.
  ///
  /// Extracts the Uthmani word surrounding a character position.
  static String? _extractWordFromUthmani(String uthmani, List<int> pos) {
    if (pos.length < 2 || uthmani.isEmpty) return null;
    final start = pos[0].clamp(0, uthmani.length).toInt();
    final end = pos[1].clamp(start, uthmani.length).toInt();
    // وسّع لِتشمل الكلمة كاملةً (إلى الفراغات المحيطة).
    int wordStart = start;
    while (wordStart > 0 && !_isUthmaniSeparator(uthmani[wordStart - 1])) {
      wordStart--;
    }
    int wordEnd = end;
    while (wordEnd < uthmani.length && !_isUthmaniSeparator(uthmani[wordEnd])) {
      wordEnd++;
    }
    final word = uthmani.substring(wordStart, wordEnd).trim();
    return word.isEmpty ? null : word;
  }

  /// هل الحرف فاصل كلمات (فراغ أو شرطة Tatweel)?
  static bool _isUthmaniSeparator(String ch) {
    return ch == ' ' || ch == '\u0640'; // فراغ أو كشيدة (Tatweel).
  }

  static List<TajweedRule> _parseRules(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<Map>()
        .map((m) => TajweedRule.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  String toString() => 'RecitationError($errorType/$speechErrorType: '
      '${refTajweedRules.map((r) => r.nameAr).join(", ")}'
      '${wordText != null ? " في \"$wordText\"" : ""})';
}

/// قاعدة تجويد مُطبَّقة على موضع معيّن.
///
/// A tajweed rule applied at a specific position.
class TajweedRule {
  const TajweedRule({
    required this.nameAr,
    required this.nameEn,
    this.goldenLen,
    this.correctnessType,
    this.tag,
  });

  /// اسم القاعدة بِالعربية (مثل "المد اللازم").
  /// Rule name in Arabic (e.g. "Lazem Madd" → "المد اللازم").
  final String nameAr;

  /// اسم القاعدة بِالإنجليزية.
  /// Rule name in English.
  final String nameEn;

  /// الطول الذهبي المتوقَّع (عدد الحركات) إن وُجد.
  /// Expected golden length (harakat count) if applicable.
  final int? goldenLen;

  /// نوع التحقّق: 'count' (عدد حركات) أو 'sifa' (صفة حرف).
  /// Verification type: 'count' (harakat) or 'sifa' (letter attribute).
  final String? correctnessType;

  /// وسم إضافي (مثل 'alif', 'waw', 'yaa' لِنوع حرف المدّ).
  /// Extra tag (e.g. 'alif', 'waw', 'yaa' for madd letter type).
  final String? tag;

  factory TajweedRule.fromJson(Map<String, dynamic> j) {
    final name = j['name'];
    String ar = '', en = '';
    if (name is Map) {
      ar = (name['ar'] as String?) ?? '';
      en = (name['en'] as String?) ?? '';
    }
    return TajweedRule(
      nameAr: ar,
      nameEn: en,
      goldenLen: (j['golden_len'] as num?)?.toInt(),
      correctnessType: j['correctness_type'] as String?,
      tag: j['tag'] as String?,
    );
  }

  @override
  String toString() => nameAr.isNotEmpty ? nameAr : nameEn;
}

/// موضع في المصحف (سورة، آية، كلمة، حرف).
///
/// A position in the moshaf (surah, ayah, word, character).
class SurahAyahPosition {
  const SurahAyahPosition({
    required this.suraIdx,
    required this.ayaIdx,
    this.uthmaniWordIdx = 0,
    this.uthmaniCharIdx = 0,
    this.phonemesIdx = 0,
  });

  /// رقم السورة (1-based).
  /// Surah number (1-based).
  final int suraIdx;

  /// رقم الآية (1-based).
  /// Ayah number (1-based).
  final int ayaIdx;

  /// رقم الكلمة العثمانية (0-based).
  /// Uthmani word index (0-based).
  final int uthmaniWordIdx;

  /// رقم الحرف العثماني (0-based).
  /// Uthmani character index (0-based).
  final int uthmaniCharIdx;

  /// رقم الفونيم (0-based).
  /// Phoneme index (0-based).
  final int phonemesIdx;

  factory SurahAyahPosition.fromJson(Map<String, dynamic> j) =>
      SurahAyahPosition(
        suraIdx: (j['sura_idx'] as num?)?.toInt() ?? 1,
        ayaIdx: (j['aya_idx'] as num?)?.toInt() ?? 1,
        uthmaniWordIdx: (j['uthmani_word_idx'] as num?)?.toInt() ?? 0,
        uthmaniCharIdx: (j['uthmani_char_idx'] as num?)?.toInt() ?? 0,
        phonemesIdx: (j['phonemes_idx'] as num?)?.toInt() ?? 0,
      );

  @override
  String toString() => '$suraIdx:$ayaIdx';
}
