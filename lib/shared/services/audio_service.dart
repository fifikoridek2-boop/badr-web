import 'package:just_audio/just_audio.dart';
import 'package:badr/core/services/storage_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  final StorageService _storage = StorageService();

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  bool get isPlaying => _player.playing;
  Duration? get duration => _player.duration;
  Duration get position => _player.position;

  String? _currentUrl;
  String? get currentUrl => _currentUrl;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;
  double _downloadProgress = 0;
  double get downloadProgress => _downloadProgress;

  Future<void> play(String url) async {
    try {
      if (_currentUrl == url && _player.playing) return;
      _currentUrl = url;
      await _player.stop();

      // Cache-first: check local file before streaming
      final cachedPath = await _storage.getCachedAudioPath(url);
      if (cachedPath != null) {
        await _player.setFilePath(cachedPath);
      } else {
        await _player.setUrl(url);
      }
      await _player.play();
    } catch (_) {}
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();

  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
  }

  Future<void> seek(Duration position) async => await _player.seek(position);

  /// Download audio file for offline use
  Future<void> downloadAudio(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    if (_isDownloading) return;
    _isDownloading = true;
    _downloadProgress = 0;
    try {
      await _storage.downloadAndCacheAudio(url, onProgress: (recv, total) {
        if (total > 0) {
          _downloadProgress = recv / total;
          onProgress?.call(_downloadProgress);
        }
      });
    } finally {
      _isDownloading = false;
      _downloadProgress = 0;
    }
  }

  Future<bool> isAudioCached(String url) =>
      _storage.isAudioCached(url);

  Future<void> deleteAudioCache(String url) =>
      _storage.deleteAudioFile(url);

  void dispose() => _player.dispose();
}
