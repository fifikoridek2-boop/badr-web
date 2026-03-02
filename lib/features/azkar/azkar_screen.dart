import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/azkar/azkar_provider.dart';
import 'package:badr/shared/models/azkar_model.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  String _filter = 'الكل';

  final List<Map<String, dynamic>> _allTabs = [
    {'key': 'morning_azkar',  'label': 'الصباح',   'icon': Icons.wb_sunny_outlined,     'isDua': false},
    {'key': 'evening_azkar',  'label': 'المساء',   'icon': Icons.nights_stay_outlined,  'isDua': false},
    {'key': 'sleep_azkar',    'label': 'النوم',    'icon': Icons.bedtime_outlined,       'isDua': false},
    {'key': 'prophetic_duas', 'label': 'نبوية',    'icon': Icons.star_outline,           'isDua': true},
    {'key': 'quran_duas',     'label': 'قرآنية',   'icon': Icons.menu_book_outlined,    'isDua': true},
    {'key': 'prophets_duas',  'label': 'الأنبياء', 'icon': Icons.people_outline,        'isDua': true},
  ];

  List<Map<String, dynamic>> get _filteredTabs {
    if (_filter == 'أذكار') return _allTabs.where((t) => !(t['isDua'] as bool)).toList();
    if (_filter == 'أدعية') return _allTabs.where((t) => t['isDua'] as bool).toList();
    return _allTabs;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AzkarProvider>().loadData());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final provider = context.watch<AzkarProvider>();
    final tabs = _filteredTabs;

    return DefaultTabController(
      length: tabs.length,
      key: ValueKey(_filter), // ← مفتاح إعادة البناء عند تغيير الفلتر
      child: Scaffold(
        backgroundColor: color.surface,
        appBar: AppBar(
          backgroundColor: color.surface,
          title: Text('الأذكار والأدعية',
              style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  fontWeight: FontWeight.bold,
                  color: color.primary)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(96),
            child: Column(
              children: [
                // ─── فلتر ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: ['الكل', 'أذكار', 'أدعية'].map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(f,
                              style: TextStyle(
                                  fontFamily: AppConstants.fontCairo,
                                  fontSize: 13,
                                  color: selected ? color.onPrimary : color.onSurface)),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: color.primary,
                          backgroundColor: color.surfaceContainerHigh,
                          side: BorderSide.none,
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // ─── تبويبات ───
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelStyle: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(
                      fontFamily: AppConstants.fontCairo, fontSize: 13),
                  tabs: tabs.map((t) => Tab(
                    icon: Icon(t['icon'] as IconData, size: 18),
                    text: t['label'] as String,
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        body: provider.isLoading
            ? _buildShimmer(color)
            : provider.error.isNotEmpty
                ? _buildError(provider, color)
                : TabBarView(
                    children: tabs.map((t) {
                      final key = t['key'] as String;
                      final isDua = t['isDua'] as bool;
                      final list = isDua
                          ? provider.duas[key] ?? []
                          : provider.azkar[key] ?? [];
                      return _AzkarList(
                          items: list, categoryKey: key, isDua: isDua);
                    }).toList(),
                  ),
      ),
    );
  }

  Widget _buildShimmer(ColorScheme color) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: color.surfaceContainerHigh,
        highlightColor: color.surfaceContainerHighest,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
              color: color.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildError(AzkarProvider provider, ColorScheme color) {
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
            onPressed: () => provider.loadData(),
            child: Text('إعادة المحاولة',
                style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
        ],
      ),
    );
  }
}

class _AzkarList extends StatelessWidget {
  final List<AzkarModel> items;
  final String categoryKey;
  final bool isDua;
  const _AzkarList(
      {required this.items, required this.categoryKey, required this.isDua});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return Center(
          child: Text('لا توجد بيانات',
              style: TextStyle(fontFamily: AppConstants.fontCairo)));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${items.where((a) => a.isDone).length} / ${items.length} مكتمل',
                  style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 13,
                      color: color.onSurfaceVariant)),
              TextButton.icon(
                onPressed: () => context
                    .read<AzkarProvider>()
                    .resetCategory(categoryKey, isDua),
                icon: const Icon(Icons.refresh, size: 16),
                label: Text('إعادة تعيين',
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo, fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: items.length,
            itemBuilder: (context, index) => _AzkarCard(
                item: items[index], categoryKey: categoryKey, isDua: isDua),
          ),
        ),
      ],
    );
  }
}

class _AzkarCard extends StatelessWidget {
  final AzkarModel item;
  final String categoryKey;
  final bool isDua;
  const _AzkarCard(
      {required this.item, required this.categoryKey, required this.isDua});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final isDone = item.isDone;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone
            ? color.primaryContainer.withValues(alpha: 0.5)
            : color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDone
                ? color.primary.withValues(alpha: 0.5)
                : color.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              item.text,
              style: TextStyle(
                fontFamily: AppConstants.fontAyat,
                fontSize: 18,
                color: isDone
                    ? color.onSurface.withValues(alpha: 0.5)
                    : color.onSurface,
                height: 1.9,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.text));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('تم النسخ',
                          style:
                              TextStyle(fontFamily: AppConstants.fontCairo)),
                      duration: const Duration(seconds: 1),
                    ));
                  },
                  icon: const Icon(Icons.copy_outlined, size: 18),
                ),
                if (!isDone)
                  GestureDetector(
                    onTap: () => context
                        .read<AzkarProvider>()
                        .incrementAzkar(categoryKey, item.id, isDua),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                          color: color.primaryContainer,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('${item.currentCount} / ${item.count}',
                          style: TextStyle(
                              fontFamily: AppConstants.fontCairo,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color.onPrimaryContainer)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: color.primary,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Icon(Icons.check, size: 16, color: color.onPrimary),
                      const SizedBox(width: 4),
                      Text('مكتمل',
                          style: TextStyle(
                              fontFamily: AppConstants.fontCairo,
                              fontSize: 13,
                              color: color.onPrimary)),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
