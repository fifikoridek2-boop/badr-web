import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:convert';

class PrayerProvider extends ChangeNotifier {
  PrayerTimes? _prayerTimes;
  Position? _position;
  String _cityName = '';
  String _error = '';
  bool _isLoading = false;

  // إعدادات
  CalculationMethod _method = CalculationMethod.umm_al_qura;
  Madhab _madhab = Madhab.shafi;
  Map<String, bool> _notifications = {
    'fajr': true,
    'sunrise': false,
    'dhuhr': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };
  Map<String, int> _adjustments = {
    'fajr': 0,
    'sunrise': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  PrayerTimes? get prayerTimes => _prayerTimes;
  Position? get position => _position;
  String get cityName => _cityName;
  String get error => _error;
  bool get isLoading => _isLoading;
  CalculationMethod get method => _method;
  Madhab get madhab => _madhab;
  Map<String, bool> get notifications => _notifications;
  Map<String, int> get adjustments => _adjustments;

  final AudioPlayer _audioPlayer = AudioPlayer();

  PrayerProvider() {
    _loadSettings();
  }

  // ═══════════════════════════════════════
  //  تحميل المواقيت
  // ═══════════════════════════════════════
  Future<void> loadPrayerTimes() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // طلب الصلاحية
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _error = 'يرجى السماح بالوصول للموقع من الإعدادات';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // الموقع
      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      // حفظ الإحداثيات
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lat', _position!.latitude);
      await prefs.setDouble('lng', _position!.longitude);

      // حساب المواقيت
      _calculateTimes();

      // اسم المدينة من الإحداثيات
      _cityName = '${_position!.latitude.toStringAsFixed(2)}° , ${_position!.longitude.toStringAsFixed(2)}°';

    } catch (e) {
      // محاولة تحميل الإحداثيات المحفوظة
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('lat');
      final lng = prefs.getDouble('lng');
      if (lat != null && lng != null) {
        _position = Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _calculateTimes();
        _cityName = '${lat.toStringAsFixed(2)}° , ${lng.toStringAsFixed(2)}°';
      } else {
        _error = 'تعذر الحصول على الموقع';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateTimes() {
    if (_position == null) return;
    final coordinates = Coordinates(_position!.latitude, _position!.longitude);
    final params = _method.getParameters();
    params.madhab = _madhab;

    // تطبيق التعديلات

    _prayerTimes = PrayerTimes.today(coordinates, params);
  }

  // ═══════════════════════════════════════
  //  الأوقات كـ List
  // ═══════════════════════════════════════
  List<Map<String, dynamic>> getPrayerList() {
    if (_prayerTimes == null) return [];
    return [
      {
        'key': 'fajr',
        'name': 'الفجر',
        'time': _prayerTimes!.fajr,
        'icon': Icons.brightness_3_outlined,
      },
      {
        'key': 'sunrise',
        'name': 'الشروق',
        'time': _prayerTimes!.sunrise,
        'icon': Icons.wb_twilight_outlined,
      },
      {
        'key': 'dhuhr',
        'name': 'الظهر',
        'time': _prayerTimes!.dhuhr,
        'icon': Icons.wb_sunny_outlined,
      },
      {
        'key': 'asr',
        'name': 'العصر',
        'time': _prayerTimes!.asr,
        'icon': Icons.sunny_snowing,
      },
      {
        'key': 'maghrib',
        'name': 'المغرب',
        'time': _prayerTimes!.maghrib,
        'icon': Icons.wb_twilight,
      },
      {
        'key': 'isha',
        'name': 'العشاء',
        'time': _prayerTimes!.isha,
        'icon': Icons.nightlight_outlined,
      },
    ];
  }

  // الصلاة الحالية أو القادمة
  String getCurrentPrayer() {
    if (_prayerTimes == null) return '';
    final current = _prayerTimes!.currentPrayer();
    switch (current) {
      case Prayer.fajr: return 'الفجر';
      case Prayer.sunrise: return 'الشروق';
      case Prayer.dhuhr: return 'الظهر';
      case Prayer.asr: return 'العصر';
      case Prayer.maghrib: return 'المغرب';
      case Prayer.isha: return 'العشاء';
      default: return '';
    }
  }

  String getNextPrayer() {
    if (_prayerTimes == null) return '';
    final next = _prayerTimes!.nextPrayer();
    switch (next) {
      case Prayer.fajr: return 'الفجر';
      case Prayer.sunrise: return 'الشروق';
      case Prayer.dhuhr: return 'الظهر';
      case Prayer.asr: return 'العصر';
      case Prayer.maghrib: return 'المغرب';
      case Prayer.isha: return 'العشاء';
      default: return '';
    }
  }

  DateTime? getNextPrayerTime() {
    if (_prayerTimes == null) return null;
    final next = _prayerTimes!.nextPrayer();
    return _prayerTimes!.timeForPrayer(next);
  }

  // ═══════════════════════════════════════
  //  الإعدادات
  // ═══════════════════════════════════════
  void setMethod(CalculationMethod method) {
    _method = method;
    _calculateTimes();
    _saveSettings();
    notifyListeners();
  }

  void setMadhab(Madhab madhab) {
    _madhab = madhab;
    _calculateTimes();
    _saveSettings();
    notifyListeners();
  }

  void toggleNotification(String key) {
    _notifications[key] = !(_notifications[key] ?? true);
    _saveSettings();
    notifyListeners();
  }

  void setAdjustment(String key, int minutes) {
    _adjustments[key] = minutes;
    _saveSettings();
    notifyListeners();
  }

  // ═══════════════════════════════════════
  //  تشغيل الأذان
  // ═══════════════════════════════════════
  Future<void> playAdhan() async {
    try {
      await _audioPlayer.setAsset('assets/audio/adan.mp3');
      await _audioPlayer.play();
    } catch (_) {}
  }

  Future<void> stopAdhan() async {
    await _audioPlayer.stop();
  }

  // ═══════════════════════════════════════
  //  حفظ وتحميل الإعدادات
  // ═══════════════════════════════════════
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prayer_method', _method.index);
    await prefs.setInt('prayer_madhab', _madhab.index);
    await prefs.setString('prayer_notifications', jsonEncode(_notifications));
    await prefs.setString('prayer_adjustments', jsonEncode(_adjustments));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final methodIndex = prefs.getInt('prayer_method');
    final madhabIndex = prefs.getInt('prayer_madhab');
    final notifData = prefs.getString('prayer_notifications');
    final adjData = prefs.getString('prayer_adjustments');

    if (methodIndex != null) {
      _method = CalculationMethod.values[methodIndex];
    }
    if (madhabIndex != null) {
      _madhab = Madhab.values[madhabIndex];
    }
    if (notifData != null) {
      _notifications = Map<String, bool>.from(jsonDecode(notifData));
    }
    if (adjData != null) {
      _adjustments = Map<String, int>.from(jsonDecode(adjData));
    }
    notifyListeners();
  }

  static const Map<CalculationMethod, String> methodNames = {
    CalculationMethod.umm_al_qura: 'أم القرى',
    CalculationMethod.muslim_world_league: 'رابطة العالم الإسلامي',
    CalculationMethod.egyptian: 'الهيئة المصرية',
    CalculationMethod.karachi: 'كراتشي',
    CalculationMethod.north_america: 'أمريكا الشمالية',
    CalculationMethod.dubai: 'دبي',
    CalculationMethod.kuwait: 'الكويت',
    CalculationMethod.qatar: 'قطر',
    CalculationMethod.singapore: 'سنغافورة',
    CalculationMethod.turkey: 'تركيا',
  };

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
