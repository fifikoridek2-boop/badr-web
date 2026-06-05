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
              _CalculationMethodDropdown(provider: provider),
              const SizedBox(height: 16),
              _SettingLabel(
                label: 'حساب العصر',
                tooltip:
                    'اختر تلقائي ليتم تحديد المذهب حسب موقعك، أو حدده يدويًا (شافعي/حنفي).',
                color: color,
              ),
              const SizedBox(height: 8),
              _AsrMadhabSegmentedButton(provider: provider),
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
    final textTheme = Theme.of(context).textTheme;

    return Card.filled(
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_outlined,
                    color: color.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معاينة الأذان',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color.onSurface,
                        ),
                      ),
                      Text(
                        'استمع للأذان قبل تفعيل التنبيهات',
                        style: textTheme.labelSmall?.copyWith(
                          fontFamily: AppConstants.fontCairo,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            StreamBuilder<Duration?>(
              stream: provider.adhanDurationStream,
              builder: (context, durationSnap) {
                final duration =
                    durationSnap.data ?? provider.adhanDuration ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: provider.adhanPositionStream,
                  builder: (context, posSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    final maxMs = duration.inMilliseconds <= 0
                        ? 1
                        : duration.inMilliseconds;
                    final value =
                        position.inMilliseconds.clamp(0, maxMs).toDouble();
                    final remaining = duration > position
                        ? duration - position
                        : Duration.zero;

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                          ),
                          child: Slider(
                            value: value,
                            min: 0,
                            max: maxMs.toDouble(),
                            onChanged: (v) {
                              provider.seekAdhan(
                                Duration(milliseconds: v.round()),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: textTheme.labelSmall?.copyWith(
                                  fontFamily: AppConstants.fontCairo,
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '-${_formatDuration(remaining)}',
                                style: textTheme.labelSmall?.copyWith(
                                  fontFamily: AppConstants.fontCairo,
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<PlayerState>(
                          stream: provider.adhanPlayerStateStream,
                          builder: (context, snap) {
                            final isPlaying =
                                snap.data?.playing ?? provider.isAdhanPlaying;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton.filled(
                                  onPressed: () => isPlaying
                                      ? provider.pauseAdhan()
                                      : provider.playAdhan(),
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    size: 30,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: color.primary,
                                    foregroundColor: color.onPrimary,
                                    fixedSize: const Size.square(58),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton.filledTonal(
                                  onPressed: () => provider.stopAdhan(),
                                  icon: const Icon(Icons.stop, size: 22),
                                  style: IconButton.styleFrom(
                                    fixedSize: const Size.square(44),
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
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _CalculationMethodDropdown extends StatelessWidget {
  final PrayerProvider provider;

  const _CalculationMethodDropdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final currentValue = provider.isAutoMethod ? 'auto' : provider.method.name;

    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          key: ValueKey(currentValue),
          width: constraints.maxWidth,
          initialSelection: currentValue,
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(
              color.surfaceContainerHigh,
            ),
          ),
          textStyle: TextStyle(
            fontFamily: AppConstants.fontCairo,
            color: color.onSurface,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: color.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: color.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: color.outlineVariant),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          dropdownMenuEntries: [
            DropdownMenuEntry<String>(
              value: 'auto',
              label: 'تلقائي',
              leadingIcon: Icon(Icons.auto_mode, color: color.primary),
            ),
            ...PrayerProvider.methodNames.entries.map(
              (e) => DropdownMenuEntry<String>(
                value: e.key.name,
                label: e.value,
              ),
            ),
          ],
          onSelected: (value) {
            if (value == null) return;
            if (value == 'auto') {
              provider.setMethodAuto(true);
              return;
            }
            final method = PrayerProvider.methodNames.keys.firstWhere(
              (m) => m.name == value,
              orElse: () => provider.method,
            );
            provider.setMethod(method);
          },
        );
      },
    );
  }
}

class _AsrMadhabSegmentedButton extends StatelessWidget {
  final PrayerProvider provider;

  const _AsrMadhabSegmentedButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    final selected = provider.isAutoMadhab
        ? 'auto'
        : provider.madhab == Madhab.hanafi
            ? 'hanafi'
            : 'shafi';

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        selected: {selected},
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 'auto', label: Text('تلقائي')),
          ButtonSegment(value: 'shafi', label: Text('شافعي')),
          ButtonSegment(value: 'hanafi', label: Text('حنفي')),
        ],
        onSelectionChanged: (values) {
          final value = values.first;
          if (value == 'auto') {
            provider.setMadhabAuto(true);
          } else if (value == 'hanafi') {
            provider.setMadhab(Madhab.hanafi);
          } else {
            provider.setMadhab(Madhab.shafi);
          }
        },
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(
            TextStyle(fontFamily: AppConstants.fontCairo),
          ),
        ),
      ),
    );
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
