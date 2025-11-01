import 'package:flutter/material.dart';

class AppSettings with ChangeNotifier {
  bool _isEnglish = false;
  ThemeMode _themeMode = ThemeMode.system;

  bool get isEnglish => _isEnglish;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _isEnglish ? const Locale('en') : const Locale('ar');
  TextDirection get direction => _isEnglish ? TextDirection.ltr : TextDirection.rtl;

  void setEnglish(bool value) {
    if (_isEnglish == value) return;
    _isEnglish = value;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}
