import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:badr/core/services/api_service.dart';
import 'package:badr/core/services/storage_service.dart';
import 'package:badr/shared/models/azkar_model.dart';

class AzkarProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Map<String, List<AzkarModel>> _azkar = {};
  Map<String, List<AzkarModel>> _duas = {};
  bool _isLoading = false;
  String _error = '';

  Map<String, List<AzkarModel>> get azkar => _azkar;
  Map<String, List<AzkarModel>> get duas => _duas;
  bool get isLoading => _isLoading;
  String get error => _error;

  static const String _azkarCacheKey = 'azkar_data';
  static const String _duasCacheKey  = 'duas_data';

  static const Map<String, String> azkarTabs = {
    'morning_azkar': 'أذكار الصباح',
    'evening_azkar': 'أذكار المساء',
    'sleep_azkar':   'أذكار النوم',
    'wake_azkar':    'أذكار الاستيقاظ',
    'other_azkar':   'أذكار متنوعة',
  };

  static const Map<String, String> duasTabs = {
    'prophetic_duas': 'أدعية نبوية',
    'quran_duas':     'أدعية قرآنية',
    'prophets_duas':  'أدعية الأنبياء',
    'khatm_duas':     'أدعية الختم',
  };

  Future<void> loadData() async {
    if (_azkar.isNotEmpty && _duas.isNotEmpty) return;
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // ─── Cache-first: try sqflite ───────────────────────────────
      final cachedAzkar = await _storage.getCachedJson(_azkarCacheKey);
      final cachedDuas  = await _storage.getCachedJson(_duasCacheKey);

      if (cachedAzkar != null && cachedDuas != null) {
        _parseAzkar(jsonDecode(cachedAzkar) as Map<String, dynamic>);
        _parseDuas(jsonDecode(cachedDuas) as Map<String, dynamic>);
        _isLoading = false;
        notifyListeners();
        return;
      }

      // ─── Fallback: fetch from API and cache ─────────────────────
      final results = await Future.wait([_api.getAzkar(), _api.getDuas()]);

      final azkarData = results[0] as Map<String, dynamic>;
      final duasData  = results[1] as Map<String, dynamic>;

      _parseAzkar(azkarData);
      _parseDuas(duasData);

      await _storage.cacheJson(_azkarCacheKey, jsonEncode(azkarData));
      await _storage.cacheJson(_duasCacheKey,  jsonEncode(duasData));

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _parseAzkar(Map<String, dynamic> data) {
    _azkar = {};
    data.forEach((key, value) {
      if (value is List) {
        _azkar[key] = value
            .map((e) => AzkarModel.fromJson(e as Map<String, dynamic>, azkarTabs[key] ?? key))
            .toList();
      }
    });
  }

  void _parseDuas(Map<String, dynamic> data) {
    _duas = {};
    data.forEach((key, value) {
      if (value is List) {
        _duas[key] = value
            .map((e) => AzkarModel.fromJson(e as Map<String, dynamic>, duasTabs[key] ?? key))
            .toList();
      }
    });
  }

  /// Force refresh from API (e.g. pull-to-refresh)
  Future<void> refresh() async {
    await _storage.clearCachedJson(_azkarCacheKey);
    await _storage.clearCachedJson(_duasCacheKey);
    _azkar = {};
    _duas  = {};
    await loadData();
  }

  void incrementAzkar(String category, int id, bool isDua) {
    final map  = isDua ? _duas : _azkar;
    final list = map[category];
    if (list == null) return;
    final index = list.indexWhere((a) => a.id == id);
    if (index != -1) { list[index].increment(); notifyListeners(); }
  }

  void resetCategory(String category, bool isDua) {
    final map  = isDua ? _duas : _azkar;
    final list = map[category];
    if (list == null) return;
    for (final a in list) { a.reset(); }
    notifyListeners();
  }

  String getRandomAzkar() {
    final all = <AzkarModel>[];
    _azkar.forEach((_, list) => all.addAll(list));
    if (all.isEmpty) return '';
    return all[DateTime.now().second % all.length].text;
  }
}
