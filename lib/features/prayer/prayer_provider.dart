import 'dart:async';
import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerProvider extends ChangeNotifier {
  PrayerTimes? _prayerTimes;
  Position? _position;
  String _cityName = '';
  String _error = '';
  bool _isLoading = false;

  // إعدادات
  CalculationMethod _method = CalculationMethod.umm_al_qura;
  Madhab _madhab = Madhab.shafi;
  bool _isAutoMethod = true;
  bool _isAutoMadhab = true;

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
  bool get isAutoMethod => _isAutoMethod;
  bool get isAutoMadhab => _isAutoMadhab;
  Map<String, bool> get notifications => _notifications;
  Map<String, int> get adjustments => _adjustments;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Stream<Duration> get adhanPositionStream => _audioPlayer.positionStream;
  Stream<Duration?> get adhanDurationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get adhanPlayerStateStream => _audioPlayer.playerStateStream;
  bool get isAdhanPlaying => _audioPlayer.playing;
  Duration? get adhanDuration => _audioPlayer.duration;

  late final StreamSubscription<PlayerState> _playerStateSub;

  PrayerProvider() {
    _playerStateSub = _audioPlayer.playerStateStream.listen((_) {
      notifyListeners();
    });
    _loadSettings();
  }

  Future<void> loadPrayerTimes() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
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

      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lat', _position!.latitude);
      await prefs.setDouble('lng', _position!.longitude);

      _calculateTimes();

      _cityName =
          '${_position!.latitude.toStringAsFixed(2)}° , ${_position!.longitude.toStringAsFixed(2)}°';
    } catch (e) {
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
    final resolvedMethod = _resolveCalculationMethod();
    final resolvedMadhab = _resolveMadhab();
    final params = resolvedMethod.getParameters();
    params.madhab = resolvedMadhab;
    _prayerTimes = PrayerTimes.today(coordinates, params);
  }

  CalculationMethod _resolveCalculationMethod() {
    if (!_isAutoMethod || _position == null) return _method;
    final lat = _position!.latitude;
    final lng = _position!.longitude;

    if (lng >= 34 && lng <= 60 && lat >= 12 && lat <= 40) {
      return CalculationMethod.umm_al_qura;
    }
    if (lng >= 60 && lng <= 95 && lat >= 5 && lat <= 42) {
      return CalculationMethod.karachi;
    }
    if (lng >= -30 && lng <= 55 && lat >= 10 && lat <= 37) {
      return CalculationMethod.egyptian;
    }
    if (lng >= -12 && lng <= 45 && lat >= 37) {
      return CalculationMethod.turkey;
    }
    if (lng <= -30) {
      return CalculationMethod.north_america;
    }
    return CalculationMethod.muslim_world_league;
  }

  Madhab _resolveMadhab() {
    if (!_isAutoMadhab || _position == null) return _madhab;
    final lat = _position!.latitude;
    final lng = _position!.longitude;

    if (lng >= 60 && lng <= 95 && lat >= 5 && lat <= 42) {
      return Madhab.hanafi;
    }
    return Madhab.shafi;
  }

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

  String getCurrentPrayer() {
    if (_prayerTimes == null) return '';
    final current = _prayerTimes!.currentPrayer();
    switch (current) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      default:
        return '';
    }
  }

  String getNextPrayer() {
    if (_prayerTimes == null) return '';
    final next = _prayerTimes!.nextPrayer();
    switch (next) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      default:
        return '';
    }
  }

  DateTime? getNextPrayerTime() {
    if (_prayerTimes == null) return null;
    final next = _prayerTimes!.nextPrayer();
    return _prayerTimes!.timeForPrayer(next);
  }

  void setMethod(CalculationMethod method) {
    _method = method;
    _isAutoMethod = false;
    _calculateTimes();
    _saveSettings();
    notifyListeners();
  }

  void setMethodAuto(bool value) {
    _isAutoMethod = value;
    _calculateTimes();
    _saveSettings();
    notifyListeners();
  }

  void setMadhab(Madhab madhab) {
    _madhab = madhab;
    _isAutoMadhab = false;
    _calculateTimes();
    _saveSettings();
    notifyListeners();
  }

  void setMadhabAuto(bool value) {
    _isAutoMadhab = value;
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

  Future<void> playAdhan() async {
    try {
      final currentAsset = _audioPlayer.audioSource != null;
      if (!currentAsset) {
        await _audioPlayer.setAsset('assets/audio/adan.mp3');
      }
      await _audioPlayer.play();
    } catch (_) {}
  }

  Future<void> pauseAdhan() async {
    await _audioPlayer.pause();
  }

  Future<void> stopAdhan() async {
    await _audioPlayer.stop();
  }

  Future<void> seekAdhan(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prayer_method', _method.index);
    await prefs.setInt('prayer_madhab', _madhab.index);
    await prefs.setBool('prayer_method_auto', _isAutoMethod);
    await prefs.setBool('prayer_madhab_auto', _isAutoMadhab);
    await prefs.setString('prayer_notifications', jsonEncode(_notifications));
    await prefs.setString('prayer_adjustments', jsonEncode(_adjustments));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final methodIndex = prefs.getInt('prayer_method');
    final madhabIndex = prefs.getInt('prayer_madhab');
    final methodAuto = prefs.getBool('prayer_method_auto');
    final madhabAuto = prefs.getBool('prayer_madhab_auto');
    final notifData = prefs.getString('prayer_notifications');
    final adjData = prefs.getString('prayer_adjustments');

    if (methodIndex != null && methodIndex < CalculationMethod.values.length) {
      _method = CalculationMethod.values[methodIndex];
    }
    if (madhabIndex != null && madhabIndex < Madhab.values.length) {
      _madhab = Madhab.values[madhabIndex];
    }
    if (methodAuto != null) {
      _isAutoMethod = methodAuto;
    }
    if (madhabAuto != null) {
      _isAutoMadhab = madhabAuto;
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
    _playerStateSub.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
