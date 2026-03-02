import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/library/library_provider.dart';

class PlayerBox extends StatefulWidget {
  const PlayerBox({super.key});

  @override
  State<PlayerBox> createState() => _PlayerBoxState();
}

class _PlayerBoxState extends State<PlayerBox>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  void _expand() {
    if (!_isExpanded) setState(() => _isExpanded = true);
  }

  void _collapse() {
    if (_isExpanded) setState(() => _isExpanded = false);
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
                Icon(Icons.download_outlined,
                    color: color.onPrimaryContainer.withValues(alpha: 0.7),
                    size: 20),
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
