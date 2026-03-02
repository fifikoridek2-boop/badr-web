import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/library/library_provider.dart';
import 'package:badr/shared/widgets/player_box.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final provider = context.watch<LibraryProvider>();
    final isRadioPlaying = provider.isRadio && provider.isPlaying;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        title: Text('الراديو',
            style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontWeight: FontWeight.bold,
                color: color.primary)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.primaryContainer,
                      border: Border.all(
                          color: isRadioPlaying
                              ? color.primary
                              : color.outlineVariant,
                          width: isRadioPlaying ? 3 : 1),
                    ),
                    child: Icon(Icons.radio,
                        size: 72,
                        color: isRadioPlaying
                            ? color.primary
                            : color.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  Text('إذاعة القرآن الكريم',
                      style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color.onSurface)),
                  const SizedBox(height: 8),
                  Text('بث مباشر من القاهرة',
                      style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 14,
                          color: color.onSurfaceVariant)),
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    onPressed: () {
                      if (isRadioPlaying) {
                        provider.togglePlay();
                      } else {
                        provider.playRadio();
                      }
                    },
                    icon: Icon(isRadioPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(
                      isRadioPlaying ? 'إيقاف مؤقت' : 'تشغيل البث',
                      style: TextStyle(
                          fontFamily: AppConstants.fontCairo, fontSize: 16),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                    ),
                  ),
                  if (isRadioPlaying) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('يبث الآن',
                            style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontSize: 13,
                                color: color.primary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // بوكس تشغيل القراء فقط (مو الراديو)
          if (!provider.isRadio)
            const PlayerBox(),
        ],
      ),
    );
  }
}
