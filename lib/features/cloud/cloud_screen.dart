import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/core/services/api_service.dart';
import 'package:badr/features/library/library_provider.dart';
import 'package:provider/provider.dart';

class CloudScreen extends StatefulWidget {
  const CloudScreen({super.key});

  @override
  State<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends State<CloudScreen> {
  final ApiService _api = ApiService();
  
  // التحميلات
  bool _isAzkarDownloaded = false;
  bool _isLaylatDownloaded = false;
  Map<String, DownloadInfo> _audioDownloads = {};
  
  // عناصر التحكم
  bool _isLoadingAzkar = false;
  bool _isLoadingLaylat = false;
  bool _isDownloadingAudio = false;
  
  // تصفية الصوتيات
  String _audioFilter = 'الكل';
  
  // التحميل اليدوي للصوتيات
  String? _selectedReciterId;
  String? _selectedReciterName;
  String? _selectedSurahId;
  String? _selectedSurahName;
  final TextEditingController _surahSearchController = TextEditingController();
  final TextEditingController _reciterSearchController = TextEditingController();
  List<Map<String, dynamic>> _searchedReciters = [];
  List<Map<String, dynamic>> _searchedSurahs = [];

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAzkarDownloaded = prefs.getBool('azkar_downloaded') ?? false;
      _isLaylatDownloaded = prefs.getBool('laylat_downloaded') ?? false;
    });
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

  Future<void> _searchReciters(String query) async {
    if (query.isEmpty) {
      setState(() => _searchedReciters = []);
      return;
    }
    try {
      final data = await _api.getReciters();
      final reciters = (data['reciters'] as List?) ?? [];
      setState(() {
        _searchedReciters = reciters
            .where((r) => r['reciter_name'].toString().contains(query))
            .take(5)
            .toList()
            .cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() => _searchedReciters = []);
    }
  }

  Future<void> _searchSurahs(String query) async {
    if (query.isEmpty) {
      setState(() => _searchedSurahs = []);
      return;
    }
    try {
      final data = await _api.getSurahs();
      final surahs = (data['surahs'] as List?) ?? [];
      setState(() {
        _searchedSurahs = surahs
            .where((s) => s['name'].toString().contains(query) || 
                         s['number'].toString().contains(query))
            .take(5)
            .toList()
            .cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() => _searchedSurahs = []);
    }
  }

  Future<void> _downloadSingleAudio() async {
    if (_selectedReciterId == null || _selectedSurahId == null) {
      _showErrorSnackBar('اختر القارئ والسورة أولاً');
      return;
    }
    
    final key = '${_selectedReciterId}_${_selectedSurahId}';
    setState(() {
      _audioDownloads[key] = DownloadInfo(
        progress: 0,
        isDownloading: true,
        speed: '',
      );
    });

    try {
      final data = await _api.getReciterAudio(_selectedReciterId!);
      final audios = (data['audio_urls'] as List?) ?? [];
      final audio = audios.firstWhere(
        (a) => a['surah_id'].toString() == _selectedSurahId,
        orElse: () => null,
      );
      
      if (audio == null) {
        throw Exception('السورة غير موجودة');
      }

      final url = audio['audio_url'].toString();
      
      // محاكاة التحميل مع شريط التقدم
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _audioDownloads[key] = DownloadInfo(
              progress: i / 100,
              isDownloading: i < 100,
              speed: '${(i * 0.5).toStringAsFixed(1)} MB/s',
            );
          });
        }
      }
      
      _showSuccessSnackBar('تم تحميل ${_selectedSurahName} بنجاح');
    } catch (e) {
      setState(() {
        _audioDownloads[key] = DownloadInfo(
          progress: 0,
          isDownloading: false,
          error: 'فشل التحميل',
        );
      });
      _showErrorSnackBar('فشل تحميل الملف');
    }
  }

  void _clearReciterSelection() {
    setState(() {
      _selectedReciterId = null;
      _selectedReciterName = null;
      _searchedReciters = [];
    });
    _reciterSearchController.clear();
  }

  void _clearSurahSelection() {
    setState(() {
      _selectedSurahId = null;
      _selectedSurahName = null;
      _searchedSurahs = [];
    });
    _surahSearchController.clear();
  }

  @override
  void dispose() {
    _surahSearchController.dispose();
    _reciterSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final libraryProvider = context.watch<LibraryProvider>();

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
            reciters: libraryProvider.reciters,
            isLoadingReciters: libraryProvider.isLoadingReciters,
            // البحث عن القراء
            searchedReciters: _searchedReciters,
            onReciterSearch: _searchReciters,
            selectedReciterId: _selectedReciterId,
            selectedReciterName: _selectedReciterName,
            onReciterSelected: (id, name) => setState(() {
              _selectedReciterId = id;
              _selectedReciterName = name;
              _searchedReciters = [];
            }),
            // البحث عن السور
            searchedSurahs: _searchedSurahs,
            onSurahSearch: _searchSurahs,
            selectedSurahId: _selectedSurahId,
            selectedSurahName: _selectedSurahName,
            onSurahSelected: (id, name) => setState(() {
              _selectedSurahId = id;
              _selectedSurahName = name;
              _searchedSurahs = [];
            }),
            surahSearchController: _surahSearchController,
            reciterSearchController: _reciterSearchController,
            // التحميل
            onDownload: _downloadSingleAudio,
            audioDownloads: _audioDownloads,
            isDownloadingAudio: _isDownloadingAudio,
            onClearReciter: _clearReciterSelection,
            onClearSurah: _clearSurahSelection,
          ),
          
          const SizedBox(height: 24),
          
          // ═══ مؤشر التحميل العام ═══
          _GlobalProgressCard(
            color: color,
            isAzkarDownloaded: _isAzkarDownloaded,
            isLaylatDownloaded: _isLaylatDownloaded,
            downloadedAudiosCount: _audioDownloads.length,
          ),
        ],
      ),
    );
  }
}

class DownloadInfo {
  final double progress;
  final bool isDownloading;
  final String speed;
  final String? error;
  
  DownloadInfo({
    required this.progress,
    required this.isDownloading,
    this.speed = '',
    this.error,
  });
}

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

class _AudioSectionCard extends StatelessWidget {
  final ColorScheme color;
  final String filter;
  final ValueChanged<String> onFilterChanged;
  final List<dynamic> reciters;
  final bool isLoadingReciters;
  final List<Map<String, dynamic>> searchedReciters;
  final Function(String) onReciterSearch;
  final String? selectedReciterId;
  final String? selectedReciterName;
  final Function(String, String) onReciterSelected;
  final List<Map<String, dynamic>> searchedSurahs;
  final Function(String) onSurahSearch;
  final String? selectedSurahId;
  final String? selectedSurahName;
  final Function(String, String) onSurahSelected;
  final TextEditingController surahSearchController;
  final TextEditingController reciterSearchController;
  final VoidCallback onDownload;
  final Map<String, DownloadInfo> audioDownloads;
  final bool isDownloadingAudio;
  final VoidCallback onClearReciter;
  final VoidCallback onClearSurah;

  const _AudioSectionCard({
    required this.color,
    required this.filter,
    required this.onFilterChanged,
    required this.reciters,
    required this.isLoadingReciters,
    required this.searchedReciters,
    required this.onReciterSearch,
    required this.selectedReciterId,
    required this.selectedReciterName,
    required this.onReciterSelected,
    required this.searchedSurahs,
    required this.onSurahSearch,
    required this.selectedSurahId,
    required this.selectedSurahName,
    required this.onSurahSelected,
    required this.surahSearchController,
    required this.reciterSearchController,
    required this.onDownload,
    required this.audioDownloads,
    required this.isDownloadingAudio,
    required this.onClearReciter,
    required this.onClearSurah,
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
            
            // البحث عن القارئ
            Text(
              'اختر القارئ',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 13,
                color: color.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reciterSearchController,
              style: TextStyle(fontFamily: AppConstants.fontCairo),
              decoration: InputDecoration(
                hintText: 'ابحث عن قارئ...',
                hintStyle: TextStyle(fontFamily: AppConstants.fontCairo, color: color.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: color.onSurfaceVariant),
                filled: true,
                fillColor: color.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: onReciterSearch,
            ),
            
            // نتائج البحث عن القارئ
            if (searchedReciters.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchedReciters.length,
                  itemBuilder: (context, index) {
                    final reciter = searchedReciters[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        reciter['reciter_name'].toString(),
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          color: color.onSurface,
                        ),
                      ),
                      onTap: () {
                        onReciterSelected(
                          reciter['reciter_id'].toString(),
                          reciter['reciter_name'].toString(),
                        );
                        reciterSearchController.text = reciter['reciter_name'].toString();
                      },
                    );
                  },
                ),
              ),
            
            // القارئ المختار
            if (selectedReciterName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: color.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedReciterName!,
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          color: color.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: color.onPrimaryContainer),
                      onPressed: onClearReciter,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // البحث عن السورة
            Text(
              'اختر السورة',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 13,
                color: color.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: surahSearchController,
              style: TextStyle(fontFamily: AppConstants.fontCairo),
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة...',
                hintStyle: TextStyle(fontFamily: AppConstants.fontCairo, color: color.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: color.onSurfaceVariant),
                filled: true,
                fillColor: color.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: onSurahSearch,
            ),
            
            // نتائج البحث عن السورة
            if (searchedSurahs.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchedSurahs.length,
                  itemBuilder: (context, index) {
                    final surah = searchedSurahs[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        '${surah['number']}. ${surah['name']}',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          color: color.onSurface,
                        ),
                      ),
                      onTap: () {
                        onSurahSelected(
                          surah['number'].toString(),
                          surah['name'].toString(),
                        );
                        surahSearchController.text = '${surah['number']}. ${surah['name']}';
                      },
                    );
                  },
                ),
              ),
            
            // السورة المختارة
            if (selectedSurahName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book, size: 16, color: color.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedSurahName!,
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          color: color.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: color.onSecondaryContainer),
                      onPressed: onClearSurah,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // زر التحميل
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
            
            // شريط التحميل
            if (audioDownloads.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...audioDownloads.entries.map((entry) {
                final info = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'جاري التحميل...',
                              style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontSize: 12,
                                color: color.onSurfaceVariant,
                              ),
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
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: info.progress,
                        backgroundColor: color.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(color.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(info.progress * 100).toInt()}%',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 11,
                          color: color.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

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