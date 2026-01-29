import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

/// Сервис управления языком приложения
class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  
  AppLanguage _currentLanguage = AppLanguage.en; // По умолчанию English
  
  AppLanguage get currentLanguage => _currentLanguage;
  Locale get locale => _currentLanguage.locale;
  
  LanguageService() {
    _loadLanguage();
  }
  
  /// Загрузить сохраненный язык
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString(_languageKey);
      
      if (langCode != null) {
        _currentLanguage = AppLanguage.values.firstWhere(
          (l) => l.code == langCode,
          orElse: () => AppLanguage.en,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error loading language: $e');
    }
  }
  
  /// Изменить язык
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    
    _currentLanguage = language;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);
    } catch (e) {
      print('Error saving language: $e');
    }
  }
  
  /// Список всех языков
  List<AppLanguage> get availableLanguages => AppLanguage.values;
}

