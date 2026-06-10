import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/home/home_provider.dart';
import 'features/quran/quran_provider.dart';
import 'features/azkar/azkar_provider.dart';
import 'features/library/library_provider.dart';
import 'features/prayer/prayer_provider.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // التقاط أخطاء Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _showErrorOverlay(details.exceptionAsString(), details.stack.toString());
    };

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(AppConstants.keyThemeMode) ?? 'auto';

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(savedTheme)),
          ChangeNotifierProvider(create: (_) => HomeProvider()),
          ChangeNotifierProvider(create: (_) => QuranProvider()),
          ChangeNotifierProvider(create: (_) => AzkarProvider()),
          ChangeNotifierProvider(create: (_) => LibraryProvider()),
          ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ],
        child: const BadrApp(),
      ),
    );
  }, (error, stack) {
    // التقاط الأخطاء غير المتوقعة وعرضها
    _showErrorOverlay(error.toString(), stack.toString());
  });
}

// عرض الخطأ على الشاشة
void _showErrorOverlay(String error, String stack) {
  runApp(MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔴 CRASH',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Stack Trace:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  stack.length > 3000 ? stack.substring(0, 3000) + '...' : stack,
                  style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ));
}

class BadrApp extends StatelessWidget {
  const BadrApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final materialTheme = MaterialTheme(
      Typography.material2021().black.apply(fontFamily: AppConstants.fontCairo),
    );

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: materialTheme.light().copyWith(
        textTheme: materialTheme.light().textTheme.apply(fontFamily: AppConstants.fontCairo),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            TextStyle(fontFamily: AppConstants.fontCairo, fontSize: 12),
          ),
        ),
      ),
      darkTheme: materialTheme.dark().copyWith(
        textTheme: materialTheme.dark().textTheme.apply(fontFamily: AppConstants.fontCairo),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            TextStyle(fontFamily: AppConstants.fontCairo, fontSize: 12),
          ),
        ),
      ),
      themeMode: themeProvider.themeMode,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const SplashScreen(),
    );
  }
}
