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
  static const List<Map<String, dynamic>> ayahReaderInfo = [
    {
      'index': 0,
      'name': 'عبد الباسط',
      'readerD': 'Abdul_Basit_Murattal_192kbps',
      'readerI': 'basit',
      'url': ayahs2ndSource
    },
    {
      'index': 1,
      'name': 'محمد المنشاوي',
      'readerD': 'Minshawy_Murattal_128kbps',
      'readerI': 'minshawy',
      'url': ayahs2ndSource
    },
    {
      'index': 2,
      'name': 'محمود الحصري',
      'readerD': 'Husary_128kbps',
      'readerI': 'husary',
      'url': ayahs2ndSource
    },
    {
      'index': 3,
      'name': 'أحمد العجمي',
      'readerD': '128/ar.ahmedajamy',
      'readerI': 'ajamy',
      'url': ayahs1stSource
    },
    {
      'index': 4,
      'name': 'ماهر المعيقلي',
      'readerD': 'MaherAlMuaiqly128kbps',
      'readerI': 'muaiqly',
      'url': ayahs2ndSource
    },
    {
      'index': 5,
      'name': 'سعود الشريم',
      'readerD': 'Saood_ash-Shuraym_128kbps',
      'readerI': 'saood',
      'url': ayahs2ndSource
    },
    {
      'index': 6,
      'name': 'عبد الله الجهني',
      'readerD': 'Abdullaah_3awwaad_Al-Juhaynee_128kbps',
      'readerI': 'Juhaynee',
      'url': ayahs2ndSource
    },
    {
      'index': 7,
      'name': 'فارس عباد',
      'readerD': 'Fares_Abbad_64kbps',
      'readerI': 'Fares',
      'url': ayahs2ndSource
    },
    {
      'index': 8,
      'name': 'محمد أيوب',
      'readerD': '128/ar.muhammadayyoub',
      'readerI': 'ayyoob',
      'url': ayahs1stSource
    },
    {
      'index': 9,
      'name': 'ماهر المعيقلي - مجود',
      'readerD': 'MaherAlMuaiqly128kbps',
      'readerI': 'maher',
      'url': ayahs2ndSource,
    },
    {
      'index': 10,
      'name': 'ياسر الدوسري - مجود',
      'readerD': 'Yasser_Ad-Dussary_128kbps',
      'readerI': 'yasser_ad-dussary',
      'url': ayahs2ndSource
    },
  ];

  static const List<Map<String, dynamic>> surahReaderInfo = [
    {
      'name': 'عبد الباسط',
      'readerD': surahUrl1,
      'readerN': 'abdul_basit_murattal/',
      'readerI': 'basit'
    },
    {
      'name': 'محمد المنشاوي',
      'readerD': surahUrl1,
      'readerN': 'muhammad_siddeeq_al-minshaawee/',
      'readerI': 'minshawy'
    },
    {
      'name': 'محمود الحصري',
      'readerD': surahUrl1,
      'readerN': 'mahmood_khaleel_al-husaree_iza3a/',
      'readerI': 'husary'
    },
    {
      'name': 'أحمد العجمي',
      'readerD': surahUrl1,
      'readerN': 'ahmed_ibn_3ali_al-3ajamy/',
      'readerI': 'ajamy'
    },
    {
      'name': 'ماهر المعيقلي',
      'readerD': surahUrl1,
      'readerN': 'maher_almu3aiqly/year1440/',
      'readerI': 'muaiqly'
    },
    {
      'name': 'سعود الشريم',
      'readerD': surahUrl1,
      'readerN': 'sa3ood_al-shuraym/',
      'readerI': 'saood'
    },
    {
      'name': 'سعد الغامدي',
      'readerD': surahUrl1,
      'readerN': 'sa3d_al-ghaamidi/complete/',
      'readerI': 'Ghamadi'
    },
    {
      'name': 'مصطفى العززاوي',
      'readerD': surahUrl1,
      'readerN': 'mustafa_al3azzawi/',
      'readerI': 'mustafa'
    },
    {
      'name': 'ناصر القطامي',
      'readerD': surahUrl1,
      'readerN': 'nasser_bin_ali_alqatami/',
      'readerI': 'nasser'
    },
    {
      'name': 'قادر الكردي',
      'readerD': surahUrl2,
      'readerN': 'peshawa/Rewayat-Hafs-A-n-Assem/',
      'readerI': 'qader'
    },
    {
      'name': 'شيرزاد طاهر',
      'readerD': surahUrl3,
      'readerN': 'taher/',
      'readerI': 'taher'
    },
    {
      'name': 'عبد الرحمن العوسي',
      'readerD': surahUrl4,
      'readerN': 'aloosi/',
      'readerI': 'aloosi'
    },
    {
      'name': 'وديع اليمني',
      'readerD': surahUrl4,
      'readerN': 'wdee3/',
      'readerI': 'wdee3'
    },
    {
      'name': 'ياسر الدوسري',
      'readerD': surahUrl1,
      'readerN': 'yasser_ad-dussary/',
      'readerI': 'yasser_ad-dussary'
    },
    {
      'name': 'عبد الله الجهني',
      'readerD': surahUrl1,
      'readerN': 'abdullaah_3awwaad_al-juhaynee/',
      'readerI': 'Juhaynee'
    },
    {
      'name': 'فارس عباد',
      'readerD': surahUrl1,
      'readerN': 'fares/',
      'readerI': 'Fares'
    },
    {
      'name': 'محمد أيوب',
      'readerD': surahUrl1,
      'readerN': 'muhammad_ayyoob_hq/',
      'readerI': 'ayyoob'
    },
    {
      'name': 'ماهر المعيقلي - مجود',
      'readerD': surahUrl3,
      'readerN': 'maher/',
      'readerI': 'maher'
    },
    {
      'name': 'أحمد النفيس - مجود',
      'readerD': surahUrl2,
      'readerN': 'nufais/Rewayat-Hafs-A-n-Assem/',
      'readerI': 'nufais'
    },
    {
      'name': 'ياسر الدوسري - مجود',
      'readerD': surahUrl5,
      'readerN': 'yasser/',
      'readerI': 'yasser_ad-dussary'
    },
  ];
}
