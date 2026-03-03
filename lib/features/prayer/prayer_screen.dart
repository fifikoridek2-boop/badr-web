import 'package:adhan/adhan.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/prayer/prayer_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PrayerProvider>().loadPrayerTimes());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final provider = context.watch<PrayerProvider>();

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        title: Text(
          'مواقيت الصلاة',
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontWeight: FontWeight.bold,
            color: color.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadPrayerTimes(),
          ),
        ],
      ),
      body: provider.isLoading
          ? _buildShimmer(color)
          : provider.error.isNotEmpty
              ? _buildError(provider, color)
              : _buildContent(provider, color),
    );
  }

  Widget _buildShimmer(ColorScheme color) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: color.surfaceContainerHigh,
              highlightColor: color.surfaceContainerHighest,
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: color.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
        ...List.generate(
          6,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Shimmer.fromColors(
              baseColor: color.surfaceContainerHigh,
              highlightColor: color.surfaceContainerHighest,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: color.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(PrayerProvider provider, ColorScheme color) {
    final prayers = provider.getPrayerList();
    final currentPrayer = provider.getCurrentPrayer();
    final nextPrayer = provider.getNextPrayer();
    final nextTime = provider.getNextPrayerTime();
    DateTime? currentTime;
    for (final p in prayers) {
      if (p['name'] == currentPrayer) {
        currentTime = p['time'] as DateTime?;
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          color: color.primaryContainer,
          borderRadius: BorderRadius.circular(999),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: color.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                provider.cityName.isNotEmpty
                    ? provider.cityName
                    : 'جارٍ تحديد الموقع...',
                style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          color: color.primaryContainer,
          child: Row(
            children: [
              Expanded(
                child: _PrayerSummaryPane(
                  title: 'الصلاة الحالية',
                  name: currentPrayer.isNotEmpty ? currentPrayer : '--',
                  timeText: currentTime != null
                      ? DateFormat('hh:mm a').format(currentTime!)
                      : '--:--',
                  color: color,
                ),
              ),
              Container(
                width: 1,
                height: 64,
                color: color.onPrimaryContainer.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _PrayerSummaryPane(
                  title: 'الصلاة القادمة',
                  name: nextPrayer.isNotEmpty ? nextPrayer : '--',
                  timeText:
                      nextTime != null ? DateFormat('hh:mm a').format(nextTime) : '--:--',
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          color: color.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إعدادات مواقيت الصلاة',
                style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
              const SizedBox(height: 12),
              _SettingLabel(
                label: 'طريقة الحساب',
                tooltip:
                    'اختر تلقائي ليتم تحديد طريقة الحساب حسب إحداثيات موقعك، أو اختر طريقة محددة يدويًا.',
                color: color,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SmallChip(
                    label: 'تلقائي',
                    selected: provider.isAutoMethod,
                    color: color,
                    onTap: () => provider.setMethodAuto(true),
                  ),
                  ...PrayerProvider.methodNames.entries.map(
                    (e) => _SmallChip(
                      label: e.value,
                      selected: !provider.isAutoMethod && provider.method == e.key,
                      color: color,
                      onTap: () => provider.setMethod(e.key),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingLabel(
                label: 'حساب العصر',
                tooltip:
                    'اختر تلقائي ليتم تحديد المذهب حسب موقعك، أو حدده يدويًا (شافعي/حنفي).',
                color: color,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SmallChip(
                    label: 'تلقائي',
                    selected: provider.isAutoMadhab,
                    color: color,
                    onTap: () => provider.setMadhabAuto(true),
                  ),
                  _SmallChip(
                    label: 'شافعي',
                    selected: !provider.isAutoMadhab && provider.madhab == Madhab.shafi,
                    color: color,
                    onTap: () => provider.setMadhab(Madhab.shafi),
                  ),
                  _SmallChip(
                    label: 'حنفي',
                    selected: !provider.isAutoMadhab && provider.madhab == Madhab.hanafi,
                    color: color,
                    onTap: () => provider.setMadhab(Madhab.hanafi),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _AdhanControlCard(provider: provider),
        const SizedBox(height: 16),
        ...prayers.map(
          (p) => _PrayerCard(
            prayer: p,
            isCurrentPrayer: p['name'] == currentPrayer,
            notificationEnabled: provider.notifications[p['key']] ?? true,
            adjustment: provider.adjustments[p['key']] ?? 0,
            onToggleNotification: () => provider.toggleNotification(p['key']),
            onAdjust: () => _showAdjustDialog(context, provider, p),
          ),
        ),
      ],
    );
  }

  Widget _buildError(PrayerProvider provider, ColorScheme color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 48, color: color.error),
          const SizedBox(height: 12),
          Text(
            provider.error,
            style: TextStyle(fontFamily: AppConstants.fontCairo, color: color.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => provider.loadPrayerTimes(),
            child: Text('إعادة المحاولة', style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, PrayerProvider provider, Map p) {
    final color = Theme.of(context).colorScheme;
    int adjustment = provider.adjustments[p['key']] ?? 0;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: Text('تعديل وقت ${p['name']}', style: TextStyle(fontFamily: AppConstants.fontCairo)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تعديل الوقت بالدقائق',
                style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  fontSize: 13,
                  color: color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setS(() => adjustment--),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${adjustment >= 0 ? '+' : ''}$adjustment دقيقة',
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setS(() => adjustment++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: TextStyle(fontFamily: AppConstants.fontCairo)),
            ),
            FilledButton(
              onPressed: () {
                provider.setAdjustment(p['key'], adjustment);
                Navigator.pop(context);
              },
              child: Text('حفظ', style: TextStyle(fontFamily: AppConstants.fontCairo)),
            ),
          ],
        ),
      ),
    );
  }
}


class _PrayerSummaryPane extends StatelessWidget {
  final String title;
  final String name;
  final String timeText;
  final ColorScheme color;

  const _PrayerSummaryPane({
    required this.title,
    required this.name,
    required this.timeText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontSize: 12,
            color: color.onPrimaryContainer.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color.onPrimaryContainer,
          ),
        ),
        Text(
          timeText,
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontSize: 13,
            color: color.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final BorderRadius? borderRadius;

  const _SectionCard({required this.child, required this.color, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _AdhanControlCard extends StatelessWidget {
  final PrayerProvider provider;

  const _AdhanControlCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return _SectionCard(
      color: color.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تشغيل الأذان',
            style: TextStyle(
              fontFamily: AppConstants.fontCairo,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color.primary,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<Duration?>(
            stream: provider.adhanDurationStream,
            builder: (context, durationSnap) {
              final duration = durationSnap.data ?? provider.adhanDuration ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: provider.adhanPositionStream,
                builder: (context, posSnap) {
                  final position = posSnap.data ?? Duration.zero;
                  final maxMs = duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds;
                  final value = position.inMilliseconds.clamp(0, maxMs).toDouble();

                  return Column(
                    children: [
                      Slider(
                        value: value,
                        min: 0,
                        max: maxMs.toDouble(),
                        onChanged: (v) {
                          provider.seekAdhan(Duration(milliseconds: v.round()));
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: TextStyle(
                              fontFamily: AppConstants.fontCairo,
                              fontSize: 12,
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              fontFamily: AppConstants.fontCairo,
                              fontSize: 12,
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<PlayerState>(
                        stream: provider.adhanPlayerStateStream,
                        builder: (context, snap) {
                          final isPlaying = snap.data?.playing ?? provider.isAdhanPlaying;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilledButton.icon(
                                onPressed: () => provider.playAdhan(),
                                icon: const Icon(Icons.play_arrow),
                                label: Text(
                                  'تشغيل',
                                  style: TextStyle(fontFamily: AppConstants.fontCairo),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: isPlaying ? () => provider.pauseAdhan() : null,
                                icon: const Icon(Icons.pause),
                                label: Text(
                                  'إيقاف مؤقت',
                                  style: TextStyle(fontFamily: AppConstants.fontCairo),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => provider.stopAdhan(),
                                icon: const Icon(Icons.stop),
                                label: Text(
                                  'إيقاف',
                                  style: TextStyle(fontFamily: AppConstants.fontCairo),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _SettingLabel extends StatelessWidget {
  final String label;
  final String tooltip;
  final ColorScheme color;

  const _SettingLabel({
    required this.label,
    required this.tooltip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppConstants.fontCairo,
              fontSize: 12,
              color: color.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.info_outline, size: 14, color: color.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme color;
  final VoidCallback onTap;

  const _SmallChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.primary : color.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.primary : color.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? color.onPrimary : color.onSurface,
          ),
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final Map<String, dynamic> prayer;
  final bool isCurrentPrayer;
  final bool notificationEnabled;
  final int adjustment;
  final VoidCallback onToggleNotification;
  final VoidCallback onAdjust;

  const _PrayerCard({
    required this.prayer,
    required this.isCurrentPrayer,
    required this.notificationEnabled,
    required this.adjustment,
    required this.onToggleNotification,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final time = prayer['time'] as DateTime?;
    final timeStr = time != null ? DateFormat('hh:mm a').format(time) : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentPrayer ? color.primaryContainer : color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPrayer ? color.primary.withValues(alpha: 0.5) : color.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCurrentPrayer ? color.primary : color.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              prayer['icon'] as IconData,
              size: 20,
              color: isCurrentPrayer ? color.onPrimary : color.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer['name'] as String,
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrentPrayer ? color.onPrimaryContainer : color.onSurface,
                  ),
                ),
                if (adjustment != 0)
                  Text(
                    '${adjustment > 0 ? '+' : ''}$adjustment دقيقة',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 11,
                      color: color.primary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(
              fontFamily: AppConstants.fontCairo,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCurrentPrayer ? color.onPrimaryContainer : color.primary,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.tune, size: 18, color: color.onSurfaceVariant),
            onPressed: onAdjust,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: Icon(
              notificationEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              size: 18,
              color: notificationEnabled ? color.primary : color.onSurfaceVariant,
            ),
            onPressed: onToggleNotification,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
