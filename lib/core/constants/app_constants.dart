class AppConstants {
  // ═══════════════════════════════════════
  //  معلومات التطبيق
  // ═══════════════════════════════════════
  static const String appName = 'بدر';
  static const String appVersion = '1.0.0';
  static const String packageId = 'com.badr.app';

  // ═══════════════════════════════════════
  //  الخطوط
  // ═══════════════════════════════════════
  static const String fontAyat = 'Ayat';
  static const String fontCairo = 'Cairo';

  // ═══════════════════════════════════════
  //  الأصول
  // ═══════════════════════════════════════
  static const String logoPath = 'assets/images/logo.png';
  static const String adanPath = 'assets/audio/adan.mp3';

  // ═══════════════════════════════════════
  //  Shared Preferences Keys
  // ═══════════════════════════════════════
  static const String keyThemeMode = 'theme_mode';
  static const String keyFontSize = 'font_size_quran';
  static const String keyFontType = 'font_type_quran';
  static const String keyAdanEnabled = 'adan_enabled';
  static const String keyLastSurah = 'last_surah_read';
  static const String keyLastPage = 'last_page_read';
  static const String keyTasbihCounts = 'tasbih_counts';

  // ═══════════════════════════════════════
  //  قاعدة البيانات
  // ═══════════════════════════════════════
  static const String dbName = 'badr.db';
  static const int dbVersion = 1;

  // ═══════════════════════════════════════
  //  الأوفلاين - مسارات الصوت
  // ═══════════════════════════════════════
  static const String audioFolder = 'badr_audio';

  // ═══════════════════════════════════════
  //  أوقات الصلاة
  // ═══════════════════════════════════════
  static const List<String> prayerNames = [
    'الفجر',
    'الشروق',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];

  // ═══════════════════════════════════════
  //  التسبيح
  // ═══════════════════════════════════════
  static const List<String> tasbihTexts = [
    'سبحان الله',
    'الحمد لله',
    'لا إله إلا الله',
    'الله أكبر',
  ];
}