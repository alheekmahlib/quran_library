import 'tasmee_tolerance.dart';

/// V4's own evidence presets. They are not Zipformer retry thresholds.
/// Feedback remains experimental regardless of the selected preset.
enum TajweedFormerFeedbackPreset { strict, balanced, sensitive }

/// إعدادات المصحف لِخادم quran-muaalem.
///
/// Moshaf attributes for the quran-muaalem server.
///
/// القيم الافتراضية مطابقة لِرواية حفص (Hafs). تُمرَّر كحقول form data في
/// طلب `/correct-recitation`. عدّلها فقط إن كان المصحف الهدف يختلف.
///
/// Defaults match Hafs riwayah. Passed as form fields in the
/// `/correct-recitation` request. Change only if the target moshaf differs.
class MuaalemConfig {
  const MuaalemConfig({
    this.rewaya = 'hafs',
    this.tajweedFormerPreset = TajweedFormerFeedbackPreset.balanced,
    this.tajweedFormerTolerance,
    this.recitationSpeed = 'murattal',
    this.maddMonfaselLen = 4,
    this.maddMottaselLen = 4,
    this.maddAaredLen = 4,
    this.maddLazemLen = 6,
    this.maddLeenLen = 2,
    this.takbeer = 'no_takbeer',
    this.ghonnaLamAndRaa = 'no_ghonna',
    this.ghonnaNaqis = 'no_ghonna',
    this.sakenBeforeHamz = 'tahqeek',
    this.medOomMadd = 'talith',
    this.dtaah = 'no_idgham',
    this.dghnmkhfaa = 'no_idgham',
    this.naqlHamzatWassel = 'no',
    this.isbaal = 'no',
    this.bslamYaa = 'no',
    this.maddMottaselSukoonLen = 2,
    this.naskhStyle = 'no_naskh',
    this.haaPronunciation = 'no_tahfif',
    this.tafkheemLetters = 'tafkheem',
    this.istitala = 'tafweem',
    this.tafashie = 'shidda',
    this.safeer = 'shidda',
    this.qalqla = 'qalqla_kubra',
    this.ghonna = 'no_ghonna',
    this.tikraar = 'no_tikraar',
    this.hamsOrJahr = 'jahr',
    this.shiddaOrRakhawa = 'shidda',
    this.tafkheemOrTaqeeq = 'tafkheem',
    this.itbaq = 'no_itbaq',
  });

  /// رواية المصحف (hafs أو warsh أو qalon...).
  final String rewaya;

  /// Model-specific evidence preset for V4's diagnostic candidates.
  /// Not sent to the quran-muaalem server and not a correctness guarantee.
  final TajweedFormerFeedbackPreset tajweedFormerPreset;

  /// Optional independent V4 diagnostics; null preserves the legacy preset.
  final TasmeeToleranceProfile? tajweedFormerTolerance;

  /// سرعة التلاوة (murattal أو mujawwad).
  final String recitationSpeed;

  /// طول المدّ المنفصل (2-5 حركات).
  final int maddMonfaselLen;

  /// طول المدّ المتّصل (2-6 حركات).
  final int maddMottaselLen;

  /// طول المدّ العارض للسكون (2-6 حركات).
  final int maddAaredLen;

  /// طول المدّ اللازم (default 6).
  final int maddLazemLen;

  /// طول مدّ اللين (default 2).
  final int maddLeenLen;

  /// تكبيرة الإحرام (no_takbeer أو takbeer).
  final String takbeer;

  /// غُنّة اللام والراء (no_ghonna أو ghonna).
  final String ghonnaLamAndRaa;

  /// غُنّة الناقص (no_ghonna أو ghonna).
  final String ghonnaNaqis;

  /// الساكن قبل الهمزة (tahqeek أو tashil).
  final String sakenBeforeHamz;

  /// مدّ جمع (talith أو more).
  final String medOomMadd;

  /// بقية الإعدادات المتقدّمة (defaults = Hafs standard).
  final String dtaah;
  final String dghnmkhfaa;
  final String naqlHamzatWassel;
  final String isbaal;
  final String bslamYaa;
  final int maddMottaselSukoonLen;
  final String naskhStyle;
  final String haaPronunciation;
  final String tafkheemLetters;
  final String istitala;
  final String tafashie;
  final String safeer;
  final String qalqla;
  final String ghonna;
  final String tikraar;
  final String hamsOrJahr;
  final String shiddaOrRakhawa;
  final String tafkheemOrTaqeeq;
  final String itbaq;

  /// حوّل الإعدادات إلى حقول form-data لِطلب HTTP.
  /// Convert to form-data fields for the HTTP request.
  Map<String, String> toFormFields() => {
        'rewaya': rewaya,
        'recitation_speed': recitationSpeed,
        'madd_monfasel_len': maddMonfaselLen.toString(),
        'madd_mottasel_len': maddMottaselLen.toString(),
        'madd_aared_len': maddAaredLen.toString(),
        'madd_lazem_len': maddLazemLen.toString(),
        'madd_leen_len': maddLeenLen.toString(),
        'takbeer': takbeer,
        'ghonna_lam_and_raa': ghonnaLamAndRaa,
        'ghonna_naqis': ghonnaNaqis,
        'saken_before_hamz': sakenBeforeHamz,
        'med_oom_madd': medOomMadd,
        'dtaah': dtaah,
        'dghnmkhfaa': dghnmkhfaa,
        'naql_hamzat_wassel': naqlHamzatWassel,
        'isbaal': isbaal,
        'bslam_yaa': bslamYaa,
        'madd_mottasel_sukoon_len': maddMottaselSukoonLen.toString(),
        'naskh_style': naskhStyle,
        'haa_pronunciation': haaPronunciation,
        'tafkheem_letters': tafkheemLetters,
        'istitala': istitala,
        'tafashie': tafashie,
        'safeer': safeer,
        'qalqla': qalqla,
        'ghonna': ghonna,
        'tikraar': tikraar,
        'hams_or_jahr': hamsOrJahr,
        'shidda_or_rakhawa': shiddaOrRakhawa,
        'tafkheem_or_taqeeq': tafkheemOrTaqeeq,
        'itbaq': itbaq,
      };

  @override
  String toString() =>
      'MuaalemConfig(rewaya: $rewaya, speed: $recitationSpeed)';

  /// إعدادات القيم فوق الافتراضي الحفصي التي لا يقيّمها TajweedFormer V4.
  ///
  /// Names of the recitation settings this config carries beyond the Hafs
  /// defaults that TajweedFormer V4 does not assess. V4 reads only
  /// [rewaya] (Hafs only, rejected separately) and [tajweedFormerPreset];
  /// every other field belongs to the server/Zipformer paths. Returning a
  /// non-empty list is an explicit "unsupported", not a silent ignore: the
  /// V4 session refuses to record with such settings instead of pretending
  /// they were honored.
  List<String> unsupportedTajweedFormerSettings() => [
        if (recitationSpeed != 'murattal') 'recitationSpeed',
        if (maddMonfaselLen != 4) 'maddMonfaselLen',
        if (maddMottaselLen != 4) 'maddMottaselLen',
        if (maddAaredLen != 4) 'maddAaredLen',
        if (maddLazemLen != 6) 'maddLazemLen',
        if (maddLeenLen != 2) 'maddLeenLen',
        if (takbeer != 'no_takbeer') 'takbeer',
        if (ghonnaLamAndRaa != 'no_ghonna') 'ghonnaLamAndRaa',
        if (ghonnaNaqis != 'no_ghonna') 'ghonnaNaqis',
        if (sakenBeforeHamz != 'tahqeek') 'sakenBeforeHamz',
        if (medOomMadd != 'talith') 'medOomMadd',
        if (dtaah != 'no_idgham') 'dtaah',
        if (dghnmkhfaa != 'no_idgham') 'dghnmkhfaa',
        if (naqlHamzatWassel != 'no') 'naqlHamzatWassel',
        if (isbaal != 'no') 'isbaal',
        if (bslamYaa != 'no') 'bslamYaa',
        if (maddMottaselSukoonLen != 2) 'maddMottaselSukoonLen',
        if (naskhStyle != 'no_naskh') 'naskhStyle',
        if (haaPronunciation != 'no_tahfif') 'haaPronunciation',
        if (tafkheemLetters != 'tafkheem') 'tafkheemLetters',
        if (istitala != 'tafweem') 'istitala',
        if (tafashie != 'shidda') 'tafashie',
        if (safeer != 'shidda') 'safeer',
        if (qalqla != 'qalqla_kubra') 'qalqla',
        if (ghonna != 'no_ghonna') 'ghonna',
        if (tikraar != 'no_tikraar') 'tikraar',
        if (hamsOrJahr != 'jahr') 'hamsOrJahr',
        if (shiddaOrRakhawa != 'shidda') 'shiddaOrRakhawa',
        if (tafkheemOrTaqeeq != 'tafkheem') 'tafkheemOrTaqeeq',
        if (itbaq != 'no_itbaq') 'itbaq',
      ];
}
