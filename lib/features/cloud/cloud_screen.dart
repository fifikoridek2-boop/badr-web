import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/core/services/api_service.dart';

// ═══════════════════════════════════════
//  نموذج معلومات التحميل
// ═══════════════════════════════════════
class DownloadInfo {
  final double progress;
  final bool isDownloading;
  final bool isCompleted;
  final String speed;
  final String fileSize;
  final String downloadedSize;
  final String remainingTime;
  final String? error;
  final String? fileName;
  final String? reciterName;
  final CancelToken? cancelToken;

  DownloadInfo({
    this.progress = 0,
    this.isDownloading = false,
    this.isCompleted = false,
    this.speed = '',
    this.fileSize = '',
    this.downloadedSize = '',
    this.remainingTime = '',
    this.error,
    this.fileName,
    this.reciterName,
    this.cancelToken,
  });

  DownloadInfo copyWith({
    double? progress,
    bool? isDownloading,
    bool? isCompleted,
    String? speed,
    String? fileSize,
    String? downloadedSize,
    String? remainingTime,
    String? error,
    String? fileName,
    String? reciterName,
    CancelToken? cancelToken,
  }) {
    return DownloadInfo(
      progress: progress ?? this.progress,
      isDownloading: isDownloading ?? this.isDownloading,
      isCompleted: isCompleted ?? this.isCompleted,
      speed: speed ?? this.speed,
      fileSize: fileSize ?? this.fileSize,
      downloadedSize: downloadedSize ?? this.downloadedSize,
      remainingTime: remainingTime ?? this.remainingTime,
      error: error ?? this.error,
      fileName: fileName ?? this.fileName,
      reciterName: reciterName ?? this.reciterName,
      cancelToken: cancelToken ?? this.cancelToken,
    );
  }
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
  
  // التحميلات
  bool _isAzkarDownloaded = false;
  bool _isLaylatDownloaded = false;
  final Map<String, DownloadInfo> _audioDownloads = {};
  
  // عناصر التحكم
  bool _isLoadingAzkar = false;
  bool _isLoadingLaylat = false;
  
  // تصفية الصوتيات
  String _audioFilter = 'الكل';
  
  // القراء
  List<Map<String, dynamic>> _reciters = [];
  bool _isLoadingReciters = false;
  String? _selectedReciterId;
  String? _selectedReciterName;
  
  // السور
  List<Map<String, dynamic>> _surahs = [];
  bool _isLoadingSurahs = false;
  String? _selectedSurahId;
  String? _selectedSurahName;
  
  // البحث
  final TextEditingController _reciterSearchController = TextEditingController();
  final TextEditingController _surahSearchController = TextEditingController();
  List<Map<String, dynamic>> _filteredReciters = [];
  List<Map<String, dynamic>> _filteredSurahs = [];
  
  // بوكس التحميل المعروض
  String? _activeDownloadKey;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
    _loadReciters();
    _loadSurahs();
  }

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
        _reciters = reciters.cast<Map<String, dynamic>>();
        _filteredReciters = List.from(_reciters);
      });
    } catch (e) {
      // تجاهل الخطأ
    } finally {
      setState(() => _isLoadingReciters = false);
    }
  }

  Future<void> _loadSurahs() async {
    if (_surahs.isNotEmpty) return;
    setState(() => _isLoadingSurahs = true);
    try {
      final data = await _api.getSurahs();
      final surahs = (data['surahs'] as List?) ?? [];
      setState(() {
        _surahs = surahs.cast<Map<String, dynamic>>();
        _filteredSurahs = List.from(_surahs);
      });
    } catch (e) {
      // تجاهل الخطأ
    } finally {
      setState(() => _isLoadingSurahs = false);
    }
  }

  void _filterReciters(String query) {
    if (query.isEmpty) {
      setState(() => _filteredReciters = List.from(_reciters));
    } else {
      setState(() {
        _filteredReciters = _reciters
            .where((r) => r['reciter_name'].toString().contains(query))
            .toList();
      });
    }
  }

  void _filterSurahs(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSurahs = List.from(_surahs));
    } else {
      setState(() {
        _filteredSurahs = _surahs
            .where((s) =>
                s['name'].toString().contains(query) ||
                s['number'].toString().contains(query))
            .toList();
      });
    }
  }

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

  void _selectReciter(String id, String name) {
    setState(() {
      _selectedReciterId = id;
      _selectedReciterName = name;
      _filteredReciters = [];
    });
    _reciterSearchController.text = name;
  }

  void _selectSurah(String id, String name) {
    setState(() {
      _selectedSurahId = id;
      _selectedSurahName = name;
      _filteredSurahs = [];
    });
    _surahSearchController.text = name;
  }

  void _clearReciterSelection() {
    setState(() {
      _selectedReciterId = null;
      _selectedReciterName = null;
      _filteredReciters = List.from(_reciters);
    });
    _reciterSearchController.clear();
  }

  void _clearSurahSelection() {
    setState(() {
      _selectedSurahId = null;
      _selectedSurahName = null;
      _filteredSurahs = List.from(_surahs);
    });
    _surahSearchController.clear();
  }

  Future<void> _startDownload() async {
    if (_selectedReciterId == null || _selectedSurahId == null) {
      _showErrorSnackBar('اختر القارئ والسورة أولاً');
      return;
    }

    final key = '${_selectedReciterId}_${_selectedSurahId}';
    final cancelToken = CancelToken();
    
    setState(() {
      _activeDownloadKey = key;
      _audioDownloads[key] = DownloadInfo(
        isDownloading: true,
        fileName: _selectedSurahName,
        reciterName: _selectedReciterName,
        cancelToken: cancelToken,
      );
    });

    try {
      // محاكاة التحميل الحقيقي
      double progress = 0;
      while (progress < 1) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (cancelToken.isCancelled) break;
        
        progress += 0.05;
        final downloaded = (progress * 5.2).toStringAsFixed(1);
        final total = '5.2';
        final speed = '${(progress * 2.5).toStringAsFixed(1)} MB/s';
        final remaining = '${((1 - progress) * 2).toStringAsFixed(0)} ثانية';
        
        if (mounted) {
          setState(() {
            _audioDownloads[key] = _audioDownloads[key]!.copyWith(
              progress: progress,
              downloadedSize: downloaded,
              fileSize: total,
              speed: speed,
              remainingTime: remaining,
            );
          });
        }
      }
      
      if (mounted && !cancelToken.isCancelled) {
        setState(() {
          _audioDownloads[key] = _audioDownloads[key]!.copyWith(
            isDownloading: false,
            isCompleted: true,
            progress: 1.0,
          );
        });
        _showSuccessSnackBar('تم تحميل $_selectedSurahName بنجاح');
      }
    } catch (e) {
      setState(() {
        _audioDownloads[key] = _audioDownloads[key]!.copyWith(
          isDownloading: false,
          error: 'فشل التحميل',
        );
      });
      _showErrorSnackBar('فشل تحميل الملف');
    }
  }

  void _cancelDownload(String key) {
    final download = _audioDownloads[key];
    download?.cancelToken?.cancel();
    setState(() {
      _audioDownloads.remove(key);
      if (_activeDownloadKey == key) {
        _activeDownloadKey = null;
      }
    });
  }

  void _showDownloadDialog() {
    if (_selectedReciterId == null || _selectedSurahId == null) {
      _showErrorSnackBar('اختر القارئ والسورة أولاً');
      return;
    }

    final key = '${_selectedReciterId}_${_selectedSurahId}';
    final existingDownload = _audioDownloads[key];
    
    // إذا كان التحميل جاري، اعرض تفاصيله
    if (existingDownload != null && existingDownload.isDownloading) {
      _showDownloadDetailsDialog(key, existingDownload);
      return;
    }
    
    // وإلا، اعرض حوار التأكيد
    _showConfirmDialog(key);
  }

  void _showConfirmDialog(String key) {
    final color = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.download, color: color.primary),
            const SizedBox(width: 8),
            Text(
              'تأكيد التحميل',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'السورة: $_selectedSurahName',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                color: color.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'القارئ: $_selectedReciterName',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                color: color.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'سيتم تحميل الملف على جهازك.',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 13,
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(fontFamily: AppConstants.fontCairo),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startDownload();
            },
            child: Text(
              'تحميل',
              style: TextStyle(fontFamily: AppConstants.fontCairo),
            ),
          ),
        ],
      ),
    );
  }

  void _showDownloadDetailsDialog(String key, DownloadInfo info) {
    final color = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // الاستماع للتحديثات
          final currentInfo = _audioDownloads[key] ?? info;
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  currentInfo.isCompleted ? Icons.check_circle : Icons.downloading,
                  color: currentInfo.isCompleted ? Colors.green : color.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentInfo.isCompleted ? 'تم التحميل' : 'جاري التحميل',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentInfo.fileName != null) ...[
                  Text(
                    'السورة: ${currentInfo.fileName}',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (currentInfo.reciterName != null) ...[
                  Text(
                    'القارئ: ${currentInfo.reciterName}',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // شريط التقدم
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: currentInfo.progress,
                    minHeight: 12,
                    backgroundColor: color.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      currentInfo.isCompleted ? Colors.green : color.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // النسبة المئوية
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(currentInfo.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: currentInfo.isCompleted ? Colors.green : color.primary,
                      ),
                    ),
                    if (currentInfo.speed.isNotEmpty)
                      Text(
                        currentInfo.speed,
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 12,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // الحجم
                Row(
                  children: [
                    Text(
                      'الحجم: ',
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 12,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${currentInfo.downloadedSize} / ${currentInfo.fileSize} MB',
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 12,
                        color: color.onSurface,
                      ),
                    ),
                  ],
                ),
                
                // الوقت المتبقي
                if (currentInfo.remainingTime.isNotEmpty && !currentInfo.isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    'الوقت المتبقي: ${currentInfo.remainingTime}',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 12,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (!currentInfo.isCompleted)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _cancelDownload(key);
                  },
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      color: color.error,
                    ),
                  ),
                ),
              if (currentInfo.isCompleted)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'تم',
                    style: TextStyle(fontFamily: AppConstants.fontCairo),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _reciterSearchController.dispose();
    _surahSearchController.dispose();
    super.dispose();
  }

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
          const SizedBox(height: 12),
          
          // ═══ بطاقة الصوتيات ═══
          _AudioSectionCard(
            color: color,
            filter: _audioFilter,
            onFilterChanged: (f) => setState(() => _audioFilter = f),
            // القراء
            reciters: _filteredReciters,
            isLoadingReciters: _isLoadingReciters,
            selectedReciterId: _selectedReciterId,
            selectedReciterName: _selectedReciterName,
            onReciterSelected: _selectReciter,
            onClearReciter: _clearReciterSelection,
            reciterSearchController: _reciterSearchController,
            onReciterSearchChanged: _filterReciters,
            // السور
            surahs: _filteredSurahs,
            isLoadingSurahs: _isLoadingSurahs,
            selectedSurahId: _selectedSurahId,
            selectedSurahName: _selectedSurahName,
            onSurahSelected: _selectSurah,
            onClearSurah: _clearSurahSelection,
            surahSearchController: _surahSearchController,
            onSurahSearchChanged: _filterSurahs,
            // الأزرار
            onDownload: _showDownloadDialog,
            // التحميلات النشطة
            audioDownloads: _audioDownloads,
            activeDownloadKey: _activeDownloadKey,
            onShowDetails: (key) => _showDownloadDetailsDialog(key, _audioDownloads[key]!),
            onCancel: _cancelDownload,
          ),
          
          const SizedBox(height: 24),
          
          // ═══ مؤشر التحميل العام ═══
          _GlobalProgressCard(
            color: color,
            isAzkarDownloaded: _isAzkarDownloaded,
            isLaylatDownloaded: _isLaylatDownloaded,
            downloadedAudiosCount: _audioDownloads.values.where((d) => d.isCompleted).length,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
//  بطاقة التحميل الأساسية
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDownloaded 
                    ? color.primaryContainer 
                    : color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isDownloaded ? color.primary : color.onSurfaceVariant,
                size: 24,
              ),
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
                      fontSize: 16,
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
              Icon(Icons.check, color: color.primary, size: 28)
            else if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: color.primary,
                ),
              )
            else
              IconButton(
                onPressed: onDownload,
                icon: Icon(Icons.download_outlined, color: color.primary),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  قسم الصوتيات
// ═══════════════════════════════════════
class _AudioSectionCard extends StatelessWidget {
  final ColorScheme color;
  final String filter;
  final ValueChanged<String> onFilterChanged;
  // القراء
  final List<Map<String, dynamic>> reciters;
  final bool isLoadingReciters;
  final String? selectedReciterId;
  final String? selectedReciterName;
  final Function(String, String) onReciterSelected;
  final VoidCallback onClearReciter;
  final TextEditingController reciterSearchController;
  final ValueChanged<String> onReciterSearchChanged;
  // السور
  final List<Map<String, dynamic>> surahs;
  final bool isLoadingSurahs;
  final String? selectedSurahId;
  final String? selectedSurahName;
  final Function(String, String) onSurahSelected;
  final VoidCallback onClearSurah;
  final TextEditingController surahSearchController;
  final ValueChanged<String> onSurahSearchChanged;
  // الأزرار
  final VoidCallback onDownload;
  // التحميلات
  final Map<String, DownloadInfo> audioDownloads;
  final String? activeDownloadKey;
  final Function(String) onShowDetails;
  final Function(String) onCancel;

  const _AudioSectionCard({
    required this.color,
    required this.filter,
    required this.onFilterChanged,
    required this.reciters,
    required this.isLoadingReciters,
    required this.selectedReciterId,
    required this.selectedReciterName,
    required this.onReciterSelected,
    required this.onClearReciter,
    required this.reciterSearchController,
    required this.onReciterSearchChanged,
    required this.surahs,
    required this.isLoadingSurahs,
    required this.selectedSurahId,
    required this.selectedSurahName,
    required this.onSurahSelected,
    required this.onClearSurah,
    required this.surahSearchController,
    required this.onSurahSearchChanged,
    required this.onDownload,
    required this.audioDownloads,
    required this.activeDownloadKey,
    required this.onShowDetails,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
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
            
            // فلتر الكل / المحملة فقط
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
            
            // ═══ قسم القراء ═══
            Text(
              'اختر القارئ',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 13,
                color: color.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            
            if (selectedReciterName != null)
              _SelectedItem(
                icon: Icons.person,
                label: selectedReciterName!,
                backgroundColor: color.primaryContainer,
                textColor: color.onPrimaryContainer,
                onClear: onClearReciter,
              )
            else if (isLoadingReciters)
              _LoadingIndicator()
            else
              _DropdownList(
                items: reciters,
                searchController: reciterSearchController,
                onSearchChanged: onReciterSearchChanged,
                onItemSelected: (item) => onReciterSelected(
                  item['reciter_id'].toString(),
                  item['reciter_name'].toString(),
                ),
                itemBuilder: (item) => item['reciter_name'].toString(),
                color: color,
              ),
            
            const SizedBox(height: 16),
            
            // ═══ قسم السور ═══
            Text(
              'اختر السورة',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 13,
                color: color.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            
            if (selectedSurahName != null)
              _SelectedItem(
                icon: Icons.menu_book,
                label: selectedSurahName!,
                backgroundColor: color.secondaryContainer,
                textColor: color.onSecondaryContainer,
                onClear: onClearSurah,
              )
            else if (isLoadingSurahs)
              _LoadingIndicator()
            else
              _DropdownList(
                items: surahs,
                searchController: surahSearchController,
                onSearchChanged: onSurahSearchChanged,
                onItemSelected: (item) => onSurahSelected(
                  item['number'].toString(),
                  item['name'].toString(),
                ),
                itemBuilder: (item) => '${item['number']}. ${item['name']}',
                color: color,
              ),
            
            const SizedBox(height: 16),
            
            // ═══ زر التحميل ═══
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: selectedReciterId != null && selectedSurahId != null
                    ? onDownload
                    : null,
                icon: Icon(Icons.download, size: 20),
                label: Text(
                  'تحميل',
                  style: TextStyle(fontFamily: AppConstants.fontCairo),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            
            // ═══ التحميلات النشطة ═══
            if (activeDownloadKey != null && audioDownloads.containsKey(activeDownloadKey)) ...[
              const SizedBox(height: 16),
              _ActiveDownloadCard(
                info: audioDownloads[activeDownloadKey]!,
                color: color,
                onShowDetails: () => onShowDetails(activeDownloadKey!),
                onCancel: () => onCancel(activeDownloadKey!),
              ),
            ],
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
  final VoidCallback onShowDetails;
  final VoidCallback onCancel;

  const _ActiveDownloadCard({
    required this.info,
    required this.color,
    required this.onShowDetails,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: info.isCompleted 
              ? Colors.green.withValues(alpha: 0.5) 
              : color.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                info.isCompleted ? Icons.check_circle : Icons.downloading,
                color: info.isCompleted ? Colors.green : color.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.isCompleted ? 'تم التحميل' : 'جاري التحميل',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: info.isCompleted ? Colors.green : color.onSurface,
                  ),
                ),
              ),
              if (!info.isCompleted)
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: color.error),
                  onPressed: onCancel,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: info.progress,
              minHeight: 6,
              backgroundColor: color.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(
                info.isCompleted ? Colors.green : color.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          
          // النسبة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(info.progress * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: info.isCompleted ? Colors.green : color.primary,
                ),
              ),
              if (info.speed.isNotEmpty)
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
          
          const SizedBox(height: 8),
          
          // زر التفاصيل
          if (info.isDownloading)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onShowDetails,
                child: Text(
                  'عرض التفاصيل',
                  style: TextStyle(fontFamily: AppConstants.fontCairo, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
//  عنصر محدد
// ═══════════════════════════════════════
class _SelectedItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onClear;

  const _SelectedItem({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: textColor),
            onPressed: onClear,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
//  مؤشر التحميل
// ═══════════════════════════════════════
class _LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              fontFamily: AppConstants.fontCairo,
              fontSize: 13,
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
//  قائمة منسدلة مع بحث
// ═══════════════════════════════════════
class _DropdownList extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Function(Map<String, dynamic>) onItemSelected;
  final String Function(Map<String, dynamic>) itemBuilder;
  final ColorScheme color;

  const _DropdownList({
    required this.items,
    required this.searchController,
    required this.onSearchChanged,
    required this.onItemSelected,
    required this.itemBuilder,
    required this.color,
  });

  @override
  State<_DropdownList> createState() => _DropdownListState();
}

class _DropdownListState extends State<_DropdownList> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isExpanded = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_isExpanded) {
      setState(() => _isExpanded = false);
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _DropdownOverlay(
        layerLink: _layerLink,
        items: widget.items,
        onItemSelected: (item) {
          widget.onItemSelected(item);
          _removeOverlay();
        },
        itemBuilder: widget.itemBuilder,
        color: widget.color,
        searchController: widget.searchController,
        onSearchChanged: widget.onSearchChanged,
        onClose: _removeOverlay,
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isExpanded = true);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _isExpanded ? _removeOverlay : _showOverlay,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: widget.color.onSurfaceVariant, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.searchController,
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    color: widget.color.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث...',
                    hintStyle: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      color: widget.color.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    widget.onSearchChanged(value);
                    if (!_isExpanded) {
                      _showOverlay();
                    } else {
                      _overlayEntry?.markNeedsBuild();
                    }
                  },
                  onTap: () {
                    if (!_isExpanded) _showOverlay();
                  },
                ),
              ),
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: widget.color.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  Overlay للقائمة المنسدلة
// ═══════════════════════════════════════
class _DropdownOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onItemSelected;
  final String Function(Map<String, dynamic>) itemBuilder;
  final ColorScheme color;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClose;

  const _DropdownOverlay({
    required this.layerLink,
    required this.items,
    required this.onItemSelected,
    required this.itemBuilder,
    required this.color,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: MediaQuery.of(context).size.width - 64,
      child: CompositedTransformFollower(
        link: layerLink,
        showAbove: true,
        offset: const Offset(0, 50),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: color.surfaceContainerHighest,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    itemBuilder(item),
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 14,
                      color: color.onSurface,
                    ),
                  ),
                  onTap: () => onItemSelected(item),
                );
              },
            ),
          ),
        ),
      ),
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
//  إحصائيات التحميل
// ═══════════════════════════════════════
class _GlobalProgressCard extends StatelessWidget {
  final ColorScheme color;
  final bool isAzkarDownloaded;
  final bool isLaylatDownloaded;
  final int downloadedAudiosCount;
  
  const _GlobalProgressCard({
    required this.color,
    required this.isAzkarDownloaded,
    required this.isLaylatDownloaded,
    required this.downloadedAudiosCount,
  });

  @override
  Widget build(BuildContext context) {
    final completed = (isAzkarDownloaded ? 1 : 0) + (isLaylatDownloaded ? 1 : 0);
    final total = 3;
    final progress = completed / total;
    
    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_done_outlined, color: color.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'إحصائيات التحميل',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // شريط التقدم العام
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: color.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completed / $total مكتمل',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 13,
                color: color.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                _StatItem(
                  icon: Icons.auto_awesome_outlined,
                  label: 'الأذكار',
                  value: isAzkarDownloaded ? '✓' : '-',
                  color: color,
                ),
                const SizedBox(width: 12),
                _StatItem(
                  icon: Icons.nights_stay_outlined,
                  label: 'ليلة القدر',
                  value: isLaylatDownloaded ? '✓' : '-',
                  color: color,
                ),
                const SizedBox(width: 12),
                _StatItem(
                  icon: Icons.headphones_outlined,
                  label: 'الصوتيات',
                  value: downloadedAudiosCount > 0 ? '$downloadedAudiosCount' : '-',
                  color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 11,
                color: color.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: value == '✓' ? color.primary : color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}