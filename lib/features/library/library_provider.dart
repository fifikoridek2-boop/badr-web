import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badr/core/services/api_service.dart';
import 'package:badr/shared/models/reciter_model.dart';
import 'package:badr/shared/services/audio_service.dart';

class LibraryProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final AudioService _audio = AudioService();

  List<ReciterModel> _reciters = [];
  List<ReciterModel> _filteredReciters = [];
  List<ReciterModel> _favorites = [];
  List<ReciterAudioModel> _currentReciterAudios = [];

  // ─── state منفصل للقارئ والراديو ───
  ReciterModel? _currentReciter;
  ReciterAudioModel? _currentAudio;
  String _surahName = '';      // اسم السورة عند تشغيل قارئ
  String _radioName = '';      // اسم الراديو

  bool _isLoadingReciters = false;
  bool _isLoadingAudios = false;
  bool _isPlaying = false;
  bool _isRadio = false;
  String _error = '';

  List<ReciterModel> get reciters => _filteredReciters;
  List<ReciterModel> get favorites => _favorites;
  List<ReciterAudioModel> get currentReciterAudios => _currentReciterAudios;
  ReciterModel? get currentReciter => _isRadio ? null : _currentReciter;
  ReciterAudioModel? get currentAudio => _currentAudio;
  bool get isLoadingReciters => _isLoadingReciters;
  bool get isLoadingAudios => _isLoadingAudios;
  bool get isPlaying => _isPlaying;
  bool get isRadio => _isRadio;
  String get error => _error;
  AudioService get audioService => _audio;

  // اسم الشيء الحالي المشغّل
  String get currentSurahName => _isRadio ? _radioName : _surahName;

  LibraryProvider() {
    _audio.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    _loadFavorites();
  }

  Future<void> loadReciters() async {
    if (_reciters.isNotEmpty) return;
    _isLoadingReciters = true;
    _error = '';
    notifyListeners();
    try {
      final data = await _api.getReciters();
      final list = (data['reciters'] as List?) ?? [];
      _reciters = list
          .map((e) => ReciterModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _filteredReciters = List.from(_reciters);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingReciters = false;
      notifyListeners();
    }
  }

  Future<void> loadReciterAudios(ReciterModel reciter) async {
    _isLoadingAudios = true;
    _currentReciterAudios = [];
    _error = '';
    notifyListeners();
    try {
      final data = await _api.getReciterAudio(reciter.reciterId);
      final list = (data['audio_urls'] as List?) ?? [];
      _currentReciterAudios = list
          .map((e) => ReciterAudioModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingAudios = false;
      notifyListeners();
    }
  }

  Future<void> playSurah(ReciterModel reciter, ReciterAudioModel audio) async {
    // تشغيل قارئ يلغي الراديو
    _isRadio = false;
    _radioName = '';
    _currentReciter = reciter;
    _currentAudio = audio;
    _surahName = audio.surahNameAr;
    notifyListeners();
    await _audio.play(audio.audioUrl);
  }

  Future<void> playRadio() async {
    // تشغيل راديو يلغي القارئ
    _isRadio = true;
    _surahName = '';
    _currentAudio = null;
    _currentReciter = null;
    _radioName = 'إذاعة القرآن الكريم';
    notifyListeners();
    await _audio.play('https://quran.yousefheiba.com/api/radio');
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _audio.pause();
    } else {
      await _audio.resume();
    }
  }

  Future<void> stop() async {
    await _audio.stop();
    _currentAudio = null;
    _surahName = '';
    _radioName = '';
    _isRadio = false;
    notifyListeners();
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredReciters = List.from(_reciters);
    } else {
      _filteredReciters = _reciters.where((r) {
        return r.reciterName.contains(query) ||
            r.reciterShortName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  bool isCurrentlyPlaying(String audioUrl) {
    return _audio.currentUrl == audioUrl && _isPlaying && !_isRadio;
  }

  // ═══════════════════════════════════════
  //  المفضلون
  // ═══════════════════════════════════════
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('favorite_reciters');
    if (data != null) {
      final list = jsonDecode(data) as List;
      _favorites = list
          .map((e) => ReciterModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(ReciterModel reciter) async {
    final exists = _favorites.any((r) => r.reciterId == reciter.reciterId);
    if (exists) {
      _favorites.removeWhere((r) => r.reciterId == reciter.reciterId);
    } else {
      _favorites.add(reciter);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'favorite_reciters',
      jsonEncode(_favorites.map((r) => {
        'reciter_id': r.reciterId,
        'reciter_name': r.reciterName,
        'reciter_short_name': r.reciterShortName,
      }).toList()),
    );
    notifyListeners();
  }

  bool isFavorite(String reciterId) {
    return _favorites.any((r) => r.reciterId == reciterId);
  }
}
