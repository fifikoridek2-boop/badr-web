import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/quran/quran_provider.dart';
import 'package:badr/features/quran/surah_detail_screen.dart';
import 'package:badr/shared/models/surah_model.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'الكل';

  @override
  void initState() {
    super.initState();
    final provider = context.read<QuranProvider>();
    Future.microtask(() => provider.loadSurahs());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final provider = context.watch<QuranProvider>();

    final bookmarks = provider.bookmarks;
    final surahs = _getFilteredSurahs(provider.surahs);

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        title: Text(
          'المصحف الشريف',
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontWeight: FontWeight.bold,
            color: color.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'ابحث عن سورة...',
              hintStyle: WidgetStateProperty.all(
                TextStyle(fontFamily: AppConstants.fontCairo),
              ),
              textStyle: WidgetStateProperty.all(
                TextStyle(fontFamily: AppConstants.fontCairo),
              ),
              onChanged: (q) => provider.search(q),
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      provider.search('');
                    },
                  ),
              ],
            ),
          ),

          // ═══════════════════════════════════════
          //  الإشارات المرجعية
          // ═══════════════════════════════════════
          if (bookmarks.isNotEmpty && _searchController.text.isEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.bookmark, size: 16, color: color.primary),
                  const SizedBox(width: 6),
                  Text(
                    'المرجعيات',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final b = bookmarks[index];
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ActionChip(
                      label: Text(
                        b['surah_name'] ?? '',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 12,
                        ),
                      ),
                      avatar: Icon(Icons.bookmark,
                          size: 14, color: color.primary),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SurahDetailScreen(
                            surahNumber: b['surah_number'],
                            surahName: b['surah_name'],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // ═══════════════════════════════════════
          //  فلترة مكية / مدنية
          // ═══════════════════════════════════════
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['الكل', 'مكية', 'مدنية'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(
                      f,
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 13,
                        color: selected
                            ? color.onPrimary
                            : color.onSurface,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: color.primary,
                    checkmarkColor: color.onPrimary,
                    backgroundColor: color.surfaceContainerHigh,
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ═══════════════════════════════════════
          //  القائمة
          // ═══════════════════════════════════════
          Expanded(
            child: provider.isLoadingSurahs
                ? _buildShimmer(color)
                : provider.error.isNotEmpty
                    ? _buildError(context, provider, color)
                    : surahs.isEmpty
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
                            itemCount: surahs.length,
                            itemBuilder: (context, index) {
                              final surah = surahs[index];
                              return _SurahTile(
                                surah: surah,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SurahDetailScreen(
                                      surahNumber: surah.number,
                                      surahName: surah.arName,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  List<SurahModel> _getFilteredSurahs(List<SurahModel> surahs) {
    if (_filter == 'مكية') {
      return surahs.where((s) => s.type == 'Meccan').toList();
    } else if (_filter == 'مدنية') {
      return surahs.where((s) => s.type == 'Medinan').toList();
    }
    return surahs;
  }

  Widget _buildError(
      BuildContext context, QuranProvider provider, ColorScheme color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 48, color: color.error),
          const SizedBox(height: 12),
          Text(
            'لا يوجد اتصال بالإنترنت',
            style: TextStyle(
              fontFamily: AppConstants.fontCairo,
              color: color.error,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => provider.loadSurahs(),
            child: Text('إعادة المحاولة',
                style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
        ],
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
            height: 70,
            decoration: BoxDecoration(
              color: color.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final SurahModel surah;
  final VoidCallback onTap;
  const _SurahTile({required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: color.surfaceContainerLow,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${surah.number}',
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.arName,
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${surah.typeAr}  •  ${surah.ayatCount} آية',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 12,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_back_ios_new,
                    size: 16, color: color.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
