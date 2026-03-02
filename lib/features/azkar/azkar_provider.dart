import 'package:flutter/material.dart';
import 'package:badr/core/services/api_service.dart';
import 'package:badr/shared/models/azkar_model.dart';

class AzkarProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, List<AzkarModel>> _azkar = {};
  Map<String, List<AzkarModel>> _duas = {};
  bool _isLoading = false;
  String _error = '';

  Map<String, List<AzkarModel>> get azkar => _azkar;
  Map<String, List<AzkarModel>> get duas => _duas;
  bool get isLoading => _isLoading;
  String get error => _error;

  // أسماء التبويبات العربية
  static const Map<String, String> azkarTabs = {
    'morning_azkar': 'أذكار الصباح',
    'evening_azkar': 'أذكار المساء',
    'sleep_azkar': 'أذكار النوم',
    'wake_azkar': 'أذكار الاستيقاظ',
    'other_azkar': 'أذكار متنوعة',
  };

  static const Map<String, String> duasTabs = {
    'prophetic_duas': 'أدعية نبوية',
    'quran_duas': 'أدعية قرآنية',
    'prophets_duas': 'أدعية الأنبياء',
    'khatm_duas': 'أدعية الختم',
  };

  Future<void> loadData() async {
    if (_azkar.isNotEmpty && _duas.isNotEmpty) return;
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.getAzkar(),
        _api.getDuas(),
      ]);

      // الأذكار
      final azkarData = results[0] as Map<String, dynamic>;
      _azkar = {};
      azkarData.forEach((key, value) {
        if (value is List) {
          _azkar[key] = value
              .map((e) => AzkarModel.fromJson(
                  e as Map<String, dynamic>,
                  azkarTabs[key] ?? key))
              .toList();
        }
      });

      // الأدعية
      final duasData = results[1] as Map<String, dynamic>;
      _duas = {};
      duasData.forEach((key, value) {
        if (value is List) {
          _duas[key] = value
              .map((e) => AzkarModel.fromJson(
                  e as Map<String, dynamic>,
                  duasTabs[key] ?? key))
              .toList();
        }
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void incrementAzkar(String category, int id, bool isDua) {
    final map = isDua ? _duas : _azkar;
    final list = map[category];
    if (list != null) {
      final index = list.indexWhere((a) => a.id == id);
      if (index != -1) {
        list[index].increment();
        notifyListeners();
      }
    }
  }

  void resetCategory(String category, bool isDua) {
    final map = isDua ? _duas : _azkar;
    final list = map[category];
    if (list != null) {
      for (final a in list) {
        a.reset();
      }
      notifyListeners();
    }
  }

  // ذكر عشوائي للصفحة الرئيسية
  String getRandomAzkar() {
    final all = <AzkarModel>[];
    _azkar.forEach((_, list) => all.addAll(list));
    if (all.isEmpty) return '';
    final index = DateTime.now().second % all.length;
    return all[index].text;
  }
}
