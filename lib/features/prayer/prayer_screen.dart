import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/prayer/prayer_provider.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

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
        title: Text('مواقيت الصلاة',
            style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontWeight: FontWeight.bold,
                color: color.primary)),
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
        Shimmer.fromColors(
          baseColor: color.surfaceContainerHigh,
          highlightColor: color.surfaceContainerHighest,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: color.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 16),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── بطاقة رئيسية موسعة ───
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // الموقع
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: color.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    provider.cityName.isNotEmpty
                        ? provider.cityName
                        : 'جارٍ تحديد الموقع...',
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 13,
                        color: color.onPrimaryContainer),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // الصلاة الحالية والقادمة
              Row(
                children: [
                  if (currentPrayer.isNotEmpty)
                    Expanded(
                      child: Column(
                        children: [
                          Text('الصلاة الحالية',
                              style: TextStyle(
                                  fontFamily: AppConstants.fontCairo,
                                  fontSize: 11,
                                  color: color.onPrimaryContainer
                                      .withValues(alpha: 0.7))),
                          const SizedBox(height: 4),
                          Text(currentPrayer,
                              style: TextStyle(
                                  fontFamily: AppConstants.fontCairo,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: color.onPrimaryContainer)),
                        ],
                      ),
                    ),
                  if (currentPrayer.isNotEmpty && nextPrayer.isNotEmpty)
                    Container(
                        width: 1,
                        height: 40,
                        color: color.onPrimaryContainer.withValues(alpha: 0.3)),
                  if (nextPrayer.isNotEmpty && nextTime != null)
                    Expanded(
                      child: Column(
                        children: [
                          Text('الصلاة القادمة',
                              style: TextStyle(
                                  fontFamily: AppConstants.fontCairo,
                                  fontSize: 11,
                                  color: color.onPrimaryContainer
                                      .withValues(alpha: 0.7))),
                          const SizedBox(height: 4),
                          Text(nextPrayer,
                              style: TextStyle(
                                  fontFamily: AppConstants.fontCairo,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: color.onPrimaryContainer)),
                          Text(
                            DateFormat('hh:mm a').format(nextTime),
                            style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontSize: 13,
                                color: color.onPrimaryContainer
                                    .withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // زر الأذان
              OutlinedButton.icon(
                onPressed: () => provider.playAdhan(),
                icon: Icon(Icons.volume_up_outlined,
                    color: color.onPrimaryContainer, size: 18),
                label: Text('سماع الأذان',
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 13,
                        color: color.onPrimaryContainer)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: color.onPrimaryContainer.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                ),
              ),

              const Divider(height: 28),

              // ─── إعدادات الحساب داخل البطاقة ───
              Text('إعدادات المواقيت',
                  style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color.onPrimaryContainer)),

              const SizedBox(height: 12),

              // طريقة الحساب
              _SettingRow(
                label: 'طريقة الحساب',
                tooltip:
                    'كل منطقة جغرافية لها طريقة حساب خاصة تعتمد على زاوية الشمس لتحديد الفجر والعشاء',
                color: color,
                child: DropdownButton<CalculationMethod>(
                  value: provider.method,
                  isDense: true,
                  dropdownColor: color.primaryContainer,
                  style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 12,
                      color: color.onPrimaryContainer),
                  underline: const SizedBox(),
                  items: PrayerProvider.methodNames.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value,
                                style: TextStyle(
                                    fontFamily: AppConstants.fontCairo,
                                    fontSize: 12,
                                    color: color.onPrimaryContainer)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) provider.setMethod(v);
                  },
                ),
              ),

              const SizedBox(height: 8),

              // المذهب
              _SettingRow(
                label: 'حساب العصر',
                tooltip:
                    'شافعي: العصر يبدأ حين يساوي الظل مثله (أبكر)\nحنفي: العصر يبدأ حين يساوي الظل مثليه (أمتد)',
                color: color,
                child: Row(
                  children: [
                    _SmallChip(
                      label: 'شافعي',
                      selected: provider.madhab == Madhab.shafi,
                      color: color,
                      onTap: () => provider.setMadhab(Madhab.shafi),
                    ),
                    const SizedBox(width: 6),
                    _SmallChip(
                      label: 'حنفي',
                      selected: provider.madhab == Madhab.hanafi,
                      color: color,
                      onTap: () => provider.setMadhab(Madhab.hanafi),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─── قائمة الصلوات ───
        ...prayers.map((p) => _PrayerCard(
              prayer: p,
              isCurrentPrayer: p['name'] == currentPrayer,
              notificationEnabled: provider.notifications[p['key']] ?? true,
              adjustment: provider.adjustments[p['key']] ?? 0,
              onToggleNotification: () =>
                  provider.toggleNotification(p['key']),
              onAdjust: () => _showAdjustDialog(context, provider, p),
            )),
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
          Text(provider.error,
              style: TextStyle(
                  fontFamily: AppConstants.fontCairo, color: color.error),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => provider.loadPrayerTimes(),
            child: Text('إعادة المحاولة',
                style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(
      BuildContext context, PrayerProvider provider, Map p) {
    final color = Theme.of(context).colorScheme;
    int adjustment = provider.adjustments[p['key']] ?? 0;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: Text('تعديل وقت ${p['name']}',
              style: TextStyle(fontFamily: AppConstants.fontCairo)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تعديل الوقت بالدقائق',
                  style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 13,
                      color: color.onSurfaceVariant)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setS(() => adjustment--),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
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
                          color: color.onPrimaryContainer),
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
              child: Text('إلغاء',
                  style: TextStyle(fontFamily: AppConstants.fontCairo)),
            ),
            FilledButton(
              onPressed: () {
                provider.setAdjustment(p['key'], adjustment);
                Navigator.pop(context);
              },
              child: Text('حفظ',
                  style: TextStyle(fontFamily: AppConstants.fontCairo)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── صف الإعداد مع tooltip ───
class _SettingRow extends StatelessWidget {
  final String label;
  final String tooltip;
  final ColorScheme color;
  final Widget child;

  const _SettingRow({
    required this.label,
    required this.tooltip,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: tooltip,
          triggerMode: TooltipTriggerMode.tap,
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 12,
                      color: color.onPrimaryContainer.withValues(alpha: 0.8))),
              const SizedBox(width: 4),
              Icon(Icons.info_outline,
                  size: 14,
                  color: color.onPrimaryContainer.withValues(alpha: 0.5)),
            ],
          ),
        ),
        const Spacer(),
        child,
      ],
    );
  }
}

// ─── Chip صغير للمذهب ───
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? color.onPrimaryContainer
              : color.onPrimaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontFamily: AppConstants.fontCairo,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected
                  ? color.primaryContainer
                  : color.onPrimaryContainer),
        ),
      ),
    );
  }
}

// ─── بطاقة الصلاة ───
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
    final timeStr =
        time != null ? DateFormat('hh:mm a').format(time) : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentPrayer
            ? color.primaryContainer
            : color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPrayer
              ? color.primary.withValues(alpha: 0.5)
              : color.outlineVariant,
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
            child: Icon(prayer['icon'] as IconData,
                size: 20,
                color: isCurrentPrayer
                    ? color.onPrimary
                    : color.onPrimaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prayer['name'] as String,
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCurrentPrayer
                            ? color.onPrimaryContainer
                            : color.onSurface)),
                if (adjustment != 0)
                  Text(
                    '${adjustment > 0 ? '+' : ''}$adjustment دقيقة',
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 11,
                        color: color.primary),
                  ),
              ],
            ),
          ),
          Text(timeStr,
              style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCurrentPrayer
                      ? color.onPrimaryContainer
                      : color.primary)),
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
              color: notificationEnabled
                  ? color.primary
                  : color.onSurfaceVariant,
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
