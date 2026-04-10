import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'controllers/settings_controller.dart';
import 'l10n/generated/app_localizations.dart';
import 'pages/main_page.dart';
import 'services/app_cache_service.dart';
import 'theme/app_theme_builder.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppCacheService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _ctrl = SettingsController.instance;
  late ThemeMode _themeMode;
  late Color _themeSeedColor;
  late bool _pureBlackTheme;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _themeMode = _ctrl.themeMode;
    _themeSeedColor = _ctrl.themeSeedColor;
    _pureBlackTheme = _ctrl.pureBlackTheme;
    _locale = _ctrl.locale;
    _ctrl.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    final nextThemeMode = _ctrl.themeMode;
    final nextThemeSeedColor = _ctrl.themeSeedColor;
    final nextPureBlackTheme = _ctrl.pureBlackTheme;
    final nextLocale = _ctrl.locale;
    if (nextThemeMode == _themeMode &&
        nextThemeSeedColor == _themeSeedColor &&
        nextPureBlackTheme == _pureBlackTheme &&
        nextLocale == _locale) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _themeMode = nextThemeMode;
      _themeSeedColor = nextThemeSeedColor;
      _pureBlackTheme = nextPureBlackTheme;
      _locale = nextLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperIsland',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      theme: buildLightTheme(_themeSeedColor),
      darkTheme: buildDarkTheme(_themeSeedColor, pureBlack: _pureBlackTheme),
      themeMode: _themeMode,
      home: const MainPage(),
    );
  }
}
