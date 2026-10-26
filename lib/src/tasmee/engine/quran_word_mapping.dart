/// إسناد وحدات الآية إلى كلماتها العثمانية — منطق نقي (بلا Flutter)
/// ليُستخدم وقت التشغيل ولتوليد أصل الإسناد مسبقًا
/// (`tool/generate_unit_word_map.dart`).
library;

import 'quran_units.dart';

/// حروف الكلمة العثمانية المطابقة وحدويًا: بلا حركات ولا علامات قرآنية،
/// والشدة تُضاعف الحرف (تُقابل وحدة الشدة بوزن 2). المطابقة موضعية —
/// لا مقارنة هوية حروف؛ حفظُ الإجمالي وحده يفصل المسارات.
List<String> uthmaniWordLetters(String word) {
  const marks = '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0653'
      '\u0654\u0655\u0656\u0657\u0658\u0670\u06D6\u06D7\u06D8'
      '\u06D9\u06DA\u06DB\u06DC\u06DD\u06DE\u06DF\u06E0\u06E1'
      '\u06E2\u06E3\u06E4\u06E5\u06E6\u06E7\u06E8\u06E9\u06EA'
      '\u06EB\u06EC\u06ED\u0640';
  final out = <String>[];
  for (final r in word.runes) {
    final ch = String.fromCharCode(r);
    if (ch == '\u0651') {
      // شدة: ضاعف الحرف السابق.
      if (out.isNotEmpty) out.add(out.last);
    } else if (!marks.contains(ch) &&
        RegExp(r'\p{L}', unicode: true).hasMatch(ch)) {
      out.add(ch);
    }
  }
  return out;
}

/// يسند كل وحدة إلى فهرس كلمتها **العثمانية** — الفونيمات تختلف عن
/// العثماني في ثلثي المصحف (كلمة فونيمية تدمج «هُدًى لِّلْمُتَّقِينَ»)،
/// وأي خلط بين الفهرستين يُسقط كلمات من التتبّع كليًا فلا تظهر في
/// التسميع (وتتركز في نهايات الآيات حيث تُدمج المدود باللامات).
///
/// ثلاثة مسارات تصاعديّة الأمان:
/// 1. تطابق عدد الكلمات الفونيمية مع العثمانية → مطابقة فهرسية.
/// 2. مشي موضعي بالأوزان (وحدة الشدة = 2، وما عداها = 1) عبر حدود
///    الكلمات — يُعتمد إن حافظ على الإجمالي وغطّى كل كلمة ذات حروف.
/// 3. محاذاة شاملة [alignUnitsToUthmaniWords] — كان احتياطًا نسبيًّا
///    أعمى (آيات تُهجّى حروفها فيختل الحفظ) يوزّع الوحدات بلا نظر
///    لطول الكلمات فيخطئ ثلاثة أرباع وحدات المصحف.
List<int> mapUnitsToUthmaniWords({
  required List<QuranUnit> units,
  required List<int> phonemeIdx,
  required List<String> uthmaniWords,
}) {
  final wordCount = uthmaniWords.length;
  if (units.isEmpty || wordCount == 0) return const [];
  final phonemeCount = phonemeIdx.toSet().length;
  if (phonemeCount == wordCount) return phonemeIdx;

  // حدود الكلمات بحروفها المطبَّعة.
  final boundaries = List<int>.filled(wordCount + 1, 0);
  for (var w = 0; w < wordCount; w++) {
    boundaries[w + 1] =
        boundaries[w] + uthmaniWordLetters(uthmaniWords[w]).length;
  }
  final totalLetters = boundaries[wordCount];
  var totalWeight = 0;
  for (final u in units) {
    totalWeight += u.isShadda ? 2 : 1;
  }
  if (totalWeight == totalLetters) {
    final result = List<int>.filled(units.length, 0);
    var pos = 0;
    var word = 0;
    for (var i = 0; i < units.length; i++) {
      while (word + 1 < wordCount && pos >= boundaries[word + 1]) {
        word++;
      }
      result[i] = word;
      pos += units[i].isShadda ? 2 : 1;
    }
    // كل كلمة ذات حروف يجب أن تُغطّى.
    final covered = List<bool>.filled(wordCount, false);
    for (final w in result) {
      covered[w] = true;
    }
    var allCovered = true;
    for (var w = 0; w < wordCount; w++) {
      if (boundaries[w + 1] > boundaries[w] && !covered[w]) {
        allCovered = false;
        break;
      }
    }
    if (allCovered) return result;
  }

  // محاذاة شاملة — المسار 3.
  return alignUnitsToUthmaniWords(
    units: units,
    uthmaniWords: uthmaniWords,
  );
}

/// وحدات كثيرًا ما تُدرجها الملاحن (إدغام/وصل) بلا حرف متوقع مقابل.
const String _kFlexUnitLetters = 'اويۥۦنء';

/// تطبيع حرف عثماني إلى حرف الوحدة المقابل (الوحدات بلا همزات حمل
/// ولا ألف مقصورة).
String _normalizeUthmaniLetter(String ch) {
  if (ch == 'ٱ' || ch == 'آ') return 'ا';
  if ('أإؤئء'.contains(ch)) return 'ء';
  if (ch == 'ى' || ch == 'ی') return 'ي';
  if (ch == 'ة') return 'ت';
  if (ch == 'ڈ') return 'د';
  return ch;
}

/// الحروف الفونيتية **المتوقعة** لكلمة عثمانية (مسندة باختيارية/إلزام):
/// - الشدة تكرر الحرف السابق (الوحدة المضاعفة تقابل حرفين).
/// - التنوين يضيف نونًا اختيارية (تُقرأ وصلًا وتسقط وقفًا).
/// - الألف الخنجرية تضيف ألفًا اختيارية، وۥ/ۦ نفسيهما اختياريين.
/// - الألف والواو والياء واللام وٱ (همزة وصل) اختيارية: قد تسقط أو
///   تُدغم في الوصل فلا تقابلها وحدة.
List<({String letter, bool optional})> expectedUthmaniLetters(String word) {
  const marks = '\u064B\u064C\u064D\u064E\u064F\u0650\u0652'
      '\u0653\u0654\u0655\u0656\u0657\u0658\u06D6\u06D7\u06D8'
      '\u06D9\u06DA\u06DB\u06DC\u06DD\u06DE\u06DF\u06E0\u06E1'
      '\u06E2\u06E3\u06E4\u06E7\u06E8\u06E9\u06EA\u06EB\u06EC'
      '\u06ED\u0640';
  final out = <({String letter, bool optional})>[];
  for (final r in word.runes) {
    final ch = String.fromCharCode(r);
    if (ch == '\u0651') {
      if (out.isNotEmpty) {
        out.add((letter: out.last.letter, optional: true));
      }
    } else if ('\u064B\u064C\u064D'.contains(ch)) {
      out.add((letter: 'ن', optional: true));
    } else if (ch == '\u0670') {
      out.add((letter: 'ا', optional: true));
    } else if (ch == '\u06E5') {
      out.add((letter: 'ۥ', optional: true));
    } else if (ch == '\u06E6') {
      out.add((letter: 'ۦ', optional: true));
    } else if (marks.contains(ch)) {
      continue;
    } else if (RegExp(r'\p{L}', unicode: true).hasMatch(ch)) {
      final optional = ch == 'ٱ' || 'اوي'.contains(ch) || ch == 'ل';
      out.add((letter: _normalizeUthmaniLetter(ch), optional: optional));
    }
  }
  return out;
}

/// محاذاة شاملة (برمجة ديناميكية) تسند كل وحدة إلى فهرس كلمتها
/// العثمانية — المسار الأخير في [mapUnitsToUthmaniWords].
///
/// تحاذي الحروف المتوقعة ([expectedUthmaniLetters]) مع وحدات الآية:
/// كلفة تطابق الحرف 0، وحدة مرنة أو حرف اختياري 1، وإلا 3. الرجوع
/// للخلف يُسند كل وحدة للكلمة التي طابقت حرفها، وما لم يطابق يُلحق
/// بالكلمة السابقة (أو التالية إن لم توجد)، ثم تُفرض الرتابة.
///
/// الدقة المقيسة على آيات المعيار (تطابق عدد الكلمات الفونيمية مع
/// العثمانية): ≥99% على مستوى الوحدات مقابل ~27% للتوزيع النسبي
/// السابق.
List<int> alignUnitsToUthmaniWords({
  required List<QuranUnit> units,
  required List<String> uthmaniWords,
}) {
  final n = units.length;
  final wordCount = uthmaniWords.length;
  if (n == 0 || wordCount == 0) return const [];
  final exp = <({String letter, bool optional})>[];
  final expWord = <int>[];
  for (var w = 0; w < wordCount; w++) {
    for (final l in expectedUthmaniLetters(uthmaniWords[w])) {
      exp.add(l);
      expWord.add(w);
    }
  }
  final m = exp.length;
  const inf = 1 << 28;
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, inf));
  // 0 قطري (وحدة↔حرف)، 1 وحدة بلا متوقع، 2 متوقع بلا وحدة.
  final bk = List.generate(n + 1, (_) => List<int>.filled(m + 1, -1));
  dp[0][0] = 0;
  for (var i = 0; i <= n; i++) {
    for (var j = 0; j <= m; j++) {
      final c = dp[i][j];
      if (c >= inf) continue;
      if (i < n && j < m) {
        final cost = units[i].letter == exp[j].letter ? 0 : 3;
        if (c + cost < dp[i + 1][j + 1]) {
          dp[i + 1][j + 1] = c + cost;
          bk[i + 1][j + 1] = 0;
        }
      }
      if (i < n) {
        final cost = _kFlexUnitLetters.contains(units[i].letter) ? 1 : 3;
        if (c + cost < dp[i + 1][j]) {
          dp[i + 1][j] = c + cost;
          bk[i + 1][j] = 1;
        }
      }
      if (j < m) {
        final cost = exp[j].optional ? 1 : 3;
        if (c + cost < dp[i][j + 1]) {
          dp[i][j + 1] = c + cost;
          bk[i][j + 1] = 2;
        }
      }
    }
  }
  // رجوع للخلف من (n, m).
  final assign = List<int?>.filled(n, null);
  var i = n;
  var j = m;
  while (i != 0 || j != 0) {
    final how = bk[i][j];
    if (how == -1) break; // غير قابل للوصول نظريًّا.
    if (how == 0) {
      assign[i - 1] = expWord[j - 1];
      i--;
      j--;
    } else if (how == 1) {
      i--;
    } else {
      j--;
    }
  }
  // غير المطابق يُلحق بالكلمة السابقة، والبادئة الرائدة بالتالية.
  var last = -1;
  for (var k = 0; k < n; k++) {
    if (assign[k] != null) {
      last = assign[k]!;
    } else if (last >= 0) {
      assign[k] = last;
    }
  }
  var next = -1;
  for (var k = n - 1; k >= 0; k--) {
    if (assign[k] != null) {
      next = assign[k]!;
    } else if (next >= 0) {
      assign[k] = next;
    }
  }
  final result = List<int>.generate(n, (k) => assign[k] ?? 0);
  for (var k = 1; k < n; k++) {
    if (result[k] < result[k - 1]) result[k] = result[k - 1];
  }
  // إصلاح التغطية: كلمة ذات حروف بلا أي وحدة (إدغام وصلٍ حادّ مثل
  // «لَا ٱلشَّمْسُ» في 36:40 حيث تخدم اللامُ الواحدة الكلمتين) تستعير
  // وحدة الحدّ من جارتها — الكلمة بلا وحدات تسقط من التتبّع كليًا
  // فلا تظهر في التسميع ولا تقبل إعادة النطق.
  final counts = List<int>.filled(wordCount, 0);
  for (final w in result) {
    counts[w]++;
  }
  for (var w = 0; w < wordCount; w++) {
    if (counts[w] > 0 || expectedUthmaniLetters(uthmaniWords[w]).isEmpty) {
      continue;
    }
    var donor = -1;
    if (w + 1 < wordCount && counts[w + 1] > 1) {
      for (var k = 0; k < n; k++) {
        if (result[k] == w + 1) {
          donor = k;
          break;
        }
      }
    }
    if (donor < 0 && w > 0 && counts[w - 1] > 1) {
      for (var k = n - 1; k >= 0; k--) {
        if (result[k] == w - 1) {
          donor = k;
          break;
        }
      }
    }
    if (donor < 0) continue;
    counts[result[donor]]--;
    counts[w]++;
    result[donor] = w;
  }
  return result;
}
