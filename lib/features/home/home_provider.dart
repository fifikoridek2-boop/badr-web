import 'package:flutter/material.dart';

import 'package:badr/core/services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  String _azkarText = '';
  bool _isLoading = false;
  String _error = '';

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
        _azkarText = allAzkar[index]['text']?.toString() ?? '';
      }
    } catch (e) {
      _error = e.toString();
      _azkarText = 'سبحان الله وبحمده، سبحان الله العظيم';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
