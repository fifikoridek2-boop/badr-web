import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/library/library_provider.dart';
import 'package:badr/shared/models/reciter_model.dart';
import 'package:badr/shared/widgets/player_box.dart';

class ReciterScreenEnhanced extends StatefulWidget {
  final ReciterModel reciter;
  const ReciterScreenEnhanced({super.key, required this.reciter});

  @override
  State<ReciterScreenEnhanced> createState() => _ReciterScreenEnhancedState();
}

class _ReciterScreenEnhancedState extends State<ReciterScreenEnhanced> {
  late String _filterMode;

  @override
  void initState() {
    super.initState();
    _filterMode = 'all';
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('الكل')),
                      ButtonSegment(value: 'downloaded', label: Text('محمل')),
                    ],
                    selected: {_filterMode},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _filterMode = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoadingAudios
                ? _buildShimmer(color)
                : provider.error.isNotEmpty
                    ? _buildError(provider, color)
                    : ListView.builder(
                        itemCount: _getFilteredAudios(provider).length,
                        itemBuilder: (context, index) {
                          final audio = _getFilteredAudios(provider)[index];
                          final isPlaying =
                              provider.isCurrentlyPlaying(audio.audioUrl);
                          final isDownloaded =
                              provider.isAudioDownloaded(audio.audioUrl);

                          return _SurahAudioTileWithDownload(
                            reciter: widget.reciter,
                            audio: audio,
                            isPlaying: isPlaying,
                            isDownloaded: isDownloaded,
                            isDownloading:
                                provider.isDownloadingAudio &&
                                    provider.downloadingFileName ==
                                        audio.surahNameAr,
                            downloadProgress: provider.downloadProgress,
                            onPlay: () =>
                                provider.playSurah(widget.reciter, audio),
                            onDownload: () =>
                                provider.downloadAudio(
                                    audio.audioUrl, audio.surahNameAr),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<ReciterAudioModel> _getFilteredAudios(LibraryProvider provider) {
    if (_filterMode == 'downloaded') {
      return provider.currentReciterAudios
          .where((audio) => provider.isAudioDownloaded(audio.audioUrl))
          .toList();
    }
    return provider.currentReciterAudios;
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
            height: 72,
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

class _SurahAudioTileWithDownload extends StatelessWidget {
  final ReciterModel reciter;
  final ReciterAudioModel audio;
  final bool isPlaying;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const _SurahAudioTileWithDownload({
    required this.reciter,
    required this.audio,
    required this.isPlaying,
    required this.isDownloaded,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onPlay,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        color: isPlaying ? color.primaryContainer : color.surfaceContainerLow,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            InkWell(
              onTap: onPlay,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? color.primary
                            : color.primaryContainer,
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
                    const SizedBox(width: 12),
                    if (isDownloaded)
                      Icon(Icons.check_circle, color: color.primary, size: 20)
                    else
                      IconButton(
                        icon: Icon(Icons.download_outlined,
                            color: color.tertiary, size: 20),
                        onPressed: onDownload,
                      ),
                  ],
                ),
              ),
            ),
            if (isDownloading) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: downloadProgress,
                      minHeight: 3,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(downloadProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontFamily: AppConstants.fontCairo,
                            fontSize: 11,
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
