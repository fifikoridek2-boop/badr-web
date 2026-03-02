import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badr/core/constants/app_constants.dart';
import 'package:badr/features/home/home_screen.dart';
import 'package:badr/features/quran/quran_screen.dart';
import 'package:badr/features/azkar/azkar_screen.dart';
import 'package:badr/features/library/library_screen.dart';
import 'package:badr/features/settings/settings_screen.dart';
import 'package:badr/features/library/library_provider.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const QuranScreen(),
    const AzkarScreen(),
    const LibraryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final provider = context.watch<LibraryProvider>();

    // هل نحن في صفحة الراديو؟
    final isRadioPage = _currentIndex == 3;

    // شرط إظهار البوكس:
    // - إذا يوجد تشغيل
    // - في صفحة الراديو: نخفي بوكس الراديو فقط، نبقي بوكس القراء
    final showPlayer = provider.currentSurahName.isNotEmpty &&
        !(isRadioPage && provider.isRadio);

    return Scaffold(
      backgroundColor: color.surface,
      body: Column(
        children: [
          Expanded(child: _screens[_currentIndex]),

          // ─── Player Box ───
          if (showPlayer)
            _PlayerBox(key: ValueKey(provider.isRadio)),

          // ─── Bottom Nav ───
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'المصحف',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'الأذكار',
              ),
              NavigationDestination(
                icon: Icon(Icons.headphones_outlined),
                selectedIcon: Icon(Icons.headphones),
                label: 'المكتبة',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'الإعدادات',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
//  Player Box
// ═══════════════════════════════════════
class _PlayerBox extends StatefulWidget {
  const _PlayerBox({super.key});

  @override
  State<_PlayerBox> createState() => _PlayerBoxState();
}

class _PlayerBoxState extends State<_PlayerBox>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _heightAnim;

  static const double _miniHeight = 72;
  static const double _expandedHeight = 260;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnim = Tween<double>(
      begin: _miniHeight,
      end: _expandedHeight,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final color = Theme.of(context).colorScheme;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -200 && !_isExpanded) _toggle();
        if (details.primaryVelocity! > 200 && _isExpanded) _toggle();
      },
      child: AnimatedBuilder(
        animation: _heightAnim,
        builder: (context, _) {
          return Container(
            height: _heightAnim.value,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            decoration: BoxDecoration(
              color: color.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.shadow.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  // ─── خط السحب (دائماً ظاهر) ───
                  GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: color.onPrimaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ─── المحتوى ───
                  Expanded(
                    child: _isExpanded
                        ? _buildExpanded(provider, color)
                        : _buildMini(provider, color),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Mini ───
  Widget _buildMini(LibraryProvider provider, ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Icon(
            provider.isRadio ? Icons.radio : Icons.headphones,
            color: color.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _toggle,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.currentSurahName,
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!provider.isRadio && provider.currentReciter != null)
                    Text(
                      provider.currentReciter!.reciterName,
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 11,
                        color: color.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              provider.isPlaying ? Icons.pause : Icons.play_arrow,
              color: color.onPrimaryContainer,
            ),
            onPressed: () => provider.togglePlay(),
          ),
          IconButton(
            icon: Icon(Icons.close, color: color.onPrimaryContainer, size: 20),
            onPressed: () => provider.stop(),
          ),
        ],
      ),
    );
  }

  // ─── Expanded ───
  Widget _buildExpanded(LibraryProvider provider, ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم السورة والقارئ + زر الإغلاق
          Row(
            children: [
              Icon(
                provider.isRadio ? Icons.radio : Icons.headphones,
                color: color.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.currentSurahName,
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color.onPrimaryContainer,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!provider.isRadio && provider.currentReciter != null)
                      Text(
                        provider.currentReciter!.reciterName,
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 12,
                          color: color.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: color.onPrimaryContainer),
                onPressed: () {
                  _toggle();
                  provider.stop();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // شريط المدة أو الراديو
          if (provider.isRadio)
            _buildRadioBar(color)
          else
            _buildProgressBar(provider, color),

          const SizedBox(height: 20),

          // زر التشغيل فقط
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.onPrimaryContainer,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  provider.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: color.primaryContainer,
                  size: 30,
                ),
                onPressed: () => provider.togglePlay(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(LibraryProvider provider, ColorScheme color) {
    return StreamBuilder<Duration>(
      stream: provider.audioService.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = provider.audioService.duration ?? Duration.zero;
        final progress = duration.inSeconds > 0
            ? (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0)
            : 0.0;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12),
                      activeTrackColor: color.onPrimaryContainer,
                      inactiveTrackColor:
                          color.onPrimaryContainer.withValues(alpha: 0.3),
                      thumbColor: color.onPrimaryContainer,
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (v) {
                        final newPos = Duration(
                            seconds: (v * duration.inSeconds).round());
                        provider.audioService.seek(newPos);
                      },
                    ),
                  ),
                ),
                // أيقونة تحميل فقط
                Icon(Icons.download_outlined,
                    color: color.onPrimaryContainer.withValues(alpha: 0.7),
                    size: 20),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position),
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 11,
                        color:
                            color.onPrimaryContainer.withValues(alpha: 0.7))),
                Text(_formatDuration(duration),
                    style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 11,
                        color: color.onPrimaryContainer
                            .withValues(alpha: 0.7))),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRadioBar(ColorScheme color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.onPrimaryContainer,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text('بث مباشر',
            style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 12,
                color: color.onPrimaryContainer)),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            backgroundColor:
                color.onPrimaryContainer.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color.onPrimaryContainer),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
