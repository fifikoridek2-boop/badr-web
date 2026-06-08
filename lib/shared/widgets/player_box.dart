import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/library/library_provider.dart';
import 'package:badr/features/cloud/cloud_screen.dart';

class PlayerBox extends StatefulWidget {
  const PlayerBox({super.key});

  @override
  State<PlayerBox> createState() => _PlayerBoxState();
}

class _PlayerBoxState extends State<PlayerBox>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isDownloadStarted = false;
  double _downloadProgress = 0;
  String _downloadSpeed = '';

  void _expand() {
    if (!_isExpanded) setState(() => _isExpanded = true);
  }

  void _collapse() {
    if (_isExpanded) setState(() => _isExpanded = false);
  }

  void _startDownload() async {
    final provider = context.read<LibraryProvider>();
    final surahName = provider.currentSurahName;
    
    setState(() {
      _isDownloadStarted = true;
      _downloadProgress = 0;
      _downloadSpeed = '';
    });

    // محاكاة التحميل
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _downloadProgress = i / 100;
          _downloadSpeed = '${(i * 0.3).toStringAsFixed(1)} MB/s';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isDownloadStarted = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحميل $surahName بنجاح',
            style: TextStyle(fontFamily: AppConstants.fontCairo),
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'عرض التفاصيل',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CloudScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  void _showDownloadDialog(BuildContext context, LibraryProvider provider) {
    final color = Theme.of(context).colorScheme;
    final audioUrl = provider.audioService.currentUrl;
    final surahName = provider.currentSurahName;
    final reciterName = provider.currentReciter?.reciterName ?? '';

    if (audioUrl == null) return;

    // إعادة تعيين حالة التحميل
    setState(() {
      _isDownloadStarted = false;
      _downloadProgress = 0;
      _downloadSpeed = '';
    });

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.download, color: color.primary),
                const SizedBox(width: 8),
                Text(
                  'تحميل الصوت',
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
                if (surahName.isNotEmpty) ...[
                  Text(
                    'السورة: $surahName',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (reciterName.isNotEmpty) ...[
                  Text(
                    'القارئ: $reciterName',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'سيتم تحميل الملف الصوتي على جهازك.',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 13,
                    color: color.onSurfaceVariant,
                  ),
                ),
                
                // ═══ شريط التحميل ═══
                if (_isDownloadStarted) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _downloadProgress,
                      minHeight: 10,
                      backgroundColor: color.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_downloadProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color.primary,
                        ),
                      ),
                      Text(
                        _downloadSpeed,
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 11,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'جاري التحميل...',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 11,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (!_isDownloadStarted) ...[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: AppConstants.fontCairo),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    _startDownload();
                  },
                  child: Text(
                    'تحميل',
                    style: TextStyle(fontFamily: AppConstants.fontCairo),
                  ),
                ),
              ] else ...[
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isDownloadStarted = false;
                      _downloadProgress = 0;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      color: color.error,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CloudScreen()),
                    );
                  },
                  child: Text(
                    'عرض التفاصيل',
                    style: TextStyle(fontFamily: AppConstants.fontCairo),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final color = Theme.of(context).colorScheme;

    if (provider.currentSurahName.isEmpty) return const SizedBox();

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -300) _expand();
        if (details.primaryVelocity! > 300) _collapse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: color.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.shadow.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── خط السحب فقط (بدون onTap) ───
              GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < -100) _expand();
                  if (details.primaryVelocity! > 100) _collapse();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color.onPrimaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Mini دائماً ظاهر ───
              _buildMini(provider, color),

              // ─── Expanded عند السحب ───
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? _buildExpandedContent(provider, color)
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMini(LibraryProvider provider, ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
      child: Row(
        children: [
          Icon(
            provider.isRadio ? Icons.radio : Icons.headphones,
            color: color.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.currentSurahName,
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color.onPrimaryContainer,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!provider.isRadio && provider.currentReciter != null)
                  Text(
                    provider.currentReciter!.reciterName,
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 11,
                      color: color.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              provider.isPlaying ? Icons.pause : Icons.play_arrow,
              color: color.onPrimaryContainer,
            ),
            onPressed: () => provider.togglePlay(),
          ),
          IconButton(
            icon: Icon(Icons.close,
                color: color.onPrimaryContainer, size: 20),
            onPressed: () => provider.stop(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(LibraryProvider provider, ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: color.onPrimaryContainer.withValues(alpha: 0.2)),
          const SizedBox(height: 8),

          // شريط المدة أو الراديو
          if (provider.isRadio)
            _buildRadioBar(color)
          else
            _buildProgressBar(provider, color),

          const SizedBox(height: 16),

          // زر التشغيل الكبير
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.onPrimaryContainer,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  provider.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: color.primaryContainer,
                  size: 28,
                ),
                onPressed: () => provider.togglePlay(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(LibraryProvider provider, ColorScheme color) {
    return StreamBuilder<Duration>(
      stream: provider.audioService.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = provider.audioService.duration ?? Duration.zero;
        final progress = duration.inSeconds > 0
            ? (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0)
            : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12),
                      activeTrackColor: color.onPrimaryContainer,
                      inactiveTrackColor:
                          color.onPrimaryContainer.withValues(alpha: 0.3),
                      thumbColor: color.onPrimaryContainer,
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (v) {
                        final newPos = Duration(
                            seconds: (v * duration.inSeconds).round());
                        provider.audioService.seek(newPos);
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.download_outlined,
                      color: color.onPrimaryContainer.withValues(alpha: 0.7),
                      size: 20),
                  onPressed: () => _showDownloadDialog(context, provider),
                  tooltip: 'تحميل الصوت',
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position),
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 11,
                        color: color.onPrimaryContainer.withValues(alpha: 0.7))),
                Text(_formatDuration(duration),
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 11,
                        color: color.onPrimaryContainer.withValues(alpha: 0.7))),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRadioBar(ColorScheme color) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
              color: color.onPrimaryContainer, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('بث مباشر',
            style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 12,
                color: color.onPrimaryContainer)),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            backgroundColor: color.onPrimaryContainer.withValues(alpha: 0.2),
            valueColor:
                AlwaysStoppedAnimation<Color>(color.onPrimaryContainer),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
