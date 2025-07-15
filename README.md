# مكتبة القرآن الكريم (Quran Library)

![Quran Library Banner](https://raw.githubusercontent.com/alheekmahlib/quran_library/main/assets/images/banner.png)

مكتبة متكاملة لعرض القرآن الكريم في تطبيقات Flutter، مطابقة لمصحف المدينة برواية حفص عن عاصم. توفر هذه المكتبة حلاً مرنًا وعالي الأداء لدمج النصوص القرآنية، التفاسير، والعديد من خيارات العرض في مشاريع Flutter الخاصة بك.

## الميزات الرئيسية

*   **عرض مصحف المدينة**: عرض القرآن الكريم بخط مصحف المدينة، مطابق تمامًا للمصحف الورقي.
*   **تفاسير متعددة**: دعم عرض التفاسير المختلفة (مثل تفسير السعدي) مع إمكانية التبديل بينها.
*   **تخصيص الخطوط**: إمكانية تغيير حجم الخطوط وأنواعها لتناسب تفضيلات المستخدم.
*   **البحث المتقدم**: وظائف بحث قوية للعثور على الآيات والسور بسهولة.
*   **إدارة الإشارات المرجعية**: حفظ واستعراض الإشارات المرجعية (Bookmarks) للوصول السريع إلى الآيات المفضلة.
*   **تصميم مرن**: مكونات واجهة مستخدم قابلة للتخصيص لتناسب تصميم تطبيقك.
*   **دعم متعدد المنصات**: يعمل بسلاسة على أنظمة Android و iOS.

## التثبيت

لإضافة مكتبة القرآن الكريم إلى مشروع Flutter الخاص بك، اتبع الخطوات التالية:

1.  **أضف التبعية في `pubspec.yaml`:**

    ```yaml
dependencies:
  quran_library: ^1.2.7 # استخدم أحدث إصدار متاح
    ```

2.  **قم بتشغيل `flutter pub get`:**

    ```bash
flutter pub get
    ```

3.  **أضف الأصول (Assets) المطلوبة:**

    تتطلب المكتبة بعض الأصول (الخطوط، ملفات JSON، قاعدة بيانات التفاسير). تأكد من إضافة المسارات التالية إلى قسم `flutter` في `pubspec.yaml`:

    ```yaml
flutter:
  assets:
    - assets/
    - assets/fonts/
    - assets/jsons/
    - assets/svg/
    - assets/svg/surah_name/
    - assets/saadiV4.db
    - assets/en.json

  fonts:
    - family: kufi
      fonts:
        - asset: assets/fonts/Kufam-Regular.ttf
    - family: naskh
      fonts:
        - asset: assets/fonts/NotoNaskhArabic-VariableFont_wght.ttf
    - family: hafs
      fonts:
        - asset: assets/fonts/UthmanicHafs_V20.ttf
    ```

    **ملاحظة**: يجب أن تكون هذه الملفات موجودة في مجلد `assets` في جذر مشروعك. يمكنك العثور عليها في [مستودع GitHub الخاص بالمكتبة](https://github.com/alheekmahlib/quran_library/tree/main/assets).

## الاستخدام

لاستخدام المكتبة، قم باستيرادها في ملفات Dart الخاصة بك:

```dart
import 'package:quran_library/quran_library.dart';
```

### عرض صفحات القرآن

يمكنك استخدام `QuranLibraryScreen` لعرض صفحات القرآن الكريم:

```dart
import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: QuranLibraryScreen(),
    );
  }
}
```

### تخصيص الخطوط وحجم النص

يمكنك التحكم في حجم النص والخطوط المستخدمة عبر `QuranCtrl`:

```dart
import 'package:get/get.dart';
import 'package:quran_library/quran_library.dart';

// داخل أي Widget أو Controller
final quranCtrl = Get.find<QuranCtrl>();
quranCtrl.updateTextScale(ScaleUpdateDetails(scale: 1.5)); // لتكبير النص

// لتغيير الخط (مثال: استخدام خط Hafs)
// تأكد من أن الخطوط معرفة في pubspec.yaml
// quranCtrl.changeFontFamily('hafs'); // هذه الوظيفة غير موجودة حاليًا، تحتاج إلى إضافة منطق لتغيير الخطوط
```

### البحث في القرآن

يمكنك استخدام وظيفة البحث للعثور على الآيات:

```dart
import 'package:get/get.dart';
import 'package:quran_library/quran_library.dart';

// داخل أي Widget أو Controller
final quranCtrl = Get.find<QuranCtrl>();
List<AyahModel> searchResults = quranCtrl.search('قل هو الله أحد');

// لعرض نتائج البحث
// يمكنك استخدام QuranLibrarySearchScreen أو بناء واجهة مخصصة
```

### إدارة الإشارات المرجعية

يمكنك إضافة، حذف، واستعراض الإشارات المرجعية:

```dart
import 'package:get/get.dart';
import 'package:quran_library/quran_library.dart';

// داخل أي Widget أو Controller
final bookmarksCtrl = Get.find<BookmarksCtrl>();

// إضافة إشارة مرجعية
bookmarksCtrl.addBookmark(ayahNumber: 123, surahNumber: 2, pageNumber: 50);

// حذف إشارة مرجعية
bookmarksCtrl.removeBookmark(bookmarkId: 'some_id'); // تحتاج إلى معرف فريد للإشارة المرجعية

// الحصول على جميع الإشارات المرجعية
List<Bookmark> allBookmarks = bookmarksCtrl.bookmarks;
```

## المساهمة

نرحب بمساهماتكم لتحسين هذه المكتبة. يرجى قراءة [CONTRIBUTING.md](CONTRIBUTING.md) (إذا كان موجودًا) للحصول على إرشادات حول كيفية المساهمة.

## الترخيص

هذه المكتبة مرخصة بموجب ترخيص MIT. انظر ملف [LICENSE](LICENSE) لمزيد من التفاصيل.

## تواصل معنا

للاستفسارات أو الدعم، يرجى فتح مشكلة (Issue) في [مستودع GitHub](https://github.com/alheekmahlib/quran_library/issues).


