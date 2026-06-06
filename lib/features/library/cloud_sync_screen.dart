import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/library/library_provider.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  final TextEditingController _reciterSearchController = TextEditingController();
  final TextEditingController _surahSearchController = TextEditingController();

  @override
  void dispose() {
    _reciterSearchController.dispose();
    _surahSearchController.dispose();
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
        title: Text(
          'السحابة',
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
          _buildDownloadCard(
            title: 'الصور',
            icon: Icons.image_outlined,
            isCompleted: true,
            color: color,
          ),
          const SizedBox(height: 12),
          _buildDownloadCard(
            title: 'أذان وإقامة',
            icon: Icons.notifications_active_outlined,
            isCompleted: true,
            color: color,
          ),
          const SizedBox(height: 16),
          _buildAzkarDownloadCard(provider, color),
          const SizedBox(height: 16),
          _buildLaylatQadrDownloadCard(provider, color),
          const SizedBox(height: 16),
          _buildAudioDownloadSection(provider, color),
        ],
      ),
    );
  }

  Widget _buildDownloadCard({
    required String title,
    required IconData icon,
    required bool isCompleted,
    required ColorScheme color,
  }) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color.onPrimaryContainer, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'محمل بالكامل',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 12,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle, color: color.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAzkarDownloadCard(LibraryProvider provider, ColorScheme color) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite_outlined,
                      color: color.onPrimaryContainer, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأذكار',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'أذكار مختلفة وسور قرآنية',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 12,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: Text(
                  'تحميل الأن',
                  style: TextStyle(fontFamily: AppConstants.fontCairo),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaylatQadrDownloadCard(
      LibraryProvider provider, ColorScheme color) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.star_outlined,
                      color: color.onPrimaryContainer, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ليلة القدر',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'معلومات عن ليلة القدر المباركة',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 12,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: Text(
                  'تحميل الأن',
                  style: TextStyle(fontFamily: AppConstants.fontCairo),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioDownloadSection(LibraryProvider provider, ColorScheme color) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تحميل التلاوات',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            SearchBar(
              controller: _reciterSearchController,
              hintText: 'اختر أو ابحث عن قارئ...',
              hintStyle: WidgetStateProperty.all(
                  TextStyle(fontFamily: AppConstants.fontCairo)),
              textStyle: WidgetStateProperty.all(
                  TextStyle(fontFamily: AppConstants.fontCairo)),
              leading: const Icon(Icons.person_outlined),
              trailing: [
                if (_reciterSearchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _reciterSearchController.clear(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SearchBar(
              controller: _surahSearchController,
              hintText: 'اختر أو ابحث عن سورة...',
              hintStyle: WidgetStateProperty.all(
                  TextStyle(fontFamily: AppConstants.fontCairo)),
              textStyle: WidgetStateProperty.all(
                  TextStyle(fontFamily: AppConstants.fontCairo)),
              leading: const Icon(Icons.book_outlined),
              trailing: [
                if (_surahSearchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _surahSearchController.clear(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: Text(
                  'تحميل',
                  style: TextStyle(fontFamily: AppConstants.fontCairo),
                ),
              ),
            ),
            if (provider.isDownloadingAudio) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: provider.downloadProgress),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    provider.downloadingFileName,
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 12,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(provider.downloadProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 12,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
