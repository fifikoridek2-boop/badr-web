import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/library/library_provider.dart';
import 'package:badr/shared/models/reciter_model.dart';
import 'package:badr/shared/widgets/player_box.dart';
import 'package:badr/shared/widgets/player_box.dart';

class ReciterScreen extends StatefulWidget {
  final ReciterModel reciter;
  const ReciterScreen({super.key, required this.reciter});

  @override
  State<ReciterScreen> createState() => _ReciterScreenState();
}

class _ReciterScreenState extends State<ReciterScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<LibraryProvider>().loadReciterAudios(widget.reciter));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final provider = context.watch<LibraryProvider>();

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        title: Text(widget.reciter.reciterName,
            style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontWeight: FontWeight.bold,
                color: color.primary)),
        actions: [
          IconButton(
            icon: Icon(
              provider.isFavorite(widget.reciter.reciterId)
                  ? Icons.star
                  : Icons.star_outline,
              color: provider.isFavorite(widget.reciter.reciterId)
                  ? color.primary
                  : null,
            ),
            onPressed: () => provider.toggleFavorite(widget.reciter),
          ),
        ],
      ),
      bottomSheet: const PlayerBox(),
      body: provider.isLoadingAudios
          ? _buildShimmer(color)
          : provider.error.isNotEmpty
              ? _buildError(provider, color)
              : ListView.builder(
                  itemCount: provider.currentReciterAudios.length,
                  itemBuilder: (context, index) {
                    final audio = provider.currentReciterAudios[index];
                    final isPlaying =
                        provider.isCurrentlyPlaying(audio.audioUrl);
                    return _SurahAudioTile(
                      audio: audio,
                      isPlaying: isPlaying,
                      onTap: () => provider.playSurah(widget.reciter, audio),
                    );
                  },
                ),
    );
  }

  Widget _buildShimmer(ColorScheme color) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: color.surfaceContainerHigh,
        highlightColor: color.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
                color: color.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildError(LibraryProvider provider, ColorScheme color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 48, color: color.error),
          const SizedBox(height: 12),
          Text('لا يوجد اتصال بالإنترنت',
              style: TextStyle(
                  fontFamily: AppConstants.fontCairo, color: color.error)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => provider.loadReciterAudios(widget.reciter),
            child: Text('إعادة المحاولة',
                style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
        ],
      ),
    );
  }
}

class _SurahAudioTile extends StatelessWidget {
  final ReciterAudioModel audio;
  final bool isPlaying;
  final VoidCallback onTap;
  const _SurahAudioTile(
      {required this.audio, required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: isPlaying ? color.primaryContainer : color.surfaceContainerLow,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isPlaying ? color.primary : color.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: isPlaying
                        ? color.onPrimary
                        : color.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(audio.surahNameAr,
                      style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 15,
                          fontWeight: isPlaying
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isPlaying
                              ? color.onPrimaryContainer
                              : color.onSurface)),
                ),
                Text('# ${audio.surahId}',
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 12,
                        color: color.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
