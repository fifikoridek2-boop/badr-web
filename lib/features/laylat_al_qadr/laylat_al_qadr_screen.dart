import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/core/services/api_service.dart';

class LaylatAlQadrScreen extends StatefulWidget {
  const LaylatAlQadrScreen({super.key});

  @override
  State<LaylatAlQadrScreen> createState() => _LaylatAlQadrScreenState();
}

class _LaylatAlQadrScreenState extends State<LaylatAlQadrScreen> {
  late Future<Map<String, dynamic>> _contentFuture;

  static const List<String> _sectionOrder = [
    'definition',
    'virtue',
    'quranic_evidence',
    'hadith_evidence',
    'naming_reasons',
    'signs',
    'recommended_acts',
    'importance',
    'scholars_opinions',
    'date',
  ];

  static const Map<String, String> _fallbackSectionTitles = {
    'definition': 'التعريف',
    'virtue': 'الفضل',
    'quranic_evidence': 'الأدلة من القرآن الكريم',
    'hadith_evidence': 'الأدلة من السنة النبوية',
    'naming_reasons': 'سبب تسميتها',
    'signs': 'علاماتها',
    'recommended_acts': 'الأعمال المستحبة فيها',
    'importance': 'أهميتها',
    'scholars_opinions': 'أقوال العلماء',
    'date': 'توقيتها',
  };

  static const Map<String, String> _fieldLabels = {
    'value': '',
    'surah_al_qadr': 'سورة القدر',
    'surah_al_dukhan': 'سورة الدخان',
    'bukhari': 'رواه البخاري',
    'muslim': 'رواه مسلم',
    'greatness': 'عظيم شأنها',
    'predestination': 'تقدير الأقدار',
    'confirmed': 'علامات مؤكدة',
    'unconfirmed': 'علامات غير مؤكدة',
    'acts': 'أعمال مستحبة',
    'quran_revelation': 'نزول القرآن',
    'angels_descend': 'تنزل الملائكة',
    'decrees_written': 'تقدير الأمور',
    'ibn_kathir': 'ابن كثير',
    'ibn_taymiyyah': 'ابن تيمية',
  };

  @override
  void initState() {
    super.initState();
    _contentFuture = _loadContent();
  }

  Future<Map<String, dynamic>> _loadContent() async {
    final response = await ApiService().getLaylatAlQadr();
    if (response is! Map) {
      throw Exception('تعذر قراءة بيانات ليلة القدر');
    }

    final content = response['laylat_al_qadr'];
    if (content is! Map) {
      throw Exception('تعذر العثور على معلومات ليلة القدر');
    }

    return Map<String, dynamic>.from(content);
  }

  Future<void> _refresh() async {
    final future = _loadContent();
    setState(() => _contentFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        title: Text(
          'ليلة القدر',
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontWeight: FontWeight.bold,
            color: color.primary,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LaylatLoadingList();
          }

          if (snapshot.hasError) {
            return _LaylatError(
              error: snapshot.error.toString(),
              onRetry: () => setState(() => _contentFuture = _loadContent()),
            );
          }

          final content = snapshot.data ?? {};
          final keys = _orderedKeys(content);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _HeroCard(section: content['definition']),
                const SizedBox(height: 16),
                ...keys
                    .where((key) => key != 'definition')
                    .map(
                      (key) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SectionCard(
                          sectionKey: key,
                          section: content[key],
                          fallbackTitle: _fallbackSectionTitles[key] ?? key,
                          fieldLabels: _fieldLabels,
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _orderedKeys(Map<String, dynamic> content) {
    final ordered = _sectionOrder
        .where((key) => content.containsKey(key))
        .toList();
    final remaining = content.keys.where((key) => !ordered.contains(key));
    return [...ordered, ...remaining];
  }
}

class _HeroCard extends StatelessWidget {
  final dynamic section;
  const _HeroCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final data = section is Map
        ? Map<String, dynamic>.from(section)
        : <String, dynamic>{};
    final title = data['name']?.toString() ?? 'ليلة القدر';
    final value = data['value']?.toString() ?? '';

    return Card(
      elevation: 0,
      color: color.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.nights_stay_rounded,
                    color: color.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  fontSize: 15,
                  height: 1.8,
                  color: color.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String sectionKey;
  final dynamic section;
  final String fallbackTitle;
  final Map<String, String> fieldLabels;

  const _SectionCard({
    required this.sectionKey,
    required this.section,
    required this.fallbackTitle,
    required this.fieldLabels,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final data = section is Map
        ? Map<String, dynamic>.from(section)
        : <String, dynamic>{'value': section};
    final title = data['name']?.toString() ?? fallbackTitle;
    final entries = data.entries.where((entry) => entry.key != 'name').toList();

    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconForSection(sectionKey),
                  color: color.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.map(
              (entry) => _ValueBlock(
                label: fieldLabels[entry.key] ?? entry.key,
                value: entry.value,
                fieldLabels: fieldLabels,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForSection(String key) {
    switch (key) {
      case 'virtue':
        return Icons.workspace_premium_outlined;
      case 'quranic_evidence':
        return Icons.menu_book_outlined;
      case 'hadith_evidence':
        return Icons.record_voice_over_outlined;
      case 'naming_reasons':
        return Icons.help_outline_rounded;
      case 'signs':
        return Icons.visibility_outlined;
      case 'recommended_acts':
        return Icons.volunteer_activism_outlined;
      case 'importance':
        return Icons.stars_outlined;
      case 'scholars_opinions':
        return Icons.school_outlined;
      case 'date':
        return Icons.calendar_month_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

class _ValueBlock extends StatelessWidget {
  final String label;
  final dynamic value;
  final Map<String, String> fieldLabels;

  const _ValueBlock({
    required this.label,
    required this.value,
    required this.fieldLabels,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    if (value is List) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label.isNotEmpty) _BlockLabel(label: label),
            ...(value as List).map(
              (item) => _BulletText(text: item.toString()),
            ),
          ],
        ),
      );
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label.isNotEmpty) _BlockLabel(label: label),
            ...map.entries.map(
              (entry) => _ValueBlock(
                label: fieldLabels[entry.key] ?? entry.key,
                value: entry.value,
                fieldLabels: fieldLabels,
              ),
            ),
          ],
        ),
      );
    }

    final text = value?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: label.isEmpty
          ? Text(
              text,
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 15,
                height: 1.8,
                color: color.onSurface,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BlockLabel(label: label),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 15,
                    height: 1.8,
                    color: color.onSurface,
                  ),
                ),
              ],
            ),
    );
  }
}

class _BlockLabel extends StatelessWidget {
  final String label;
  const _BlockLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppConstants.fontCairo,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color.primary,
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText({required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Icon(Icons.circle, size: 6, color: color.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 15,
                height: 1.7,
                color: color.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaylatLoadingList extends StatelessWidget {
  const _LaylatLoadingList();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: color.surfaceContainerHigh,
            highlightColor: color.surfaceContainerHighest,
            child: Container(
              height: index == 0 ? 170 : 130,
              decoration: BoxDecoration(
                color: color.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(index == 0 ? 24 : 20),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LaylatError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _LaylatError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 52, color: color.error),
            const SizedBox(height: 12),
            Text(
              'تعذر تحميل معلومات ليلة القدر',
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 13,
                color: color.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: AppConstants.fontCairo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
