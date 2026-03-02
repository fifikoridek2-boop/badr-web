import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/prayer/prayer_screen.dart';
import 'package:badr/features/home/home_provider.dart';
import 'package:badr/features/library/library_screen.dart';
import 'package:badr/features/tasbih/tasbih_screen.dart';
import 'package:badr/features/radio/radio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<HomeProvider>();
    Future.microtask(() => provider.loadData());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final provider = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        title: Text(
          AppConstants.appName,
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontWeight: FontWeight.bold,
            color: color.primary,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_alarm_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerScreen())),
            tooltip: 'مواقيت الصلاة',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              provider.isLoading
                  ? _ShimmerCard(height: 100)
                  : _PrayerCard(provider: provider),
              const SizedBox(height: 16),
              provider.isLoading
                  ? _ShimmerCard(height: 120)
                  : _AzkarCard(text: provider.azkarText),
              const SizedBox(height: 16),
              if (provider.error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '⚠️ ${provider.error}',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      color: color.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              _FeaturesGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  Shimmer عام
// ═══════════════════════════════════════
class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: color.surfaceContainerHigh,
      highlightColor: color.surfaceContainerHighest,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  بطاقة وقت الصلاة
// ═══════════════════════════════════════
class _PrayerCard extends StatelessWidget {
  final HomeProvider provider;
  const _PrayerCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final prayer = provider.prayerTimes;

    return Card(
      elevation: 0,
      color: color.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mosque_outlined,
                        size: 20, color: color.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      prayer?.getNextPrayer() ?? '---',
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: color.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      prayer?.getNextPrayerTime() ?? '--:--',
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 16,
                        color: color.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.hourglass_bottom,
                        size: 14,
                        color: color.onPrimaryContainer.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      prayer?.getTimeRemaining() ?? '',
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 13,
                        color: color.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(Icons.access_time_rounded, size: 48, color: color.primary),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  بطاقة ذكر اليوم
// ═══════════════════════════════════════
class _AzkarCard extends StatelessWidget {
  final String text;
  const _AzkarCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: color.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 18, color: color.onSecondaryContainer),
                const SizedBox(width: 6),
                Text(
                  'ذكر اليوم',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(
                fontFamily: AppConstants.fontAyat,
                fontSize: 18,
                color: color.onSecondaryContainer,
                height: 1.8,
              ),
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  شبكة الميزات
// ═══════════════════════════════════════
class _FeaturesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    final features = [
      _Feature('القراء', Icons.headphones_outlined, () =>
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LibraryScreen()))),
      _Feature('التسبيح', Icons.track_changes_outlined, () =>
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TasbihScreen()))),
      _Feature('الراديو', Icons.radio_outlined, () =>
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RadioScreen()))),
      _Feature('ليلة القدر', Icons.nights_stay_outlined, () {}),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: features
          .map((f) => _FeatureCard(feature: f, color: color))
          .toList(),
    );
  }
}

class _Feature {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _Feature(this.label, this.icon, this.onTap);
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  final ColorScheme color;
  const _FeatureCard({required this.feature, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: feature.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(feature.icon, size: 36, color: color.primary),
            const SizedBox(height: 8),
            Text(
              feature.label,
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
