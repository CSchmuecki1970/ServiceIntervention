import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum AppTheme {
  light,
  dark,
  blue,
  green,
  purple,
  orange,
  pink,
  dracula,
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeName = 'selectedTheme';
  late Box<String> _box;
  AppTheme _currentTheme = AppTheme.light;

  AppTheme get currentTheme => _currentTheme;

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<String>('theme_box');
    final savedTheme = _box.get(_themeName);
    if (savedTheme != null) {
      _currentTheme = AppTheme.values.firstWhere(
        (theme) => theme.toString() == 'AppTheme.$savedTheme',
        orElse: () => AppTheme.light,
      );
    }
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _box.put(_themeName, theme.name);
    notifyListeners();
  }

  ThemeData getThemeData() {
    switch (_currentTheme) {
      case AppTheme.light:
        return _lightTheme();
      case AppTheme.dark:
        return _darkTheme();
      case AppTheme.blue:
        return _blueTheme();
      case AppTheme.green:
        return _greenTheme();
      case AppTheme.purple:
        return _purpleTheme();
      case AppTheme.orange:
        return _orangeTheme();
      case AppTheme.pink:
        return _pinkTheme();
      case AppTheme.dracula:
        return _draculaTheme();
    }
  }

  ThemeData _lightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.grey[900]!,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _blueTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue[700]!,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _greenTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green[700]!,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _purpleTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purple[700]!,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _orangeTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange[700]!,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _pinkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.pink[700]!,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _draculaTheme() {
    const Color draculaBackground = Color(0xFF282a36);
    const Color draculaPurple = Color(0xFFbd93f9);
    const Color draculaForeground = Color(0xFFf8f8f2);
    
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: draculaPurple,
        brightness: Brightness.dark,
        surface: draculaBackground,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: draculaBackground,
      cardColor: const Color(0xFF44475a),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF44475a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarThemeData(
        backgroundColor: draculaBackground,
        foregroundColor: draculaForeground,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: draculaForeground),
        bodyMedium: TextStyle(color: draculaForeground),
        bodySmall: TextStyle(color: Color(0xFF6272a4)),
        titleLarge: TextStyle(color: draculaForeground),
        titleMedium: TextStyle(color: draculaForeground),
        titleSmall: TextStyle(color: draculaForeground),
      ),
    );
  }
}
