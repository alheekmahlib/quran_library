part of '../audio.dart';

class ReadersConstants {
  ReadersConstants._();
  static const ayahs1stSource = "https://cdn.islamic.network/quran/audio/";
  static const ayahs2ndSource = "https://everyayah.com/data/";
  static const surahUrl1 = "https://download.quranicaudio.com/quran/";
  static const surahUrl2 = "https://server16.mp3quran.net/";
  static const surahUrl3 = "https://server12.mp3quran.net/";
  static const surahUrl4 = "https://server6.mp3quran.net/";
  static const surahUrl5 = "https://server11.mp3quran.net/";
  static const surahUrl6 = "https://server8.mp3quran.net/";
  static const surahUrl7 = "https://server14.mp3quran.net/";

  /// قائمة القراء المخصصة (اختيارية) - يمكن للمستخدم تعيينها
  static List<ReaderInfo>? customAyahReaders;
  static List<ReaderInfo>? customSurahReaders;

  /// الحصول على قائمة قراء الآيات (المخصصة أو الافتراضية)
  static List<ReaderInfo> get activeAyahReaders =>
      customAyahReaders ?? ayahReaderInfo;

  /// الحصول على قائمة قراء السور (المخصصة أو الافتراضية)
  static List<ReaderInfo> get activeSurahReaders =>
      customSurahReaders ?? surahReaderInfo;

  static final List<ReaderInfo> ayahReaderInfo = [
    const ReaderInfo(
      index: 0,
      name: 'إبراهيم الأخضر',
      readerNamePath: 'Ibrahim_Akhdar_32kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 1,
      name: 'أبو بكر الشاطري',
      readerNamePath: 'Abu_Bakr_Ash-Shaatree_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 2,
      name: 'أحمد العجمي',
      readerNamePath: '128/ar.ahmedajamy',
      url: ayahs1stSource,
    ),
    const ReaderInfo(
      index: 3,
      name: 'أحمد بن طالب',
      readerNamePath: 'Ahmed_Neana_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 4,
      name: 'أكرم العلاقمي',
      readerNamePath: 'Akram_AlAlaqimy_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 5,
      name: 'خالد الجليل',
      readerNamePath: 'Khaalid_Abdullaah_al-Qahtaanee_192kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 6,
      name: 'سعود الشريم',
      readerNamePath: 'Saood_ash-Shuraym_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 7,
      name: 'سهل ياسين',
      readerNamePath: 'Sahl_Yassin_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 8,
      name: 'صلاح البدير',
      readerNamePath: 'Salah_Al_Budair_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 9,
      name: 'صلاح بو خاطر',
      readerNamePath: 'Salaah_AbdulRahman_Bukhatir_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 10,
      name: 'عبد الباسط',
      readerNamePath: 'Abdul_Basit_Murattal_192kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 11,
      name: 'عبد الباسط - مجود',
      readerNamePath: 'Abdul_Basit_Mujawwad_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 12,
      name: 'عبد الله الجهني',
      readerNamePath: 'Abdullaah_3awwaad_Al-Juhaynee_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 13,
      name: 'عبد الله بصفر',
      readerNamePath: 'Abdullah_Basfar_192kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 14,
      name: 'عبدالرحمن السديس',
      readerNamePath: 'Abdurrahmaan_As-Sudais_192kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 15,
      name: 'عبدالصمد',
      readerNamePath: 'AbdulSamad_64kbps_QuranExplorer.Com',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 16,
      name: 'عبدالله مطرود',
      readerNamePath: 'Abdullah_Matroud_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 17,
      name: 'عزيز عليلي',
      readerNamePath: 'aziz_alili_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 18,
      name: 'علي الحجاج السويسي',
      readerNamePath: 'Ali_Hajjaj_AlSuesy_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 19,
      name: 'علي الحذيفي',
      readerNamePath: 'Hudhaify_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 20,
      name: 'علي جابر',
      readerNamePath: 'Ali_Jaber_64kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 21,
      name: 'فارس عباد',
      readerNamePath: 'Fares_Abbad_64kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 22,
      name: 'ماهر المعيقلي',
      readerNamePath: 'MaherAlMuaiqly128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 23,
      name: 'ماهر المعيقلي - مجود',
      readerNamePath: 'MaherAlMuaiqly128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 24,
      name: 'محمد أيوب',
      readerNamePath: '128/ar.muhammadayyoub',
      url: ayahs1stSource,
    ),
    const ReaderInfo(
      index: 25,
      name: 'محمد المنشاوي',
      readerNamePath: 'Minshawy_Murattal_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 26,
      name: 'محمد جبريل',
      readerNamePath: 'Muhammad_Jibreel_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 27,
      name: 'محمد الطبلاوي',
      readerNamePath: 'Mohammad_al_Tablaway_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 28,
      name: 'محمد عبدالكريم',
      readerNamePath: 'Muhammad_AbdulKareem_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 29,
      name: 'محمود الحصري',
      readerNamePath: 'Husary_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 30,
      name: 'محمود الحصري - مجود',
      readerNamePath: 'Husary_128kbps_Mujawwad',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 31,
      name: 'مشاري العفاسي',
      readerNamePath: 'Alafasy_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 32,
      name: 'ناصر القطامي',
      readerNamePath: 'Nasser_Alqatami_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 33,
      name: 'نبيل الرفاعي',
      readerNamePath: 'Nabil_Rifa3i_48kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 34,
      name: 'هاني الرفاعي',
      readerNamePath: 'Hani_Rifai_192kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 35,
      name: 'ياسر الدوسري - مجود',
      readerNamePath: 'Yasser_Ad-Dussary_128kbps',
      url: ayahs2ndSource,
    ),
    const ReaderInfo(
      index: 36,
      name: 'ياسر سلامة',
      readerNamePath: 'Yaser_Salamah_128kbps',
      url: ayahs2ndSource,
    ),
  ];

  static final List<ReaderInfo> surahReaderInfo = [
    const ReaderInfo(
      index: 0,
      name: 'إبراهيم الأخضر',
      readerNamePath: 'ibrahim_al_akhdar/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 1,
      name: 'إدريس أبكر',
      readerNamePath: 'idrees_akbar/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 2,
      name: 'أبو بكر الشاطري',
      readerNamePath: 'abu_bakr_ash-shaatree/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 3,
      name: 'أحمد الحذيفي',
      readerNamePath: 'ahmad_huth/',
      url: surahUrl6,
    ),
    const ReaderInfo(
      index: 4,
      name: 'أحمد العجمي',
      readerNamePath: 'ahmed_ibn_3ali_al-3ajamy/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 5,
      name: 'أحمد النفيس - مجود',
      readerNamePath: 'nufais/Rewayat-Hafs-A-n-Assem/',
      url: surahUrl2,
    ),
    const ReaderInfo(
      index: 6,
      name: 'إسلام صبحي',
      readerNamePath: 'islam/Rewayat-Hafs-A-n-Assem/',
      url: surahUrl7,
    ),
    const ReaderInfo(
      index: 7,
      name: 'بدر التركي',
      readerNamePath: 'badr_al_turki/mp3/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 8,
      name: 'بندر بليلة',
      readerNamePath: 'bandar_baleela/complete/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 9,
      name: 'خالد الجليل',
      readerNamePath: 'khaalid_al-qahtaanee/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 10,
      name: 'خليفة الطنيجي',
      readerNamePath: 'khalifah_taniji/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 11,
      name: 'رعد محمد الكردي',
      readerNamePath: 'raad_mohammad_al_kurdi/mp3/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 12,
      name: 'سعد الغامدي',
      readerNamePath: 'sa3d_al-ghaamidi/complete/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 13,
      name: 'سعود الشريم',
      readerNamePath: 'sa3ood_al-shuraym/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 14,
      name: 'شيرزاد طاهر',
      readerNamePath: 'taher/',
      url: surahUrl3,
    ),
    const ReaderInfo(
      index: 15,
      name: 'صلاح البدير',
      readerNamePath: 'salahbudair/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 16,
      name: 'عادل الكلباني',
      readerNamePath: 'adel_kalbani/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 17,
      name: 'عبد الباسط',
      readerNamePath: 'abdul_basit_murattal/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 18,
      name: 'عبد الرحمن العوسي',
      readerNamePath: 'aloosi/',
      url: surahUrl4,
    ),
    const ReaderInfo(
      index: 19,
      name: 'عبد الله الجهني',
      readerNamePath: 'abdullaah_3awwaad_al-juhaynee/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 20,
      name: 'عبد الله بصفر',
      readerNamePath: 'abdullaah_basfar/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 21,
      name: 'عبد الله القرافي',
      readerNamePath: 'a_alqrafi/Rewayat-Hafs-A-n-Assem/',
      url: surahUrl2,
    ),
    const ReaderInfo(
      index: 22,
      name: 'عبدالرحمن السديس',
      readerNamePath: 'abdurrahmaan_as-sudays/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 23,
      name: 'عبدالرحمن الشحات',
      readerNamePath: 'abdulrahman_al_shahat/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 24,
      name: 'عبدالكريم الحازمي',
      readerNamePath: 'abdulkareem_al_hazmi/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 25,
      name: 'عبدالله مطرود',
      readerNamePath: 'abdullah_matroud/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 26,
      name: 'علي الحذيفي',
      readerNamePath: 'huthayfi/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 27,
      name: 'فارس عباد',
      readerNamePath: 'fares/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 28,
      name: 'قادر الكردي',
      readerNamePath: 'peshawa/Rewayat-Hafs-A-n-Assem/',
      url: surahUrl2,
    ),
    const ReaderInfo(
      index: 29,
      name: 'ماهر المعيقلي',
      readerNamePath: 'maher_almu3aiqly/year1440/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 30,
      name: 'ماهر المعيقلي - مجود',
      readerNamePath: 'maher/',
      url: surahUrl3,
    ),
    const ReaderInfo(
      index: 31,
      name: 'محمد أيوب',
      readerNamePath: 'muhammad_ayyoob_hq/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 32,
      name: 'محمد المنشاوي',
      readerNamePath: 'muhammad_siddeeq_al-minshaawee/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 33,
      name: 'محمد جبريل',
      readerNamePath: 'muhammad_jibreel/complete/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 34,
      name: 'محمود الحصري',
      readerNamePath: 'mahmood_khaleel_al-husaree_iza3a/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 35,
      name: 'مشاري العفاسي',
      readerNamePath: 'mishaari_raashid_al_3afaasee/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 36,
      name: 'مصطفى العززاوي',
      readerNamePath: 'mustafa_al3azzawi/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 37,
      name: 'ناصر القطامي',
      readerNamePath: 'nasser_bin_ali_alqatami/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 38,
      name: 'هاني الرفاعي',
      readerNamePath: 'rifai/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 39,
      name: 'وديع اليمني',
      readerNamePath: 'wdee3/',
      url: surahUrl4,
    ),
    const ReaderInfo(
      index: 40,
      name: 'ياسر الدوسري',
      readerNamePath: 'yasser_ad-dussary/',
      url: surahUrl1,
    ),
    const ReaderInfo(
      index: 41,
      name: 'ياسر الدوسري - مجود',
      readerNamePath: 'yasser/',
      url: surahUrl5,
    ),
    const ReaderInfo(
      index: 42,
      name: 'يونس سويلص',
      readerNamePath: 'souilass/Rewayat-Warsh-A-n-Nafi/',
      url: surahUrl2,
    ),
  ];
}
