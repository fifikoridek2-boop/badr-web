import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart' as qlib;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:badr/shared/models/ayah_model.dart';
import 'package:badr/shared/models/quran_page_model.dart';
import 'package:badr/shared/models/surah_model.dart';
import 'package:badr/features/quran/local_surah_data.dart';

class QuranProvider extends ChangeNotifier {
  final qlib.QuranLibrary _quran = qlib.QuranLibrary();

  static bool _isQuranInitialized = false;

  List<SurahModel> _surahs = [];
  List<AyahModel> _ayahs = [];
  List<SurahModel> _filteredSurahs = [];
  List<Map<String, dynamic>> _bookmarks = [];
  QuranPageModel? _currentPage;

  bool _isLoadingSurahs = false;
  bool _isLoadingAyahs = false;
  bool _isLoadingPage = false;
  String _error = '';
  int _currentSurahNumber = 1;
  int _currentPageNumber = 1;
  double _fontSize = 22.0;

  List<SurahModel> get surahs => _filteredSurahs;
  List<AyahModel> get ayahs => _ayahs;
  QuranPageModel? get currentPage => _currentPage;
  bool get isLoadingSurahs => _isLoadingSurahs;
  bool get isLoadingAyahs => _isLoadingAyahs;
  bool get isLoadingPage => _isLoadingPage;
  String get error => _error;
  int get currentSurahNumber => _currentSurahNumber;
  int get currentPageNumber => _currentPageNumber;
  double get fontSize => _fontSize;
  List<Map<String, dynamic>> get bookmarks => _bookmarks;

  QuranProvider() {
    _loadBookmarks();
  }

  Future<void> _ensureQuranInitialized() async {
    if (_isQuranInitialized) return;
    await qlib.QuranLibrary.init();
    _isQuranInitialized = true;
  }

  Future<void> loadSurahs() async {
    if (_surahs.isNotEmpty) {
      _error = '';
      _filteredSurahs = List.from(_surahs);
      notifyListeners();
      return;
    }

    _isLoadingSurahs = true;
    _error = '';

    // اعرض قائمة السور فوراً من بيانات محلية مضمّنة حتى تعمل الشاشة بدون إنترنت
    // وبدون انتظار تهيئة quran_library أو أي خدمة داخلية فيها.
    _surahs = _buildFallbackSurahs();
    _filteredSurahs = List.from(_surahs);
    notifyListeners();

    try {
      await _ensureQuranInitialized();

      final librarySurahs = List.generate(114, (index) {
        final surahNumber = index + 1;
        final info = _quran.getSurahInfo(surahNumber: surahNumber);
        return SurahModel(
          id: surahNumber,
          number: surahNumber,
          arName: _plainSurahName(surahNumber),
          nameEn: info.englishName,
          type: _normalizeRevelationType(info.revelationType),
          ayatCount: info.ayahsNumber,
        );
      });

      if (librarySurahs.length == 114) {
        _surahs = librarySurahs;
        _filteredSurahs = List.from(_surahs);
      }
    } catch (_) {
      // نبقي البيانات المحلية ظاهرة ولا نعرض خطأ إنترنت لقائمة السور.
      _error = '';
    } finally {
      _isLoadingSurahs = false;
      notifyListeners();
    }
  }

  Future<void> loadPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) return;
    _isLoadingPage = true;
    _currentPageNumber = pageNumber;
    _error = '';
    notifyListeners();
    try {
      await _ensureQuranInitialized();

      final pageAyahs = _quran.getPageAyahsByPageNumber(pageNumber: pageNumber);
      final surah = _quran.getCurrentSurahDataByPageNumber(pageNumber: pageNumber);
      final juz = _quran.getJuzByPageNumber(pageNumber: pageNumber);

      final ayahs = pageAyahs
          .map(
            (a) => PageAyahModel(
              ayahNumber: a.ayahNumber,
              text: a.text,
              juzNumber: a.juz,
              sajda: a.sajda != null && a.sajda != false,
            ),
          )
          .toList();

      _currentPage = QuranPageModel(
        pageNumber: pageNumber,
        surahNameAr: surah.arabicName,
        surahNumber: surah.surahNumber,
        juzNumber: juz.juz,
        ayahs: ayahs,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingPage = false;
      notifyListeners();
    }
  }

  Future<void> loadAyahs(int surahNumber) async {
    _isLoadingAyahs = true;
    _currentSurahNumber = surahNumber;
    _ayahs = [];
    _error = '';
    notifyListeners();
    try {
      await _ensureQuranInitialized();

      final startPage = getSurahStartPage(surahNumber);
      final nextStart = surahNumber < 114 ? getSurahStartPage(surahNumber + 1) : 605;
      final endPage = nextStart - 1;

      final result = <AyahModel>[];
      for (int p = startPage; p <= endPage; p++) {
        final pageAyahs = _quran.getPageAyahsByPageNumber(pageNumber: p);
        for (final a in pageAyahs) {
          if (a.surahNumber == surahNumber) {
            result.add(
              AyahModel(
                id: a.ayahUQNumber,
                surahId: a.surahNumber ?? surahNumber,
                ayahNumber: a.ayahNumber,
                text: a.text,
                juzNumber: a.juz,
                hizbNumber: a.hizb ?? 0,
                sajda: a.sajda != null && a.sajda != false,
              ),
            );
          }
        }
      }
      _ayahs = result;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingAyahs = false;
      notifyListeners();
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredSurahs = List.from(_surahs);
    } else {
      _filteredSurahs = _surahs.where((s) {
        return s.arName.contains(query) ||
            s.nameEn.toLowerCase().contains(query.toLowerCase()) ||
            s.number.toString() == query;
      }).toList();
    }
    notifyListeners();
  }

  void increaseFontSize() {
    if (_fontSize < 32) {
      _fontSize += 2;
      notifyListeners();
    }
  }

  void decreaseFontSize() {
    if (_fontSize > 16) {
      _fontSize -= 2;
      notifyListeners();
    }
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('quran_bookmarks');
    if (data != null) {
      _bookmarks = List<Map<String, dynamic>>.from(jsonDecode(data));
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(
      int surahNumber, String surahName, int pageNumber) async {
    final exists = _bookmarks.any((b) => b['surah_number'] == surahNumber);
    if (exists) {
      _bookmarks.removeWhere((b) => b['surah_number'] == surahNumber);
    } else {
      _bookmarks.add({
        'surah_number': surahNumber,
        'surah_name': surahName,
        'page_number': pageNumber,
      });
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quran_bookmarks', jsonEncode(_bookmarks));
    notifyListeners();
  }

  bool isBookmarkedPage(int surahNumber, int pageNumber) {
    return _bookmarks.any((b) =>
        b["surah_number"] == surahNumber && b["page_number"] == pageNumber);
  }

  bool isBookmarked(int surahNumber) {
    return _bookmarks.any((b) => b['surah_number'] == surahNumber);
  }

  int? getBookmarkPage(int surahNumber) {
    try {
      final b = _bookmarks.firstWhere((b) => b['surah_number'] == surahNumber);
      return b['page_number'] as int?;
    } catch (_) {
      return null;
    }
  }

  SurahModel? getSurahByNumber(int number) {
    try {
      return _surahs.firstWhere((s) => s.number == number);
    } catch (_) {
      return null;
    }
  }

  int getSurahStartPage(int surahNumber) {
    const pages = [
      1,   2,   50,  77,  106, 128, 151, 177, 187, 208,
      221, 235, 249, 255, 262, 267, 282, 293, 305, 312,
      322, 332, 342, 350, 359, 367, 377, 385, 396, 404,
      411, 415, 418, 428, 434, 440, 446, 453, 458, 467,
      477, 483, 489, 496, 499, 502, 507, 511, 515, 518,
      520, 523, 526, 528, 531, 534, 537, 542, 545, 549,
      551, 553, 554, 556, 558, 560, 562, 564, 566, 568,
      570, 572, 574, 575, 577, 578, 580, 582, 583, 585,
      586, 587, 587, 589, 590, 591, 591, 592, 593, 594,
      595, 595, 596, 596, 597, 598, 598, 599, 599, 600,
      600, 601, 601, 602, 602, 602, 603, 603, 604, 604,
      604, 604, 604, 604,
    ];
    if (surahNumber >= 1 && surahNumber <= pages.length) {
      return pages[surahNumber - 1];
    }
    return 604;
  }

  String _plainSurahName(int surahNumber) {
    if (surahNumber < 1 || surahNumber > kPlainSurahNames.length) {
      return '';
    }
    return kPlainSurahNames[surahNumber - 1];
  }

  String _normalizeRevelationType(String type) {
    final t = type.trim();
    if (t == 'Meccan' || t == 'Medinan') return t;
    if (t.contains('مك')) return 'Meccan';
    if (t.contains('مد')) return 'Medinan';
    return 'Meccan';
  }

  List<SurahModel> _buildFallbackSurahs() {
    return kLocalSurahData.map((e) {
      return SurahModel(
        id: e['number'] as int,
        number: e['number'] as int,
        arName: e['arName'] as String,
        nameEn: e['nameEn'] as String,
        type: e['type'] as String,
        ayatCount: e['ayatCount'] as int,
      );
    }).toList();
  }

}
