import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/library/library_provider.dart';

class PlayerBottomSheet extends StatelessWidget {
  final Widget child;
  const PlayerBottomSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final hasPlayer = provider.currentSurahName.isNotEmpty;

    return Stack(
      children: [
        // ─── الشاشة الأصلية مع padding في الأسفل ───
        AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(bottom: hasPlayer ? 72 : 0),
          child: child,
        ),

        // ─── Player Sheet ───
        if (hasPlayer)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _PlayerSheet(provider: provider),
          ),
      ],
    );
  }
}

class _PlayerSheet extends StatefulWidget {
  final LibraryProvider provider;
  const _PlayerSheet({required this.provider});

  @override
  State<_PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<_PlayerSheet>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(begin: 72, end: 260).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final provider = widget.provider;

    return GestureDetector(
      onTap: _isExpanded ? null : _toggle,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -200 && !_isExpanded) _toggle();
        if (details.primaryVelocity! > 200 && _isExpanded) _toggle();
      },
      child: AnimatedBuilder(
        animation: _heightAnimation,
        builder: (context, _) => Container(
          height: _heightAnimation.value,
          decoration: BoxDecoration(
            color: color.surfaceContainerHigh,
            border: Border(top: BorderSide(color: color.outlineVariant)),
            boxShadow: [
              BoxShadow(
                color: color.shadow.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ─── Handle ───
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              // ─── الحالة المصغرة ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      provider.isRadio ? Icons.radio : Icons.headphones,
                      color: color.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.currentSurahName,
                            style: TextStyle(
                              fontFamily: AppConstants.fontCairo,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (provider.currentReciter != null)
                            Text(
                              provider.currentReciter!.reciterName,
                              style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontSize: 11,
                                color: color.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        provider.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: color.primary,
                      ),
                      onPressed: () => provider.togglePlay(),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: color.onSurfaceVariant, size: 20),
                      onPressed: () {
                        if (_isExpanded) _toggle();
                        provider.stop();
                      },
                    ),
                  ],
                ),
              ),

              // ─── الحالة الموسعة ───
              if (_isExpanded) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // شريط المدة أو الراديو
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: provider.isRadio
                      ? _buildRadioIndicator(color)
                      : _buildProgressBar(color, provider),
                ),

                const SizedBox(height: 12),

                // زر التحميل
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: TextButton.icon(
                        onPressed: null, // لاحقاً
                        icon: Icon(Icons.download_outlined,
                            size: 18, color: color.onSurfaceVariant),
                        label: Text(
                          'تحميل',
                          style: TextStyle(
                            fontFamily: AppConstants.fontCairo,
                            fontSize: 12,
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme color, LibraryProvider provider) {
    return StreamBuilder<Duration>(
      stream: provider.audioService.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = provider.audioService.duration ?? Duration.zero;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (v) {
                  final pos = Duration(
                      milliseconds: (v * duration.inMilliseconds).round());
                  provider.audioService.seek(pos);
                },
                activeColor: color.primary,
                inactiveColor: color.outlineVariant,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position),
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 11,
                        color: color.onSurfaceVariant)),
                Text(_formatDuration(duration),
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 11,
                        color: color.onSurfaceVariant)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRadioIndicator(ColorScheme color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text('بث مباشر',
            style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 13,
                color: color.primary,
                fontWeight: FontWeight.bold)),
        const Spacer(),
        StreamBuilder<PlayerState>(
          stream: widget.provider.audioService.playerStateStream,
          builder: (context, snapshot) {
            final isBuffering = snapshot.data?.processingState ==
                ProcessingState.buffering;
            return isBuffering
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color.primary),
                  )
                : Icon(Icons.radio, color: color.primary, size: 20);
          },
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
