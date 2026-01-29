import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'teen_home_screen.dart';
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';

/// Главный контейнер для подростка с нижней навигацией-островком
class TeenShell extends StatefulWidget {
  const TeenShell({super.key});

  @override
  State<TeenShell> createState() => _TeenShellState();
}

class _TeenShellState extends State<TeenShell> {
  int _currentIndex = 0;
  Gender? _userGender;
  bool _isLoading = true;
  
  final List<Widget> _screens = const [
    TeenHomeScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserGender();
  }

  Future<void> _loadUserGender() async {
    try {
      final authService = context.read<AuthService>();
      final user = await authService.getCurrentAnamaUser();
      if (mounted) {
        setState(() {
          _userGender = user?.gender;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  ThemeData _buildThemeForGender(Gender? gender) {
    final isMale = gender == Gender.male;
    
    final primaryColor = isMale ? const Color(0xFF6B7280) : const Color(0xFFF3C6CF);
    final primaryDark = isMale ? const Color(0xFF4B5563) : const Color(0xFFE8A5B3);
    final accentColor = isMale ? const Color(0xFF374151) : const Color(0xFFD4899A);
    final scaffoldBg = isMale ? const Color(0xFFF9FAFB) : const Color(0xFFFDF8F9);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryDark,
        onPrimary: Colors.white,
        primaryContainer: primaryColor,
        onPrimaryContainer: isMale ? Colors.white : const Color(0xFF5D2A3B),
        secondary: accentColor,
        onSecondary: Colors.white,
        secondaryContainer: primaryColor.withOpacity(0.3),
        surface: Colors.white,
        onSurface: const Color(0xFF1A1A1A),
        error: const Color(0xFFE57373),
      ),
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: 'SF Pro Display',
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1A1A),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: BorderSide(color: primaryDark),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryDark, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[200],
        thickness: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Theme(
      data: _buildThemeForGender(_userGender),
      child: Scaffold(
        extendBody: true, // Важно для островка!
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: AnamaBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          isTeen: true,
        ),
      ),
    );
  }
}
