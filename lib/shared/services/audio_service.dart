import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  bool get isPlaying => _player.playing;
  Duration? get duration => _player.duration;
  Duration get position => _player.position;

  String? _currentUrl;
  String? get currentUrl => _currentUrl;

  Future<void> play(String url) async {
    try {
      if (_currentUrl == url && _player.playing) return;
      _currentUrl = url;
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {}
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
  }
}
