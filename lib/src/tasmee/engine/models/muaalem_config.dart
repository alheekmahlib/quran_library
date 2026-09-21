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
}
