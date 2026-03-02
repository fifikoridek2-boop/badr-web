import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/library/library_provider.dart';
import 'package:badr/features/library/reciter_screen.dart';
import 'package:badr/shared/models/reciter_model.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<LibraryProvider>().loadReciters());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final provider = context.watch<LibraryProvider>();

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        title: Text('المكتبة الصوتية',
            style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontWeight: FontWeight.bold,
                color: color.primary)),
      ),
      body: Column(
        children: [
          // ─── بحث ───
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'ابحث عن قارئ...',
              hintStyle: WidgetStateProperty.all(
                  TextStyle(fontFamily: AppConstants.fontCairo)),
              textStyle: WidgetStateProperty.all(
                  TextStyle(fontFamily: AppConstants.fontCairo)),
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

          Expanded(
            child: provider.isLoadingReciters
                ? _buildShimmer(color)
                : provider.error.isNotEmpty
                    ? _buildError(provider, color)
                    : ListView(
                        children: [
                          // ─── المفضلون ───
                          if (provider.favorites.isNotEmpty &&
                              _searchController.text.isEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Row(
                                children: [
                                  Icon(Icons.star,
                                      size: 16, color: color.primary),
                                  const SizedBox(width: 6),
                                  Text('المفضلون',
                                      style: TextStyle(
                                          fontFamily: AppConstants.fontCairo,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: color.primary)),
                                ],
                              ),
                            ),
                            ...provider.favorites.map((r) => _ReciterTile(
                                  reciter: r,
                                  isFavorite: true,
                                  onTap: () => _openReciter(context, r),
                                  onFavorite: () =>
                                      provider.toggleFavorite(r),
                                )),
                            const Divider(indent: 16, endIndent: 16),
                            const SizedBox(height: 4),
                          ],

                          // ─── كل القراء ───
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: Row(
                              children: [
                                Icon(Icons.headphones_outlined,
                                    size: 16,
                                    color: color.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                    '${provider.reciters.length} قارئ',
                                    style: TextStyle(
                                        fontFamily: AppConstants.fontCairo,
                                        fontSize: 13,
                                        color: color.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          ...provider.reciters.map((r) => _ReciterTile(
                                reciter: r,
                                isFavorite: provider.isFavorite(r.reciterId),
                                onTap: () => _openReciter(context, r),
                                onFavorite: () =>
                                    provider.toggleFavorite(r),
                              )),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  void _openReciter(BuildContext context, ReciterModel reciter) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReciterScreen(reciter: reciter)),
    );
  }

  Widget _buildShimmer(ColorScheme color) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: color.surfaceContainerHigh,
        highlightColor: color.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            height: 64,
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
            onPressed: () => provider.loadReciters(),
            child: Text('إعادة المحاولة',
                style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
        ],
      ),
    );
  }
}

class _ReciterTile extends StatelessWidget {
  final ReciterModel reciter;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  const _ReciterTile({
    required this.reciter,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline,
                      color: color.onPrimaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(reciter.reciterName,
                      style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: color.onSurface)),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_outline,
                    color: isFavorite ? color.primary : color.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: onFavorite,
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
