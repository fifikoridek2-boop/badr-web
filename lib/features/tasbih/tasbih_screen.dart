import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/shared/widgets/player_box.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _total = 0;

  final List<Map<String, dynamic>> _tasbih = [
    {'text': 'سُبْحَانَ اللَّهِ',         'count': 0},
    {'text': 'الْحَمْدُ لِلَّهِ',          'count': 0},
    {'text': 'لَا إِلَهَ إِلَّا اللَّهُ', 'count': 0},
    {'text': 'اللَّهُ أَكْبَرُ',           'count': 0},
  ];

  void _increment(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _tasbih[index]['count'] = (_tasbih[index]['count'] as int) + 1;
      _total++;
    });
  }

  void _reset() {
    setState(() {
      _total = 0;
      for (final t in _tasbih) {
        t['count'] = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        title: Text('عداد التسبيح',
            style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontWeight: FontWeight.bold,
                color: color.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: color.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text('مجموع التسبيحات',
                            style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontSize: 14,
                                color: color.onPrimaryContainer)),
                        const SizedBox(height: 8),
                        Text('$_total',
                            style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: color.onPrimaryContainer)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: _tasbih.length,
                    itemBuilder: (context, index) {
                      final t = _tasbih[index];
                      final cnt = t['count'] as int;
                      return GestureDetector(
                        onTap: () => _increment(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.outlineVariant),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t['text'] as String,
                                  style: TextStyle(
                                      fontFamily: AppConstants.fontAyat,
                                      fontSize: 16,
                                      color: color.onSurface,
                                      height: 1.8),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('$cnt',
                                    style: TextStyle(
                                        fontFamily: AppConstants.fontCairo,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: color.onPrimaryContainer)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: color.secondaryContainer,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: ['التسبيحة', 'العدد', 'الحسنات']
                                .map((h) => Expanded(
                                      child: Text(h,
                                          style: TextStyle(
                                              fontFamily: AppConstants.fontCairo,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: color.onSecondaryContainer),
                                          textAlign: TextAlign.center),
                                    ))
                                .toList(),
                          ),
                        ),
                        ..._tasbih.asMap().entries.map((entry) {
                          final t = entry.value;
                          final cnt = t['count'] as int;
                          final isLast = entry.key == _tasbih.length - 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                          color: color.outlineVariant
                                              .withValues(alpha: 0.5))),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(t['text'] as String,
                                      style: TextStyle(
                                          fontFamily: AppConstants.fontAyat,
                                          fontSize: 14,
                                          color: color.primary),
                                      textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  child: Text('$cnt',
                                      style: TextStyle(
                                          fontFamily: AppConstants.fontCairo,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  child: Text('${cnt * 10}',
                                      style: TextStyle(
                                          fontFamily: AppConstants.fontCairo,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: color.primary),
                                      textAlign: TextAlign.center),
                                ),
                              ],
                            ),
                          );
                        }),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: color.primaryContainer.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            border: Border(
                                top: BorderSide(color: color.outlineVariant)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text('المجموع',
                                      style: TextStyle(
                                          fontFamily: AppConstants.fontCairo,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text('$_total',
                                      style: TextStyle(
                                          fontFamily: AppConstants.fontCairo,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: color.primary),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text('${_total * 10}',
                                      style: TextStyle(
                                          fontFamily: AppConstants.fontCairo,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: color.primary),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: color.onSecondaryContainer, size: 20),
                        const SizedBox(height: 12),
                        Text(
                          'مَن قالَ: سبحانَ اللهِ وبحمدِهِ، في يومٍ مئةَ مرَّةٍ، حُطَّت خطاياهُ وإن كانت مثلَ زَبَدِ البحرِ',
                          style: TextStyle(
                            fontFamily: AppConstants.fontAyat,
                            fontSize: 16,
                            color: color.onSecondaryContainer,
                            height: 1.9,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        Text('صحيح البخاري',
                            style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontSize: 12,
                                color: color.onSecondaryContainer
                                    .withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const PlayerBox(),
        ],
      ),
    );
  }
}
