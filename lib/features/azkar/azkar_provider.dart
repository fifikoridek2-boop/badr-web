import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

      // حفظ البيانات محلياً
      await _saveToCache();
    } catch (e) {
      // محاولة تحميل من الكاش
      await _loadFromCache();
      if (_azkar.isEmpty && _duas.isEmpty) {
        // تحميل البيانات المحلية كـ fallback
        _loadFallbackData();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadFallbackData() {
    // أذكار الصباح
    _azkar['morning_azkar'] = [
      AzkarModel(id: 1, text: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَـهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ', category: 'أذكار الصباح', count: 1),
      AzkarModel(id: 2, text: 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ', category: 'أذكار الصباح', count: 1),
      AzkarModel(id: 3, text: 'اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ', category: 'أذكار الصباح', count: 1),
      AzkarModel(id: 4, text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ', category: 'أذكار الصباح', count: 1),
      AzkarModel(id: 5, text: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ، لاَ إِلَهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ', category: 'أذكار الصباح', count: 100),
    ];

    // أذكار المساء
    _azkar['evening_azkar'] = [
      AzkarModel(id: 1, text: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ للهِ، وَالْحَمْدُ للهِ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ', category: 'أذكار المساء', count: 1),
      AzkarModel(id: 2, text: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ', category: 'أذكار المساء', count: 1),
      AzkarModel(id: 3, text: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ', category: 'أذكار المساء', count: 1),
      AzkarModel(id: 4, text: 'أَعُوذُ بِكَلِمَاتِ اللهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ', category: 'أذكار المساء', count: 3),
    ];

    // أذكار النوم
    _azkar['sleep_azkar'] = [
      AzkarModel(id: 1, text: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا', category: 'أذكار النوم', count: 1),
      AzkarModel(id: 2, text: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ', category: 'أذكار النوم', count: 3),
      AzkarModel(id: 3, text: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا', category: 'أذكار النوم', count: 1),
      AzkarModel(id: 4, text: 'سُبْحَانَ اللهِ', category: 'أذكار النوم', count: 33),
      AzkarModel(id: 5, text: 'الْحَمْدُ لِلَّهِ', category: 'أذكار النوم', count: 33),
      AzkarModel(id: 6, text: 'اللهُ أَكْبَرُ', category: 'أذكار النوم', count: 34),
    ];

    // الأدعية النبوية
    _duas['prophetic_duas'] = [
      AzkarModel(id: 1, text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ', category: 'أدعية نبوية', count: 1),
      AzkarModel(id: 2, text: 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِنْ لِسَانِي يَفْقَهُوا قَوْلِي', category: 'أدعية نبوية', count: 1),
      AzkarModel(id: 3, text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى', category: 'أدعية نبوية', count: 1),
      AzkarModel(id: 4, text: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عِلْمٍ لَا يَنْفَعُ وَقَلْبٍ لَا يَخْشَعُ وَدُعَاءٍ لَا يُسْمَعُ', category: 'أدعية نبوية', count: 1),
    ];

    // الأدعية القرآنية
    _duas['quran_duas'] = [
      AzkarModel(id: 1, text: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ', category: 'أدعية قرآنية', count: 1),
      AzkarModel(id: 2, text: 'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَىٰ وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ وَأَدْخِلْنِي بِرَحْمَتِكَ فِي عِبَادِكَ الصَّالِحِينَ', category: 'أدعية قرآنية', count: 1),
      AzkarModel(id: 3, text: 'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا', category: 'أدعية قرآنية', count: 1),
    ];
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final azkarJson = _azkar.map((k, v) => MapEntry(k, v.map((a) => {
        'id': a.id,
        'text': a.text,
        'category': a.category,
        'count': a.count,
        'currentCount': a.currentCount,
      }).toList()));
      final duasJson = _duas.map((k, v) => MapEntry(k, v.map((a) => {
        'id': a.id,
        'text': a.text,
        'category': a.category,
        'count': a.count,
        'currentCount': a.currentCount,
      }).toList()));
      await prefs.setString('azkar_cache', jsonEncode(azkarJson));
      await prefs.setString('duas_cache', jsonEncode(duasJson));
    } catch (_) {}
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final azkarCache = prefs.getString('azkar_cache');
      final duasCache = prefs.getString('duas_cache');

      if (azkarCache != null) {
        final Map<String, dynamic> data = jsonDecode(azkarCache);
        _azkar = data.map((k, v) => MapEntry(k, (v as List).map((a) {
          final model = AzkarModel.fromJson(a as Map<String, dynamic>, a['category'] ?? k);
          model.currentCount = a['currentCount'] ?? 0;
          return model;
        }).toList()));
      }

      if (duasCache != null) {
        final Map<String, dynamic> data = jsonDecode(duasCache);
        _duas = data.map((k, v) => MapEntry(k, (v as List).map((a) {
          final model = AzkarModel.fromJson(a as Map<String, dynamic>, a['category'] ?? k);
          model.currentCount = a['currentCount'] ?? 0;
          return model;
        }).toList()));
      }
    } catch (_) {}
  }

  void incrementAzkar(String category, int id, bool isDua) {
    final map = isDua ? _duas : _azkar;
    final list = map[category];
    if (list != null) {
      final index = list.indexWhere((a) => a.id == id);
      if (index != -1) {
        list[index].increment();
        _saveToCache();
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
      _saveToCache();
      notifyListeners();
    }
  }

  // ذكر عشوائي للصفحة الرئيسية
  String getRandomAzkar() {
    final all = <AzkarModel>[];
    _azkar.forEach((_, list) => all.addAll(list));
    if (all.isEmpty) {
      return 'سبحان الله وبحمده';
    }
    final index = DateTime.now().second % all.length;
    return all[index].text;
  }
}
