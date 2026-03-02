class PrayerModel {
  final String region;
  final String country;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String dateEn;
  final String dateHijri;

  PrayerModel({
    required this.region,
    required this.country,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.dateEn,
    required this.dateHijri,
  });

  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    final times = json['prayer_times'] as Map<String, dynamic>? ?? {};
    final date = json['date'] as Map<String, dynamic>? ?? {};
    final hijri = date['date_hijri'] as Map<String, dynamic>? ?? {};
    final hijriMonth = hijri['month'] as Map<String, dynamic>? ?? {};

    return PrayerModel(
      region: json['region']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      fajr: times['Fajr']?.toString() ?? '',
      sunrise: times['Sunrise']?.toString() ?? '',
      dhuhr: times['Dhuhr']?.toString() ?? '',
      asr: times['Asr']?.toString() ?? '',
      maghrib: times['Maghrib']?.toString() ?? '',
      isha: times['Isha']?.toString() ?? '',
      dateEn: date['date_en']?.toString() ?? '',
      dateHijri:
          '${hijri['day']} ${hijriMonth['ar']} ${hijri['year']}',
    );
  }

  Map<String, String> get allPrayers => {
        'الفجر': fajr,
        'الشروق': sunrise,
        'الظهر': dhuhr,
        'العصر': asr,
        'المغرب': maghrib,
        'العشاء': isha,
      };

  String getNextPrayer() {
    final now = DateTime.now();
    for (final entry in allPrayers.entries) {
      final time = _parseTime(entry.value);
      if (time != null && time.isAfter(now)) {
        return entry.key;
      }
    }
    return 'الفجر';
  }

  String getNextPrayerTime() {
    final now = DateTime.now();
    for (final entry in allPrayers.entries) {
      final time = _parseTime(entry.value);
      if (time != null && time.isAfter(now)) {
        return entry.value;
      }
    }
    return fajr;
  }

  String getTimeRemaining() {
    final now = DateTime.now();
    for (final entry in allPrayers.entries) {
      final time = _parseTime(entry.value);
      if (time != null && time.isAfter(now)) {
        final diff = time.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        if (hours > 0) return 'بعد $hours س $minutes د';
        return 'بعد $minutes دقيقة';
      }
    }
    return '';
  }

  DateTime? _parseTime(String timeStr) {
    try {
      if (timeStr.isEmpty) return null;
      final now = DateTime.now();
      // الصيغة "05:32" بدون AM/PM
      final parts = timeStr.trim().split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return null;
    }
  }
}
