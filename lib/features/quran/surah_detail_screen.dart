import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/quran/quran_provider.dart';
import 'package:badr/shared/widgets/player_box.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<QuranProvider>();
    final savedPage = provider.getBookmarkPage(widget.surahNumber);
    final startPage = savedPage ?? provider.getSurahStartPage(widget.surahNumber);
    Future.microtask(() => provider.loadPage(startPage));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final provider = context.watch<QuranProvider>();
    final isBookmarked = provider.isBookmarked(widget.surahNumber);

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        title: Text(
          provider.currentPage?.surahNameAr.isNotEmpty == true
              ? provider.currentPage!.surahNameAr
              : widget.surahName,
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontWeight: FontWeight.bold,
            color: color.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              color: isBookmarked ? color.primary : null,
            ),
            onPressed: () => provider.toggleBookmark(
              widget.surahNumber,
              widget.surahName,
              provider.currentPageNumber,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () => provider.increaseFontSize(),
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () => provider.decreaseFontSize(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.isLoadingPage
                ? _buildShimmer(color)
                : provider.error.isNotEmpty
                    ? _buildError(context, provider, color)
                    : _buildPage(provider, color),
          ),
          _PageNavBar(provider: provider),
          const PlayerBox(),
        ],
      ),
    );
  }

  Widget _buildPage(QuranProvider provider, ColorScheme color) {
    final page = provider.currentPage;
    if (page == null || page.ayahs.isEmpty) {
      return Center(
        child: Text('لا توجد بيانات',
            style: TextStyle(fontFamily: AppConstants.fontCairo)),
      );
    }

    final nextPageStart = provider.getSurahStartPage(
        (provider.currentPage?.surahNumber ?? widget.surahNumber) + 1);
    final isLastPage = page.pageNumber >= nextPageStart - 1 ||
        (provider.currentPage?.surahNumber ?? widget.surahNumber) == 114;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.outlineVariant),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: color.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('جزء ${page.juzNumber}',
                      style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 12,
                          color: color.onPrimaryContainer)),
                  Text(page.surahNameAr,
                      style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color.onPrimaryContainer)),
                  Text('صفحة ${page.pageNumber}',
                      style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 12,
                          color: color.onPrimaryContainer)),
                ],
              ),
            ),
            if (page.ayahs.first.ayahNumber == 1 &&
                page.pageNumber != 1 &&
                page.pageNumber != 187)
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 4),
                child: Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: TextStyle(
                    fontFamily: AppConstants.fontAyat,
                    fontSize: provider.fontSize - 2,
                    color: color.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: RichText(
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.justify,
                text: TextSpan(
                  children: _buildAyahSpans(page.ayahs, provider.fontSize, color),
                ),
              ),
            ),
            if (isLastPage)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'صَدَقَ اللَّهُ الْعَظِيمُ',
                  style: TextStyle(
                    fontFamily: AppConstants.fontAyat,
                    fontSize: provider.fontSize - 2,
                    color: color.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildAyahSpans(List ayahs, double fontSize, ColorScheme color) {
    final spans = <TextSpan>[];
    for (final ayah in ayahs) {
      final cleanText = ayah.text.replaceAll('۞', '').replaceAll('۩', '').trim();
      spans.add(TextSpan(
        text: '$cleanText ',
        style: TextStyle(
          fontFamily: AppConstants.fontAyat,
          fontSize: fontSize,
          color: color.onSurface,
          height: 2.2,
        ),
      ));
      spans.add(TextSpan(
        text: '﴿${_toArabicNumber(ayah.ayahNumber)}﴾ ',
        style: TextStyle(
          fontFamily: AppConstants.fontCairo,
          fontSize: fontSize * 0.75,
          color: color.primary,
          height: 2.2,
        ),
      ));
    }
    return spans;
  }

  String _toArabicNumber(int n) {
    const arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return n.toString().split('').map((d) => arabic[int.parse(d)]).join();
  }

  Widget _buildShimmer(ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: color.surfaceContainerHigh,
        highlightColor: color.surfaceContainerHighest,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, QuranProvider provider, ColorScheme color) {
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
            onPressed: () => provider.loadPage(provider.currentPageNumber),
            child: Text('إعادة المحاولة',
                style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
        ],
      ),
    );
  }
}

class _PageNavBar extends StatelessWidget {
  final QuranProvider provider;
  const _PageNavBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final page = provider.currentPageNumber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        border: Border(top: BorderSide(color: color.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filled(
            onPressed: page < 604 ? () => provider.loadPage(page + 1) : null,
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: page < 604 ? color.primaryContainer : color.surfaceContainerHigh,
              foregroundColor: page < 604 ? color.onPrimaryContainer : color.onSurfaceVariant,
            ),
          ),
          GestureDetector(
            onTap: () => _showPagePicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: color.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$page / 604',
                  style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color.onPrimaryContainer)),
            ),
          ),
          IconButton.filled(
            onPressed: page > 1 ? () => provider.loadPage(page - 1) : null,
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: page > 1 ? color.primaryContainer : color.surfaceContainerHigh,
              foregroundColor: page > 1 ? color.onPrimaryContainer : color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showPagePicker(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: '${provider.currentPageNumber}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('انتقل إلى صفحة',
            style: TextStyle(fontFamily: AppConstants.fontCairo)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 - 604',
            hintStyle: TextStyle(fontFamily: AppConstants.fontCairo),
          ),
          style: TextStyle(fontFamily: AppConstants.fontCairo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
          FilledButton(
            onPressed: () {
              final p = int.tryParse(controller.text);
              if (p != null && p >= 1 && p <= 604) {
                provider.loadPage(p);
                Navigator.pop(context);
              }
            },
            child: Text('انتقال',
                style: TextStyle(fontFamily: AppConstants.fontCairo, color: color.onPrimary)),
          ),
        ],
      ),
    );
  }
}
