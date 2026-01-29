import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/language_service.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/register_psychologist_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/teen_forgot_password_screen.dart';
import 'screens/auth/age_gate_screen.dart';
import 'screens/auth/parental_consent_screen.dart';
import 'models/teen_registration_data.dart';
import 'models/user_model.dart';
import 'screens/teen/teen_shell.dart';
import 'screens/parent/parent_shell.dart';
import 'screens/parent/link_account_screen.dart';
import 'screens/settings/language_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/legal/terms_of_use_screen.dart';
import 'screens/settings/feedback_screen.dart';
import 'screens/teen/phq9_test_screen.dart';
import 'screens/teen/phq9_result_screen.dart';
import 'screens/teen/gad7_test_screen.dart';
import 'screens/teen/gad7_result_screen.dart';
import 'screens/teen/traffic_light_test_screen.dart';
import 'screens/teen/traffic_light_result_screen.dart';
import 'screens/psychologists/psychologists_list_screen.dart';
import 'screens/psychologists/psychologist_chat_screen.dart';
import 'screens/psychologists/chats_list_screen.dart';
import 'screens/psychologists/psychologist_shell.dart';
import 'screens/psychologists/psychologist_chats_screen.dart';
import 'screens/psychologists/psychologist_profile_screen.dart';
import 'screens/psychologists/psychologist_user_chat_screen.dart';
import 'models/phq9_question.dart';
import 'models/psychologist_model.dart';
import 'models/gad7_question.dart';
import 'models/traffic_light_question.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Инициализация Firebase Analytics
  // На web пропускаем: 404 (App not found), 400 (Installations) при отсутствии measurementId в Console
  if (!kIsWeb) {
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      debugPrint('⚠️ Analytics init failed: $e');
    }
  }
  
  // Инициализация уведомлений (только для мобильных)
  if (!kIsWeb) {
    final notificationService = NotificationService();
    await notificationService.initialize();
  }
  
  runApp(const AnamaApp());
}

class AnamaApp extends StatelessWidget {
  const AnamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageService>(create: (_) => LanguageService()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: Consumer<LanguageService>(
        builder: (context, languageService, _) {
          return MaterialApp.router(
            title: 'Anama',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            routerConfig: _router,
            
            // Локализация
            locale: languageService.locale,
            supportedLocales: const [
              Locale('en', 'US'), // English (default)
              Locale('ru', 'RU'), // Русский
              Locale('kk', 'KZ'), // Қазақша
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }

      ThemeData _buildTheme({Gender? gender}) {
    // Для мальчиков - серая тема, для девочек - розовая
    final isMale = gender == Gender.male;
    
    final primaryColor = isMale ? const Color(0xFF6B7280) : const Color(0xFFF3C6CF);
    final primaryDark = isMale ? const Color(0xFF4B5563) : const Color(0xFFE8A5B3);
    final accentColor = isMale ? const Color(0xFF374151) : const Color(0xFFD4899A);
    final scaffoldBg = isMale ? const Color(0xFFF9FAFB) : const Color(0xFFFDF8F9);
    
    // Цвета текста с достаточной контрастностью (WCAG AA)
    final textPrimary = isMale ? const Color(0xFF111827) : const Color(0xFF1A1A1A); // Почти черный для контраста
    final textSecondary = isMale ? const Color(0xFF4B5563) : const Color(0xFF4B5563); // Темно-серый
    
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
        onSurface: textPrimary, // Используем контрастный цвет
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
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5), // Увеличенная толщина для видимости
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5), // Увеличенная толщина
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryDark, width: 2.5), // Увеличенная толщина для фокуса
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

  static final GoRouter _router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Авторизация
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/register-psychologist',
        builder: (context, state) => const RegisterPsychologistScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/teen-forgot-password',
        builder: (context, state) => const TeenForgotPasswordScreen(),
      ),
      
      // Age Gate (для проекта Anama)
      GoRoute(
        path: '/age-gate',
        builder: (context, state) {
          final registrationData = state.extra as TeenRegistrationData?;
          return AgeGateScreen(registrationData: registrationData);
        },
      ),
      
      // Parental Consent (для проекта Anama)
      GoRoute(
        path: '/parental-consent',
        builder: (context, state) {
          final registrationData = state.extra as TeenRegistrationData?;
          return ParentalConsentScreen(registrationData: registrationData);
        },
      ),
      
      // Подросток
      GoRoute(
        path: '/teen',
        builder: (context, state) => const TeenShell(),
      ),
      
      // Родитель
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentShell(),
      ),
      GoRoute(
        path: '/parent/link',
        builder: (context, state) => const LinkAccountScreen(),
      ),
      
      // Настройки
      GoRoute(
        path: '/settings/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-of-use',
        builder: (context, state) => const TermsOfUseScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      
      // Клинические тесты
      GoRoute(
        path: '/phq9-test',
        builder: (context, state) => const Phq9TestScreen(),
      ),
      GoRoute(
        path: '/phq9-result',
        builder: (context, state) {
          final result = state.extra as Phq9Result;
          return Phq9ResultScreen(result: result);
        },
      ),
      GoRoute(
        path: '/gad7-test',
        builder: (context, state) => const Gad7TestScreen(),
      ),
      GoRoute(
        path: '/gad7-result',
        builder: (context, state) {
          final result = state.extra as Gad7Result;
          return Gad7ResultScreen(result: result);
        },
      ),
      GoRoute(
        path: '/traffic-light-test',
        builder: (context, state) => const TrafficLightTestScreen(),
      ),
      GoRoute(
        path: '/traffic-light-result',
        builder: (context, state) {
          final result = state.extra as TrafficLightResult;
          return TrafficLightResultScreen(result: result);
        },
      ),
      
      // Психологи
      GoRoute(
        path: '/psychologist',
        builder: (context, state) => const PsychologistShell(),
      ),
      GoRoute(
        path: '/psychologists',
        builder: (context, state) => const PsychologistsListScreen(),
      ),
      GoRoute(
        path: '/psychologist-chat',
        builder: (context, state) {
          final psychologist = state.extra as Psychologist;
          return PsychologistChatScreen(psychologist: psychologist);
        },
      ),
      GoRoute(
        path: '/psychologist-user-chat',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return PsychologistUserChatScreen(
            userId: data['userId'] as String,
            userName: data['userName'] as String,
            chatId: data['chatId'] as String,
          );
        },
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatsListScreen(),
      ),
    ],
  );
}
