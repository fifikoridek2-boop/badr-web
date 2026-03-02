import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/home/home_provider.dart';
import 'features/quran/quran_provider.dart';
import 'features/azkar/azkar_provider.dart';
import 'features/library/library_provider.dart';
import 'features/prayer/prayer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

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
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (_) => AzkarProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
      ],
      child: const BadrApp(),
    ),
  );
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
        textTheme: materialTheme.light().textTheme.apply(
          fontFamily: AppConstants.fontCairo,
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            TextStyle(fontFamily: AppConstants.fontCairo, fontSize: 12),
          ),
        ),
      ),
      darkTheme: materialTheme.dark().copyWith(
        textTheme: materialTheme.dark().textTheme.apply(
          fontFamily: AppConstants.fontCairo,
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            TextStyle(fontFamily: AppConstants.fontCairo, fontSize: 12),
          ),
        ),
      ),
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider(String saved) : _themeMode = _fromString(saved);

  ThemeMode get themeMode => _themeMode;

  static ThemeMode _fromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(String value) async {
    _themeMode = _fromString(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, value);
    notifyListeners();
  }
}
