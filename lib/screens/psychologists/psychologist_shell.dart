import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'psychologist_chats_screen.dart';
import 'psychologist_profile_screen.dart';

/// Оболочка для интерфейса психолога
class PsychologistShell extends StatefulWidget {
  const PsychologistShell({super.key});

  @override
  State<PsychologistShell> createState() => _PsychologistShellState();
}

class _PsychologistShellState extends State<PsychologistShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKazakh = l10n.locale.languageCode == 'kk';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          PsychologistChatsScreen(), // Список чатов с пользователями
          PsychologistProfileScreen(), // Профиль психолога
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: isKazakh ? 'Чаттар' : 'Чаты',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: isKazakh ? 'Профиль' : 'Профиль',
          ),
        ],
      ),
    );
  }
}

