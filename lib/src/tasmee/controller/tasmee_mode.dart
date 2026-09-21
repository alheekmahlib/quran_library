/// نمط التسميع داخل وضع التسميع.
library;

/// يحدّد سلوك الجلسة وطرق العرض الافتراضية:
/// - [tasmee]: الكلمات مخفية وتظهر أثناء التلاوة (السلوك الكلاسيكي).
/// - [corrector]: الآيات ظاهرة مع تصحيح فوري لكل كلمة خاطئة.
/// - [teacher]: القارئ يتلو الآية ثم يسمّعها المستخدم حتى تُتلى صحيحة.
enum TasmeeMode {
  tasmee,
  corrector,
  teacher;

  /// هل كلمات الصفحة ظاهرة افتراضيًا في هذا النمط؟
  ///
  /// التسميع الكلاسيكي يخفيها (وإلا بطل الغرض)، بينما المصحح والمعلم
  /// يحتاجان رؤية الآيات أثناء التصحيح والتقليد.
  bool get showsWordsByDefault => this != TasmeeMode.tasmee;

  /// اسم النمط كما يُخزَّن ويُسجَّل مع النتائج.
  String get storageName => name;
}

/// يحوّل اسم النمط المخزَّن إلى [TasmeeMode] — أي قيمة مجهولة تُرجع
/// التسميع الكلاسيكي (افتراضي آمن للترقيات المستقبلية).
TasmeeMode tasmeeModeFromName(String? name) => switch (name) {
      'corrector' => TasmeeMode.corrector,
      'teacher' => TasmeeMode.teacher,
      _ => TasmeeMode.tasmee,
    };
