import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static Database? _db;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'badr_cache.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE json_cache (
            key   TEXT PRIMARY KEY,
            data  TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ─── JSON Cache (Azkar / Duas / etc.) ───────────────────────────────────

  Future<String?> getCachedJson(String key) async {
    final database = await db;
    final rows = await database.query(
      'json_cache',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['data'] as String;
  }

  Future<void> cacheJson(String key, String jsonData) async {
    final database = await db;
    await database.insert(
      'json_cache',
      {
        'key': key,
        'data': jsonData,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearCachedJson(String key) async {
    final database = await db;
    await database.delete('json_cache', where: 'key = ?', whereArgs: [key]);
  }

  // ─── Audio File Cache ────────────────────────────────────────────────────

  Future<Directory> get _audioCacheDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'badr_audio'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _urlToFilename(String url) {
    final segment = Uri.parse(url).pathSegments.last;
    return segment.replaceAll(RegExp(r'[^\w.]'), '_');
  }

  Future<String?> getCachedAudioPath(String url) async {
    final dir = await _audioCacheDir;
    final file = File(p.join(dir.path, _urlToFilename(url)));
    return (await file.exists()) ? file.path : null;
  }

  Future<String> downloadAndCacheAudio(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await _audioCacheDir;
    final file = File(p.join(dir.path, _urlToFilename(url)));
    if (await file.exists()) return file.path;
    await _dio.download(url, file.path, onReceiveProgress: onProgress);
    return file.path;
  }

  Future<bool> isAudioCached(String url) async {
    return (await getCachedAudioPath(url)) != null;
  }

  Future<void> deleteAudioFile(String url) async {
    final path = await getCachedAudioPath(url);
    if (path != null) await File(path).delete();
  }

  Future<void> clearAllAudio() async {
    final dir = await _audioCacheDir;
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Returns total size of cached audio in bytes
  Future<int> audioCacheSizeBytes() async {
    final dir = await _audioCacheDir;
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Human-readable size string
  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
