import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../l10n/app_localizations.dart';

/// Экран выбора языка
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = context.watch<LanguageService>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Заголовок
          Text(
            l10n.selectLanguage,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Список языков
          ...AppLanguage.values.map((language) => _buildLanguageOption(
            context,
            language: language,
            isSelected: languageService.currentLanguage == language,
            onTap: () => languageService.setLanguage(language),
          )),
        ],
      ),
    );
  }
  
  Widget _buildLanguageOption(
    BuildContext context, {
    required AppLanguage language,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Флаг
              Text(
                language.flag,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              
              // Название языка
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    Text(
                      _getLanguageSubtitle(language),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Галочка
              if (isSelected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getLanguageSubtitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.kk:
        return 'Қазақша';
      case AppLanguage.ru:
        return 'Русский';
    }
  }
}

/// Виджет выбора языка (для использования в других экранах)
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    
    return PopupMenuButton<AppLanguage>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            languageService.currentLanguage.flag,
            style: const TextStyle(fontSize: 24),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
      onSelected: (language) => languageService.setLanguage(language),
      itemBuilder: (context) => AppLanguage.values.map((language) {
        return PopupMenuItem<AppLanguage>(
          value: language,
          child: Row(
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(language.name),
              if (languageService.currentLanguage == language) ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

