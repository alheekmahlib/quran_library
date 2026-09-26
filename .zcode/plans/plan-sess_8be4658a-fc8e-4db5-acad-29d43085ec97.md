‫السبب الجذري (مُتحقق منه بالكود): عند تفعيل التمرير التلقائي تُستبدل شاشة القراءة بـ AutoScrollPageView ‏(ListView عمودي)، فلا يبقى أي PageView متصل بـ quranPagesController. وعندما تنتهي آخر آية في الصفحة أثناء التلاوة ينتقل المشغّل تلقائيًا للآية التالية (أول آية في الصفحة التالية)، فيكتشف مستمع sequenceStateStream تغيّر الصفحة ويستدعي quranPagesController.animateToPage() مباشرة في ayah_ctrl_extension.dart:227 بلا أي فحص — فيرمي استثناءً (متحكم صفحات بلا مواضع مرتبطة). والأسوأ أن الخطأ يقاطع بقية المستمع، فلا يُنفَّذ كود توسيع نافذة التشغيل (الأسطر 236–266) فتتوقف التلاوة عند نفاد النافذة المحمّلة.‬

‫الإصلاح — ملف واحد فقط: lib/src/audio/controller/extensions/ayah_ctrl_extension.dart ‏(لا استيرادات جديدة؛ AutoScrollCtrl جزء من /quran.dart المستورد أصلًا في audio.dart):‬

‫1. إضافة getter خاص داخل الامتداد:‬
```dart
/// التمرير التلقائي فعّال؟ لا يوجد PageView أفقي متصل بالمتحكم في هذا الوضع
bool get _isAutoScrollActive =>
    Get.isRegistered<AutoScrollCtrl>() &&
    AutoScrollCtrl.instance.state.isActive.value;
```

‫2. تعديل كتلة تغيّر الصفحة داخل مستمع sequenceStateStream ‏(الأسطر 217–232) لتصبح: إن كان التمرير التلقائي فعّالًا → لا قلب صفحة (سجل log فقط)؛ وإلا إن كان hasClients → animateToPage كما هو؛ وإلا → لا شيء:‬
```dart
if (newPage != prevPage) {
  if (_isAutoScrollActive) {
    log('Page changed: $prevPage -> $newPage, auto-scroll active — skipping page flip',
        name: 'AudioController');
  } else if (QuranCtrl.instance.quranPagesController.hasClients) {
    log('Page changed: $prevPage -> $newPage, animating...', name: 'AudioController');
    await QuranCtrl.instance.quranPagesController.animateToPage(
        newPage - 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut);
  }
}
```
‫النتيجة في وضع التمرير التلقائي: لا قلب صفحة، التلاوة تكمل للآية التالية، التمييز ينتقل إليها (معروضة أسفل في القائمة العمودية)، والتمرير يواصل بوتيرته المستقلة — وهو سلوكك المطلوب حرفيًا. وفي الوضع الافتراضي يبقى القلب الأفقي كما هو بلا أي انحدار.‬

‫3. تحصين moveToNextPage و moveToPreviousPage ‏(يستدعيهما زرا التخطي، وهما ظاهران أثناء الإيقاف المؤقت للتمرير التلقائي فيقع نفس الانهيار): return مبكرًا إذا كان التمرير التلقائي فعّالًا أو المتحكم بلا hasClients.‬

‫التحقق:‬
- `flutter analyze` ثم `flutter test` ‏(التأكد من صفر أخطاء جديدة وعدم كسر الاختبارات الحالية).‬
- ‫إن كان تطبيق example يعمل فسأكتشفه عبر DTD وأنفّذ hot reload بعد التعديل (قاعدة 15.1 في AGENTS.md).‬
- ‫خطوات اختبار يدوي أوصيك بها بعد التنفيذ: (1) الوضع الافتراضي + تلاوة تعبر حد صفحة → يقلب كالمعتاد. (2) تمرير تلقائي + تلاوة تعبر حد صفحة → لا خطأ، تكمل التلاوة، ينتقل التمييز. (3) إيقاف مؤقت للتمرير + زر تخطي الآية عبر حد صفحة → لا خطأ.‬
- ‫لا اختبار آلي جديد: التغيير حماية وقت تشغيل داخل مستمع stream يعتمد just_audio وGetX وPageController، ولا يوجد harness لذلك في المستودع (اختباراته كلها unit خالصة للخدمات والنماذج) — أكتفي بالتحليل الساكن والاختبار اليدوي.‬

‫ملاحظة خارج النطاق (بدون تعديل الآن): isLastAyahInPage في surah_getters.dart:209 مطابق لجسد isLastAyahInSurah ‏(يقارن بآخر آية في السورة لا في الصفحة)، ما يجعل isLastAyahInPageButNotInSurah دائمًا false؛ أي أن زر التخطي في الوضع العادي لا يقلب الصفحة عند تجاوز حدودها أصلًا. خلل قائم منفصل — أخبرني إن أردت إصلاحه لاحقًا.‬