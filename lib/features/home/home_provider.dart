import 'package:flutter/material.dart';

import 'package:badr/core/services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  String _azkarText = '';
  bool _isLoading = false;
  String _error = '';

  // أذكار افتراضية للعرض بدون إنترنت
  static const List<String> _fallbackAzkar = [
    'سُبْحَانَ اللهِ وَبِحَمْدِهِ، سُبْحَانَ اللهِ الْعَظِيمِ',
    'لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي',
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
    'سُبْحَانَ اللهِ وَبِحَمْدِهِ، وَأَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ',
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
  ];

  String get azkarText => _azkarText;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final azkarData = await _api.getAzkar() as Map<String, dynamic>;
      final allAzkar = <Map<String, dynamic>>[];

      azkarData.forEach((key, value) {
        if (value is List) {
          for (final item in value) {
            if (item is Map<String, dynamic>) {
              allAzkar.add(item);
            }
          }
        }
      });

      if (allAzkar.isNotEmpty) {
        final index = DateTime.now().second % allAzkar.length;
        _azkarText = allAzkar[index]['text']?.toString() ?? _getRandomFallback();
      } else {
        _azkarText = _getRandomFallback();
      }
    } catch (e) {
      _error = '';
      _azkarText = _getRandomFallback();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getRandomFallback() {
    final index = DateTime.now().second % _fallbackAzkar.length;
    return _fallbackAzkar[index];
  }
}
