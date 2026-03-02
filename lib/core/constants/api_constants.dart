class ApiConstants {
  // ═══════════════════════════════════════
  //  Base URL
  // ═══════════════════════════════════════
  static const String baseUrl = 'https://quran.yousefheiba.com/api';
  static const String audioBaseUrl = 'https://server.yousefheiba.com/recitations';

  // ═══════════════════════════════════════
  //  القرآن الكريم
  // ═══════════════════════════════════════
  static const String surahs = '$baseUrl/surahs';
  static const String ayahs = '$baseUrl/ayah';
  static const String quranPagesText = '$baseUrl/quranPagesText';

  // ═══════════════════════════════════════
  //  الأذكار والأدعية
  // ═══════════════════════════════════════
  static const String azkar = '$baseUrl/azkar';
  static const String duas = '$baseUrl/duas';

  // ═══════════════════════════════════════
  //  مواقيت الصلاة
  // ═══════════════════════════════════════
  static const String prayerTimes = '$baseUrl/getPrayerTimes';

  // ═══════════════════════════════════════
  //  القراء والصوتيات
  // ═══════════════════════════════════════
  static const String reciters = '$baseUrl/reciters';
  static const String reciterAudio = '$baseUrl/reciterAudio';
  static const String surahAudio = '$baseUrl/surahAudio';

  // ═══════════════════════════════════════
  //  الراديو المباشر
  // ═══════════════════════════════════════
  static const String radio = '$baseUrl/radio';
  static const String radioStream = 'https://radio.yousefheiba.com/quran_radio.mp3';

  // ═══════════════════════════════════════
  //  ليلة القدر
  // ═══════════════════════════════════════
  static const String laylatAlQadr = '$baseUrl/laylatAlQadr';
}