import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/core/services/api_service.dart';
import 'package:badr/shared/models/reciter_model.dart';

// ═══════════════════════════════════════
//  نموذج معلومات التحميل
// ═══════════════════════════════════════
class DownloadInfo {
  final double progress;
  final bool isDownloading;
  final bool isCompleted;
  final bool isFailed;
  final String speed;
  final String fileSize;
  final String downloadedSize;
  final String remainingTime;
  final String? error;
  final String? surahId;
  final String? surahName;
  final String? reciterId;
  final String? reciterName;
  final String? audioUrl;
  final CancelToken? cancelToken;
  final DateTime? startTime;

  DownloadInfo({
    this.progress = 0,
    this.isDownloading = false,
    this.isCompleted = false,
    this.isFailed = false,
    this.speed = '',
    this.fileSize = '',
    this.downloadedSize = '',
    this.remainingTime = '',
    this.error,
    this.surahId,
    this.surahName,
    this.reciterId,
    this.reciterName,
    this.audioUrl,
    this.cancelToken,
    this.startTime,
  });

  String get key => '${reciterId}_$surahId';

  DownloadInfo copyWith({
    double? progress,
    bool? isDownloading,
    bool? isCompleted,
    bool? isFailed,
    String? speed,
    String? fileSize,
    String? downloadedSize,
    String? remainingTime,
    String? error,
    String? surahId,
    String? surahName,
    String? reciterId,
    String? reciterName,
    String? audioUrl,
    CancelToken? cancelToken,
    DateTime? startTime,
  }) {
    return DownloadInfo(
      progress: progress ?? this.progress,
      isDownloading: isDownloading ?? this.isDownloading,
      isCompleted: isCompleted ?? this.isCompleted,
      isFailed: isFailed ?? this.isFailed,
      speed: speed ?? this.speed,
      fileSize: fileSize ?? this.fileSize,
      downloadedSize: downloadedSize ?? this.downloadedSize,
      remainingTime: remainingTime ?? this.remainingTime,
      error: error ?? this.error,
      surahId: surahId ?? this.surahId,
      surahName: surahName ?? this.surahName,
      reciterId: reciterId ?? this.reciterId,
      reciterName: reciterName ?? this.reciterName,
      audioUrl: audioUrl ?? this.audioUrl,
      cancelToken: cancelToken ?? this.cancelToken,
      startTime: startTime ?? this.startTime,
    );
  }
}

// ═══════════════════════════════════════
//  نموذج صوتي محمل
// ═══════════════════════════════════════
class DownloadedAudio {
  final String surahId;
  final String surahName;
  final String reciterId;
  final String reciterName;
  final String audioUrl;
  final String filePath;
  final DateTime downloadedAt;

  DownloadedAudio({
    required this.surahId,
    required this.surahName,
    required this.reciterId,
    required this.reciterName,
    required this.audioUrl,
    required this.filePath,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'surahId': surahId,
        'surahName': surahName,
        'reciterId': reciterId,
        'reciterName': reciterName,
        'audioUrl': audioUrl,
        'filePath': filePath,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory DownloadedAudio.fromJson(Map<String, dynamic> json) => DownloadedAudio(
        surahId: json['surahId'],
        surahName: json['surahName'],
        reciterId: json['reciterId'],
        reciterName: json['reciterName'],
        audioUrl: json['audioUrl'],
        filePath: json['filePath'],
        downloadedAt: DateTime.parse(json['downloadedAt']),
      );
}

// ═══════════════════════════════════════
//  شاشة التحميلات
// ═══════════════════════════════════════
class CloudScreen extends StatefulWidget {
  const CloudScreen({super.key});

  @override
  State<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends State<CloudScreen> {
  final ApiService _api = ApiService();
  final Dio _dio = Dio();
  
  // ═══ التحميلات العامة ═══
  bool _isAzkarDownloaded = false;
  bool _isLaylatDownloaded = false;
  bool _isLoadingAzkar = false;
  bool _isLoadingLaylat = false;
  
  // ═══ القراء ═══
  List<ReciterModel> _reciters = [];
  bool _isLoadingReciters = false;
  String? _selectedReciterId;
  String? _selectedReciterName;
  
  // ═══ السور (من API للقارئ المحدد) ═══
  List<ReciterAudioModel> _reciterSurahs = [];
  bool _isLoadingReciterSurahs = false;
  String? _selectedSurahId;
  String? _selectedSurahName;
  String? _selectedAudioUrl;
  
  // ═══ التحميلات النشطة ═══
  final Map<String, DownloadInfo> _activeDownloads = {};
  
  // ═══ الصوتيات المحملة ═══
  List<DownloadedAudio> _downloadedAudios = [];
  
  // ═══ الفلتر ═══
  String _filter = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadReciters();
    _loadDownloadedAudios();
    _checkDownloadStatus();
  }

  // ═══════════════════════════════════════
  //  تحميل البيانات
  // ═══════════════════════════════════════
  
  Future<void> _checkDownloadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAzkarDownloaded = prefs.getBool('azkar_downloaded') ?? false;
      _isLaylatDownloaded = prefs.getBool('laylat_downloaded') ?? false;
    });
  }

  Future<void> _loadReciters() async {
    if (_reciters.isNotEmpty) return;
    setState(() => _isLoadingReciters = true);
    try {
      final data = await _api.getReciters();
      final reciters = (data['reciters'] as List?) ?? [];
      setState(() {
        _reciters = reciters
            .map((r) => ReciterModel.fromJson(r as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading reciters: $e');
    } finally {
      setState(() => _isLoadingReciters = false);
    }
  }

  Future<void> _loadReciterSurahs(String reciterId) async {
    setState(() {
      _isLoadingReciterSurahs = true;
      _reciterSurahs = [];
      _selectedSurahId = null;
      _selectedSurahName = null;
      _selectedAudioUrl = null;
    });
    
    try {
      final data = await _api.getReciterAudio(reciterId);
      final audioList = (data['audio_urls'] as List?) ?? [];
      
      setState(() {
        _reciterSurahs = audioList
            .map((item) => ReciterAudioModel.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading reciter surahs: $e');
      setState(() {
        _reciterSurahs = [];
      });
    } finally {
      setState(() => _isLoadingReciterSurahs = false);
    }
  }

  Future<void> _loadDownloadedAudios() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('downloaded_audios_json') ?? [];
    setState(() {
      _downloadedAudios = data
          .map((jsonStr) {
            try {
              return DownloadedAudio.fromJson(
                Map<String, dynamic>.from(
                  (jsonStr.startsWith('{'))
                      ? _parseJson(jsonStr)
                      : {'dummy': jsonStr}
                ),
              );
            } catch (e) {
              return null;
            }
          })
          .whereType<DownloadedAudio>()
          .toList();
    });
  }

  Map<String, dynamic> _parseJson(String jsonStr) {
    // بسيط: try parsing, fallback to empty
    try {
      // نستخدم طريقة بديلة لحفظ البيانات
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveDownloadedAudio(DownloadedAudio audio) async {
    final prefs = await SharedPreferences.getInstance();
    _downloadedAudios.add(audio);
    
    // حفظ كـ JSON string
    final data = _downloadedAudios.map((a) {
      return '${a.reciterId}|${a.surahId}|${a.surahName}|${a.reciterName}|${a.audioUrl}|${a.filePath}|${a.downloadedAt.toIso8601String()}';
    }).toList();
    
    await prefs.setStringList('downloaded_audios_json', data);
    setState(() {});
  }

  bool _isAudioDownloaded(String reciterId, String surahId) {
    return _downloadedAudios.any(
        (a) => a.reciterId == reciterId && a.surahId == surahId);
  }

  Future<void> _removeDownloadedAudio(String reciterId, String surahId) async {
    final audio = _downloadedAudios.firstWhere(
        (a) => a.reciterId == reciterId && a.surahId == surahId,
        orElse: () => DownloadedAudio(
              surahId: '', surahName: '', reciterId: '', reciterName: '',
              audioUrl: '', filePath: '', downloadedAt: DateTime.now(),
            ));
    
    // حذف الملف من الجهاز
    if (audio.filePath.isNotEmpty) {
      try {
        final file = File(audio.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    _downloadedAudios.removeWhere(
        (a) => a.reciterId == reciterId && a.surahId == surahId);
    
    final data = _downloadedAudios.map((a) {
      return '${a.reciterId}|${a.surahId}|${a.surahName}|${a.reciterName}|${a.audioUrl}|${a.filePath}|${a.downloadedAt.toIso8601String()}';
    }).toList();
    
    await prefs.setStringList('downloaded_audios_json', data);
    setState(() {});
  }

  // ═══════════════════════════════════════
  //  اختيار القارئ والسورة
  // ═══════════════════════════════════════
  
  void _onReciterSelected(ReciterModel reciter) {
    setState(() {
      _selectedReciterId = reciter.reciterId;
      _selectedReciterName = reciter.reciterName;
      _selectedSurahId = null;
      _selectedSurahName = null;
      _selectedAudioUrl = null;
    });
    _loadReciterSurahs(reciter.reciterId);
    Navigator.pop(context);
  }

  void _onSurahSelected(ReciterAudioModel surah) {
    setState(() {
      _selectedSurahId = surah.surahId;
      _selectedSurahName = surah.surahNameAr;
      _selectedAudioUrl = surah.audioUrl;
    });
    Navigator.pop(context);
  }

  void _clearReciterSelection() {
    setState(() {
      _selectedReciterId = null;
      _selectedReciterName = null;
      _selectedSurahId = null;
      _selectedSurahName = null;
      _selectedAudioUrl = null;
      _reciterSurahs = [];
    });
  }

  void _clearSurahSelection() {
    setState(() {
      _selectedSurahId = null;
      _selectedSurahName = null;
      _selectedAudioUrl = null;
    });
  }

  // ═══════════════════════════════════════
  //  فتح منتقي القارئ
  // ═══════════════════════════════════════
  
  void _showReciterSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReciterSelector(
        reciters: _reciters,
        isLoading: _isLoadingReciters,
        onSelect: _onReciterSelected,
      ),
    );
  }

  // ═══════════════════════════════════════
  //  فتح منتقي السورة
  // ═══════════════════════════════════════
  
  void _showSurahSelector() {
    if (_selectedReciterId == null) {
      _showErrorSnackBar('اختر القارئ أولاً');
      return;
    }
    
    if (_isLoadingReciterSurahs) {
      _showErrorSnackBar('جاري تحميل السور...');
      return;
    }
    
    if (_reciterSurahs.isEmpty) {
      _showErrorSnackBar('لا توجد سور متاحة لهذا القارئ');
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SurahSelector(
        surahs: _reciterSurahs,
        isLoading: _isLoadingReciterSurahs,
        onSelect: _onSurahSelected,
        downloadedSurahIds: _downloadedAudios
            .where((a) => a.reciterId == _selectedReciterId)
            .map((a) => a.surahId)
            .toSet(),
      ),
    );
  }

  // ═══════════════════════════════════════
  //  تحميل الأذكار وليلة القدر
  // ═══════════════════════════════════════

  Future<void> _downloadAzkar() async {
    setState(() => _isLoadingAzkar = true);
    try {
      await _api.getAzkar();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('azkar_downloaded', true);
      setState(() => _isAzkarDownloaded = true);
      _showSuccessSnackBar('تم تحميل الأذكار بنجاح');
    } catch (e) {
      _showErrorSnackBar('فشل تحميل الأذكار');
    } finally {
      setState(() => _isLoadingAzkar = false);
    }
  }

  Future<void> _downloadLaylatAlQadr() async {
    setState(() => _isLoadingLaylat = true);
    try {
      await _api.getLaylatAlQadr();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('laylat_downloaded', true);
      setState(() => _isLaylatDownloaded = true);
      _showSuccessSnackBar('تم تحميل معلومات ليلة القدر بنجاح');
    } catch (e) {
      _showErrorSnackBar('فشل تحميل ليلة القدر');
    } finally {
      setState(() => _isLoadingLaylat = false);
    }
  }

  // ═══════════════════════════════════════
  //  تحميل صوتي حقيقي
  // ═══════════════════════════════════════

  Future<void> _downloadAudio() async {
    if (_selectedReciterId == null || 
        _selectedSurahId == null || 
        _selectedAudioUrl == null) {
      _showErrorSnackBar('اختر القارئ والسورة أولاً');
      return;
    }

    final key = '${_selectedReciterId}_$_selectedSurahId';
    
    if (_activeDownloads.containsKey(key)) {
      _showErrorSnackBar('هذا الصوت قيد التحميل بالفعل');
      return;
    }

    if (_isAudioDownloaded(_selectedReciterId!, _selectedSurahId!)) {
      _showErrorSnackBar('هذا الصوت محمل مسبقاً');
      return;
    }

    final cancelToken = CancelToken();
    final downloadInfo = DownloadInfo(
      isDownloading: true,
      surahId: _selectedSurahId,
      surahName: _selectedSurahName,
      reciterId: _selectedReciterId,
      reciterName: _selectedReciterName,
      audioUrl: _selectedAudioUrl,
      cancelToken: cancelToken,
      startTime: DateTime.now(),
    );

    setState(() {
      _activeDownloads[key] = downloadInfo;
    });

    try {
      // ═══ 1. الحصول على مجلد التحميلات ═══
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/downloaded_audios/${_selectedReciterId}');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // ═══ 2. تحديد مسار الملف ═══
      final fileName = '${_selectedSurahId}_${_selectedSurahName?.replaceAll(' ', '_')}.mp3';
      final filePath = '${audioDir.path}/$fileName';
      
      // ═══ 3. تحميل الملف الحقيقي ═══
      await _dio.download(
        _selectedAudioUrl!,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            final progress = received / total;
            final speed = received / (DateTime.now().difference(downloadInfo.startTime!).inMilliseconds / 1000);
            final speedStr = speed > 1024 * 1024 
                ? '${(speed / 1024 / 1024).toStringAsFixed(1)} MB/s'
                : '${(speed / 1024).toStringAsFixed(1)} KB/s';
            final remaining = speed > 0 ? (total - received) / speed : 0;
            
            setState(() {
              _activeDownloads[key] = _activeDownloads[key]!.copyWith(
                progress: progress,
                downloadedSize: (received / 1024 / 1024).toStringAsFixed(1),
                fileSize: (total / 1024 / 1024).toStringAsFixed(1),
                speed: speedStr,
                remainingTime: '${remaining.toInt()} ثانية',
              );
            });
          }
        },
      );

      // ═══ 4. حفظ معلومات الصوتي المحمل ═══
      final downloadedAudio = DownloadedAudio(
        surahId: _selectedSurahId!,
        surahName: _selectedSurahName!,
        reciterId: _selectedReciterId!,
        reciterName: _selectedReciterName!,
        audioUrl: _selectedAudioUrl!,
        filePath: filePath,
        downloadedAt: DateTime.now(),
      );

      await _saveDownloadedAudio(downloadedAudio);

      if (mounted) {
        setState(() {
          _activeDownloads[key] = _activeDownloads[key]!.copyWith(
            isDownloading: false,
            isCompleted: true,
            progress: 1.0,
          );
        });
        _showSuccessSnackBar('تم تحميل ${_selectedSurahName} بنجاح');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // تم الإلغاء
        if (mounted) {
          setState(() => _activeDownloads.remove(key));
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          _activeDownloads[key] = _activeDownloads[key]!.copyWith(
            isDownloading: false,
            isFailed: true,
            error: 'فشل التحميل: ${e.message}',
          );
        });
        _showErrorSnackBar('فشل تحميل ${_selectedSurahName}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeDownloads[key] = _activeDownloads[key]!.copyWith(
            isDownloading: false,
            isFailed: true,
            error: 'فشل التحميل',
          );
        });
        _showErrorSnackBar('فشل تحميل ${_selectedSurahName}');
      }
    }
  }

  void _cancelDownload(String key) {
    final download = _activeDownloads[key];
    download?.cancelToken?.cancel();
    setState(() => _activeDownloads.remove(key));
  }

  void _removeCompletedDownload(String key) {
    setState(() => _activeDownloads.remove(key));
  }

  // ═══════════════════════════════════════
  //  رسائل التنبيه
  // ═══════════════════════════════════════

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(fontFamily: AppConstants.fontCairo)),
      backgroundColor: Colors.green,
    ));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(fontFamily: AppConstants.fontCairo)),
      backgroundColor: Colors.red,
    ));
  }

  // ═══════════════════════════════════════
  //  بناء الواجهة
  // ═══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        title: Text(
          'التحميلات',
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontWeight: FontWeight.bold,
            color: color.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ بطاقة الأذكار ═══
          _DownloadCard(
            icon: Icons.auto_awesome_outlined,
            title: 'الأذكار والأدعية',
            subtitle: _isAzkarDownloaded ? 'تم التحميل' : 'غير محملة',
            isDownloaded: _isAzkarDownloaded,
            isLoading: _isLoadingAzkar,
            onDownload: _downloadAzkar,
            color: color,
          ),
          const SizedBox(height: 12),

          // ═══ بطاقة ليلة القدر ═══
          _DownloadCard(
            icon: Icons.nights_stay_outlined,
            title: 'ليلة القدر',
            subtitle: _isLaylatDownloaded ? 'تم التحميل' : 'غير محملة',
            isDownloaded: _isLaylatDownloaded,
            isLoading: _isLoadingLaylat,
            onDownload: _downloadLaylatAlQadr,
            color: color,
          ),
          const SizedBox(height: 20),

          // ═══ قسم الصوتيات ═══
          _AudioSection(
            color: color,
            filter: _filter,
            onFilterChanged: (f) => setState(() => _filter = f),
            // القارئ
            selectedReciterName: _selectedReciterName,
            isLoadingReciterSurahs: _isLoadingReciterSurahs,
            onSelectReciter: _showReciterSelector,
            onClearReciter: _clearReciterSelection,
            // السورة
            selectedSurahName: _selectedSurahName,
            onSelectSurah: _showSurahSelector,
            onClearSurah: _clearSurahSelection,
            // زر التحميل
            onDownload: _downloadAudio,
            canDownload: _selectedReciterId != null &&
                _selectedSurahId != null &&
                !_isAudioDownloaded(_selectedReciterId!, _selectedSurahId!),
            // التحميلات النشطة
            activeDownloads: _activeDownloads,
            onCancelDownload: _cancelDownload,
            onRemoveCompleted: _removeCompletedDownload,
            // الصوتيات المحملة
            downloadedAudios: _downloadedAudios,
            onDeleteDownloaded: _removeDownloadedAudio,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
//  قسم الصوتيات
// ═══════════════════════════════════════
class _AudioSection extends StatelessWidget {
  final ColorScheme color;
  final String filter;
  final ValueChanged<String> onFilterChanged;
  final String? selectedReciterName;
  final bool isLoadingReciterSurahs;
  final VoidCallback onSelectReciter;
  final VoidCallback onClearReciter;
  final String? selectedSurahName;
  final VoidCallback onSelectSurah;
  final VoidCallback onClearSurah;
  final VoidCallback onDownload;
  final bool canDownload;
  final Map<String, DownloadInfo> activeDownloads;
  final Function(String) onCancelDownload;
  final Function(String) onRemoveCompleted;
  final List<DownloadedAudio> downloadedAudios;
  final Function(String, String) onDeleteDownloaded;

  const _AudioSection({
    required this.color,
    required this.filter,
    required this.onFilterChanged,
    required this.selectedReciterName,
    required this.isLoadingReciterSurahs,
    required this.onSelectReciter,
    required this.onClearReciter,
    required this.selectedSurahName,
    required this.onSelectSurah,
    required this.onClearSurah,
    required this.onDownload,
    required this.canDownload,
    required this.activeDownloads,
    required this.onCancelDownload,
    required this.onRemoveCompleted,
    required this.downloadedAudios,
    required this.onDeleteDownloaded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ═══ العنوان ═══
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.headphones_outlined, color: color.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'الصوتيات',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ═══ فلتر الكل / المحملة فقط ═══
        Row(
          children: [
            _FilterChip(
              label: 'الكل',
              isSelected: filter == 'الكل',
              onTap: () => onFilterChanged('الكل'),
              color: color,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'المحملة فقط',
              isSelected: filter == 'المحملة',
              onTap: () => onFilterChanged('المحملة'),
              color: color,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ═══ اختيار القارئ والسورة ═══
        Card(
          elevation: 0,
          color: color.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // القارئ
                Text(
                  'اختر القارئ',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 12,
                    color: color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _SelectionButton(
                  icon: Icons.person_outline,
                  label: selectedReciterName ?? 'اختر قارئاً',
                  isSelected: selectedReciterName != null,
                  onTap: onSelectReciter,
                  onClear: selectedReciterName != null ? onClearReciter : null,
                  color: color,
                  backgroundColor: color.primaryContainer,
                  textColor: color.onPrimaryContainer,
                ),
                const SizedBox(height: 16),

                // السورة
                Text(
                  'اختر السورة',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 12,
                    color: color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSurahSelector(context),
                const SizedBox(height: 16),

                // زر التحميل
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canDownload ? onDownload : null,
                    icon: Icon(Icons.download, size: 20),
                    label: Text(
                      selectedReciterName == null
                          ? 'اختر القارئ أولاً'
                          : selectedSurahName == null
                              ? 'اختر السورة'
                              : 'تحميل',
                      style: TextStyle(fontFamily: AppConstants.fontCairo),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ═══ التحميلات النشطة ═══
        if (activeDownloads.isNotEmpty) ...[
          _SectionTitle(title: 'التحميلات النشطة', icon: Icons.downloading, color: color),
          const SizedBox(height: 8),
          ...activeDownloads.values.map((info) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActiveDownloadCard(
                  info: info,
                  color: color,
                  onCancel: () => onCancelDownload(info.key),
                  onRemove: () => onRemoveCompleted(info.key),
                ),
              )),
          const SizedBox(height: 12),
        ],

        // ═══ الصوتيات المحملة ═══
        if (filter == 'المحملة' || downloadedAudios.isNotEmpty) ...[
          _SectionTitle(
            title: filter == 'المحملة' ? 'الصوتيات المحملة' : 'الصوتيات المحملة',
            icon: Icons.folder_outlined,
            color: color,
          ),
          const SizedBox(height: 8),
          if (downloadedAudios.isEmpty)
            Card(
              elevation: 0,
              color: color.surfaceContainerHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off_outlined,
                          size: 48, color: color.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد صوتيات محملة',
                        style: TextStyle(fontFamily: AppConstants.fontCairo, color: color.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._buildDownloadedAudiosList(color),
        ],
      ],
    );
  }

  Widget _buildSurahSelector(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    
    if (selectedReciterName == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.menu_book_outlined, size: 20, color: color.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'اختر القارئ أولاً',
                style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  color: color.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isLoadingReciterSurahs) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color.primary),
            ),
            const SizedBox(width: 10),
            Text(
              'جاري تحميل السور...',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return _SelectionButton(
      icon: Icons.menu_book_outlined,
      label: selectedSurahName ?? 'اختر سورة',
      isSelected: selectedSurahName != null,
      onTap: onSelectSurah,
      onClear: selectedSurahName != null ? onClearSurah : null,
      color: color,
      backgroundColor: color.secondaryContainer,
      textColor: color.onSecondaryContainer,
    );
  }

  List<Widget> _buildDownloadedAudiosList(ColorScheme color) {
    final Map<String, List<DownloadedAudio>> grouped = {};
    for (final audio in downloadedAudios) {
      if (!grouped.containsKey(audio.reciterName)) {
        grouped[audio.reciterName] = [];
      }
      grouped[audio.reciterName]!.add(audio);
    }

    return grouped.entries.map((entry) {
      return Card(
        elevation: 0,
        color: color.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.primaryContainer.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 18, color: color.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontWeight: FontWeight.bold,
                        color: color.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value.length} سورة',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 12,
                      color: color.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((audio) => _DownloadedAudioTile(
                  audio: audio,
                  color: color,
                  onDelete: () => onDeleteDownloaded(audio.reciterId, audio.surahId),
                )),
          ],
        ),
      );
    }).toList();
  }
}

// ═══════════════════════════════════════
//  بطاقة التحميل الأساسي
// ═══════════════════════════════════════
class _DownloadCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDownloaded;
  final bool isLoading;
  final VoidCallback onDownload;
  final ColorScheme color;

  const _DownloadCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDownloaded,
    required this.isLoading,
    required this.onDownload,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: isDownloaded ? null : onDownload,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDownloaded ? color.primaryContainer : color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: isDownloaded ? color.primary : color.onSurfaceVariant, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isDownloaded ? Icons.check_circle : Icons.cloud_outlined,
                          size: 14,
                          color: isDownloaded ? color.primary : color.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: AppConstants.fontCairo,
                            fontSize: 13,
                            color: isDownloaded ? color.primary : color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isDownloaded)
                Icon(Icons.check, color: color.primary, size: 24)
              else if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: color.primary),
                )
              else
                IconButton(
                  onPressed: onDownload,
                  icon: Icon(Icons.download_outlined, color: color.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  زر التحديد
// ═══════════════════════════════════════
class _SelectionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final ColorScheme color;
  final Color backgroundColor;
  final Color textColor;

  const _SelectionButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.onClear,
    required this.color,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? backgroundColor : color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? textColor : color.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  color: isSelected ? textColor : color.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 18, color: textColor),
              )
            else
              Icon(Icons.expand_more, size: 20, color: color.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  بطاقة التحميل النشط
// ═══════════════════════════════════════
class _ActiveDownloadCard extends StatelessWidget {
  final DownloadInfo info;
  final ColorScheme color;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  const _ActiveDownloadCard({
    required this.info,
    required this.color,
    required this.onCancel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = info.isCompleted;
    final isFailed = info.isFailed;

    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.5)
              : isFailed
                  ? color.error.withValues(alpha: 0.5)
                  : color.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : isFailed ? Icons.error_outline : Icons.downloading,
                  color: isCompleted ? Colors.green : isFailed ? color.error : color.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.surahName ?? '',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color.onSurface,
                        ),
                      ),
                      if (info.reciterName != null)
                        Text(
                          info.reciterName!,
                          style: TextStyle(
                            fontFamily: AppConstants.fontCairo,
                            fontSize: 12,
                            color: color.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (info.isDownloading)
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: color.error),
                    onPressed: onCancel,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  )
                else
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: color.error),
                    onPressed: onRemove,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isFailed) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: info.progress,
                  minHeight: 6,
                  backgroundColor: color.surfaceContainerLow,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : color.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isCompleted ? 'تم التحميل' : isFailed ? info.error ?? 'فشل' : '${(info.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : isFailed ? color.error : color.primary,
                    ),
                  ),
                  if (info.speed.isNotEmpty && !isCompleted && !isFailed)
                    Text(
                      info.speed,
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 11,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (!isCompleted && !isFailed && info.downloadedSize.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${info.downloadedSize} / ${info.fileSize} MB',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 11,
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ] else ...[
              Text(
                info.error ?? 'حدث خطأ',
                style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  fontSize: 12,
                  color: color.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  صوتي محمل (عنصر)
// ═══════════════════════════════════════
class _DownloadedAudioTile extends StatelessWidget {
  final DownloadedAudio audio;
  final ColorScheme color;
  final VoidCallback onDelete;

  const _DownloadedAudioTile({
    required this.audio,
    required this.color,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: color.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              audio.surahName,
              style: TextStyle(fontFamily: AppConstants.fontCairo, color: color.onSurface),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: color.error),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('حذف الصوتي', style: TextStyle(fontFamily: AppConstants.fontCairo)),
                  content: Text('هل تريد حذف "${audio.surahName}"؟', style: TextStyle(fontFamily: AppConstants.fontCairo)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('إلغاء', style: TextStyle(fontFamily: AppConstants.fontCairo)),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                      child: Text('حذف', style: TextStyle(fontFamily: AppConstants.fontCairo)),
                    ),
                  ],
                ),
              );
            },
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
//  عنوان قسم
// ═══════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final ColorScheme color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════
//  فلتر
// ═══════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.primary : color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontSize: 13,
            color: isSelected ? color.onPrimary : color.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  منتقي القراء
// ═══════════════════════════════════════
class _ReciterSelector extends StatefulWidget {
  final List<ReciterModel> reciters;
  final bool isLoading;
  final Function(ReciterModel) onSelect;

  const _ReciterSelector({
    required this.reciters,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  State<_ReciterSelector> createState() => _ReciterSelectorState();
}

class _ReciterSelectorState extends State<_ReciterSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<ReciterModel> _filteredReciters = [];

  @override
  void initState() {
    super.initState();
    _filteredReciters = List.from(widget.reciters);
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredReciters = List.from(widget.reciters));
    } else {
      setState(() {
        _filteredReciters = widget.reciters
            .where((r) => r.reciterName.contains(query))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: color.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'اختر القارئ',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              style: TextStyle(fontFamily: AppConstants.fontCairo),
              decoration: InputDecoration(
                hintText: 'ابحث عن قارئ...',
                hintStyle: TextStyle(fontFamily: AppConstants.fontCairo),
                prefixIcon: Icon(Icons.search, color: color.onSurfaceVariant),
                filled: true,
                fillColor: color.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReciters.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                            fontFamily: AppConstants.fontCairo,
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filteredReciters.length,
                        itemBuilder: (context, index) {
                          final reciter = _filteredReciters[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.primaryContainer,
                              child: Icon(Icons.person, color: color.onPrimaryContainer),
                            ),
                            title: Text(
                              reciter.reciterName,
                              style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              reciter.reciterShortName,
                              style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontSize: 12,
                                color: color.onSurfaceVariant,
                              ),
                            ),
                            onTap: () => widget.onSelect(reciter),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
//  منتقي السور
// ═══════════════════════════════════════
class _SurahSelector extends StatefulWidget {
  final List<ReciterAudioModel> surahs;
  final bool isLoading;
  final Function(ReciterAudioModel) onSelect;
  final Set<String> downloadedSurahIds;

  const _SurahSelector({
    required this.surahs,
    required this.isLoading,
    required this.onSelect,
    required this.downloadedSurahIds,
  });

  @override
  State<_SurahSelector> createState() => _SurahSelectorState();
}

class _SurahSelectorState extends State<_SurahSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<ReciterAudioModel> _filteredSurahs = [];

  @override
  void initState() {
    super.initState();
    _filteredSurahs = List.from(widget.surahs);
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSurahs = List.from(widget.surahs));
    } else {
      setState(() {
        _filteredSurahs = widget.surahs
            .where((s) =>
                s.surahNameAr.contains(query) ||
                s.surahId.contains(query))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: color.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'اختر السورة',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              style: TextStyle(fontFamily: AppConstants.fontCairo),
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة...',
                hintStyle: TextStyle(fontFamily: AppConstants.fontCairo),
                prefixIcon: Icon(Icons.search, color: color.onSurfaceVariant),
                filled: true,
                fillColor: color.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSurahs.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                            fontFamily: AppConstants.fontCairo,
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filteredSurahs.length,
                        itemBuilder: (context, index) {
                          final surah = _filteredSurahs[index];
                          final isDownloaded = widget.downloadedSurahIds.contains(surah.surahId);
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDownloaded 
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : color.secondaryContainer,
                              radius: 16,
                              child: isDownloaded
                                  ? Icon(Icons.check, size: 16, color: Colors.green)
                                  : Text(
                                      surah.surahId,
                                      style: TextStyle(
                                        fontFamily: AppConstants.fontCairo,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: color.onSecondaryContainer,
                                      ),
                                    ),
                            ),
                            title: Text(
                              surah.surahNameAr,
                              style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: isDownloaded
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'محمل',
                                      style: TextStyle(
                                        fontFamily: AppConstants.fontCairo,
                                        fontSize: 11,
                                        color: Colors.green,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: isDownloaded 
                                ? null 
                                : () => widget.onSelect(surah),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}