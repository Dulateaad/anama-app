import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'parent_home_screen.dart';
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';

/// Главный контейнер для родителя с нижней навигацией-островком
class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    ParentHomeScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Важно для островка!
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AnamaBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        isTeen: false,
      ),
    );
  }
}
