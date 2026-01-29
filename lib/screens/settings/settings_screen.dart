import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/parental_consent_service.dart';
import '../../models/user_model.dart';
import '../../l10n/app_localizations.dart';
import 'language_screen.dart';

/// Экран настроек
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = context.watch<LanguageService>();
    final authService = context.watch<AuthService>();
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Заголовок
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _getTitle(l10n),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Профиль
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildProfileCard(context, l10n),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Настройки
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _getGeneralTitle(l10n),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            
            // Список настроек
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Язык
                  _buildSettingsItem(
                    context,
                    icon: Icons.language,
                    iconColor: Colors.blue,
                    title: l10n.language,
                    subtitle: languageService.currentLanguage.name,
                    trailing: Text(
                      languageService.currentLanguage.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    onTap: () => _showLanguageSelector(context),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Уведомления
                  _buildSettingsItem(
                    context,
                    icon: Icons.notifications_outlined,
                    iconColor: Colors.orange,
                    title: _getNotificationsTitle(l10n),
                    subtitle: _getNotificationsSubtitle(l10n),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_getComingSoon(l10n))),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Приватность
                  _buildSettingsItem(
                    context,
                    icon: Icons.shield_outlined,
                    iconColor: Colors.green,
                    title: _getPrivacyTitle(l10n),
                    subtitle: _getPrivacySubtitle(l10n),
                    onTap: () {
                      context.push('/privacy-policy');
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Условия использования
                  _buildSettingsItem(
                    context,
                    icon: Icons.description_outlined,
                    iconColor: Colors.blue,
                    title: _getTermsTitle(l10n),
                    subtitle: _getTermsSubtitle(l10n),
                    onTap: () {
                      context.push('/terms-of-use');
                    },
                  ),
                ]),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Поддержка
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _getSupportTitle(l10n),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // О приложении
                  _buildSettingsItem(
                    context,
                    icon: Icons.info_outline,
                    iconColor: Colors.purple,
                    title: _getAboutTitle(l10n),
                    subtitle: 'Anama v1.0.0',
                    onTap: () => _showAboutDialog(context, l10n),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Помощь
                  _buildSettingsItem(
                    context,
                    icon: Icons.help_outline,
                    iconColor: Colors.teal,
                    title: _getHelpTitle(l10n),
                    subtitle: _getHelpSubtitle(l10n),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_getComingSoon(l10n))),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Обратная связь
                  _buildSettingsItem(
                    context,
                    icon: Icons.feedback,
                    iconColor: Colors.purple,
                    title: _getFeedbackTitle(l10n),
                    subtitle: _getFeedbackSubtitle(l10n),
                    onTap: () => context.push('/feedback'),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Жалобы и обращения
                  _buildSettingsItem(
                    context,
                    icon: Icons.report_problem,
                    iconColor: Colors.red,
                    title: _getComplaintTitle(l10n),
                    subtitle: _getComplaintSubtitle(l10n),
                    onTap: () => _showComplaintDialog(context, l10n),
                  ),
                ]),
              ),
            ),
            
            // Раздел для родителей: Управление данными ребенка
            if (authService.currentAnamaUserCached?.role == UserRole.parent) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _getParentControlTitle(l10n),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Отозвать согласие
                    _buildSettingsItem(
                      context,
                      icon: Icons.cancel_outlined,
                      iconColor: Colors.orange,
                      title: _getRevokeConsentTitle(l10n),
                      subtitle: _getRevokeConsentSubtitle(l10n),
                      onTap: () => _showRevokeConsentDialog(context, l10n, authService),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Удалить данные ребенка
                    _buildSettingsItem(
                      context,
                      icon: Icons.delete_forever,
                      iconColor: Colors.red,
                      title: _getDeleteChildDataTitle(l10n),
                      subtitle: _getDeleteChildDataSubtitle(l10n),
                      onTap: () => _showDeleteChildDataDialog(context, l10n, authService),
                    ),
                  ]),
                ),
              ),
            ],
            
            // Право на забвение (для всех пользователей)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _getDataRightsTitle(l10n),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Удалить мои данные (право на забвение)
                  _buildSettingsItem(
                    context,
                    icon: Icons.delete_outline,
                    iconColor: Colors.red,
                    title: _getRightToBeForgottenTitle(l10n),
                    subtitle: _getRightToBeForgottenSubtitle(l10n),
                    onTap: () => _showRightToBeForgottenDialog(context, l10n, authService),
                  ),
                ]),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            
            // Кнопка выхода
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    _getLogoutTitle(l10n),
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getProfileTitle(l10n),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _getProfileSubtitle(l10n),
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const LanguageScreen(),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3C6CF), Color(0xFFE8A5B3)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('A', style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                )),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Anama'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getAboutDescription(l10n)),
            const SizedBox(height: 16),
            Text(
              'v1.0.0',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _signOut(BuildContext context) async {
    final authService = context.read<AuthService>();
    await authService.signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  // Локализованные строки
  String _getTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Баптаулар';
      case 'en': return 'Settings';
      default: return 'Настройки';
    }
  }

  String _getGeneralTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'ЖАЛПЫ';
      case 'en': return 'GENERAL';
      default: return 'ОБЩИЕ';
    }
  }

  String _getNotificationsTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Хабарландырулар';
      case 'en': return 'Notifications';
      default: return 'Уведомления';
    }
  }

  String _getNotificationsSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Push-хабарландыруларды баптау';
      case 'en': return 'Configure push notifications';
      default: return 'Настройка push-уведомлений';
    }
  }

  String _getPrivacyTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Құпиялылық';
      case 'en': return 'Privacy';
      default: return 'Приватность';
    }
  }

  String _getPrivacySubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Деректер мен қауіпсіздік';
      case 'en': return 'Data and security';
      default: return 'Данные и безопасность';
    }
  }
  
  String _getTermsTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Қолдану ережелері';
      case 'en': return 'Terms of use';
      default: return 'Условия использования';
    }
  }
  
  String _getTermsSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Қолдану ережелерін оқу';
      case 'en': return 'Read terms of use';
      default: return 'Прочитать условия использования';
    }
  }

  String _getSupportTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'ҚОЛДАУ';
      case 'en': return 'SUPPORT';
      default: return 'ПОДДЕРЖКА';
    }
  }

  String _getAboutTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Қосымша туралы';
      case 'en': return 'About app';
      default: return 'О приложении';
    }
  }

  String _getHelpTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Көмек';
      case 'en': return 'Help';
      default: return 'Помощь';
    }
  }

  String _getHelpSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'ЖҚС және қолдау';
      case 'en': return 'FAQ and support';
      default: return 'FAQ и поддержка';
    }
  }

  String _getLogoutTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Шығу';
      case 'en': return 'Log out';
      default: return 'Выйти';
    }
  }

  String _getProfileTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Менің профилім';
      case 'en': return 'My Profile';
      default: return 'Мой профиль';
    }
  }

  String _getProfileSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Профильді өңдеу';
      case 'en': return 'Edit profile';
      default: return 'Редактировать профиль';
    }
  }

  String _getAboutDescription(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Anama — балалар мен жасөспірімдердің эмоциялық қауіпсіздігіне арналған AI қосымшасы.';
      case 'en': return 'Anama is an AI app for emotional safety of children and teenagers.';
      default: return 'Anama — AI-приложение для эмоциональной безопасности детей и подростков.';
    }
  }

  String _getComingSoon(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Жақында қолжетімді болады';
      case 'en': return 'Coming soon';
      default: return 'Скоро будет доступно';
    }
  }

  String _getFeedbackTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Кері байланыс';
      default: return 'Обратная связь';
    }
  }

  String _getFeedbackSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Сұрақтар, ұсыныстар, пікірлер';
      default: return 'Вопросы, предложения, отзывы';
    }
  }

  String _getComplaintTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Жалбалар мен өтініштер';
      case 'en': return 'Complaints and appeals';
      default: return 'Жалобы и обращения';
    }
  }

  String _getComplaintSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Деректерді сақтау туралы шағым';
      case 'en': return 'Report data storage issues';
      default: return 'Сообщить о проблемах с хранением данных';
    }
  }

  String _getParentControlTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'БАЛА ДЕРЕКТЕРІН БАСҚАРУ';
      case 'en': return 'CHILD DATA MANAGEMENT';
      default: return 'УПРАВЛЕНИЕ ДАННЫМИ РЕБЕНКА';
    }
  }

  String _getRevokeConsentTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Келісімді кері алу';
      case 'en': return 'Revoke consent';
      default: return 'Отозвать согласие';
    }
  }

  String _getRevokeConsentSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Родительлік келісімді кері алу';
      case 'en': return 'Revoke parental consent';
      default: return 'Отозвать родительское согласие';
    }
  }

  String _getDeleteChildDataTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Баланың деректерін жою';
      case 'en': return 'Delete child data';
      default: return 'Удалить данные ребенка';
    }
  }

  String _getDeleteChildDataSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Барлық деректерді толық жою';
      case 'en': return 'Permanently delete all data';
      default: return 'Полностью удалить все данные';
    }
  }

  String _getDataRightsTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'ДЕРЕКТЕР ҚҰҚЫҚТАРЫ';
      case 'en': return 'DATA RIGHTS';
      default: return 'ПРАВА НА ДАННЫЕ';
    }
  }

  String _getRightToBeForgottenTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Ұмыту құқығы';
      case 'en': return 'Right to be forgotten';
      default: return 'Право на забвение';
    }
  }

  String _getRightToBeForgottenSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Менің деректерімді жою';
      case 'en': return 'Delete my data';
      default: return 'Удалить мои данные';
    }
  }

  /// Показать диалог для жалоб и обращений
  void _showComplaintDialog(BuildContext context, AppLocalizations l10n) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getComplaintTitle(l10n)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.locale.languageCode == 'kk'
                  ? 'Егер сіз деректерді сақтау тәсіліне наразы болсаңыз, өтінішіңізді жіберіңіз:'
                  : 'Если вы недовольны тем, как хранятся ваши данные, отправьте обращение:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: l10n.locale.languageCode == 'kk'
                    ? 'Өтінішіңізді жазыңыз...'
                    : 'Опишите вашу проблему...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.locale.languageCode == 'kk'
                          ? 'Өтініш бос болмауы керек'
                          : 'Обращение не может быть пустым',
                    ),
                  ),
                );
                return;
              }

              // Сохраняем жалобу в Firestore
              try {
                final authService = context.read<AuthService>();
                final user = authService.currentUser;
                
                await FirebaseFirestore.instance.collection('complaints').add({
                  'userId': user?.uid,
                  'userEmail': user?.email,
                  'complaint': controller.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'status': 'new',
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.locale.languageCode == 'kk'
                            ? 'Өтініш жіберілді. Рахмет!'
                            : 'Обращение отправлено. Спасибо!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.locale.languageCode == 'kk'
                            ? 'Қате: $e'
                            : 'Ошибка: $e',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.get('send')),
          ),
        ],
      ),
    );
  }

  /// Показать диалог отзыва согласия
  void _showRevokeConsentDialog(BuildContext context, AppLocalizations l10n, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getRevokeConsentTitle(l10n)),
        content: Text(
          l10n.locale.languageCode == 'kk'
              ? 'Сіз шынымен баланың деректеріне келісімді кері алғыңыз келе ме? Бұл әрекетті кері қайтару мүмкін емес.'
              : 'Вы действительно хотите отозвать согласие на обработку данных ребенка? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                final user = await authService.getCurrentAnamaUser();
                  if (user?.linkedUserId != null) {
                    final consentService = ParentalConsentService();
                    final consent = await consentService.getActiveConsent(user!.linkedUserId!);
                    
                    if (consent != null) {
                      await consentService.revokeConsent(consent.id);
                      
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.locale.languageCode == 'kk'
                                ? 'Келісім кері алынды'
                                : 'Согласие отозвано',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.get('done')),
          ),
        ],
      ),
    );
  }

  /// Показать диалог удаления данных ребенка
  void _showDeleteChildDataDialog(BuildContext context, AppLocalizations l10n, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getDeleteChildDataTitle(l10n)),
        content: Text(
          l10n.locale.languageCode == 'kk'
              ? '⚠️ ЕСКЕРТУ: Бұл әрекет баланың барлық деректерін толығымен жойады. Бұл әрекетті кері қайтару мүмкін емес. Сіз шынымен жалғастырғыңыз келе ме?'
              : '⚠️ ВНИМАНИЕ: Это действие полностью удалит все данные ребенка. Это действие нельзя отменить. Вы действительно хотите продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                final user = await authService.getCurrentAnamaUser();
                if (user?.linkedUserId != null) {
                  // Удаляем данные ребенка
                  await authService.deleteUserData(user!.linkedUserId!);
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.locale.languageCode == 'kk'
                            ? 'Баланың деректері жойылды'
                            : 'Данные ребенка удалены',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_getDeleteChildDataTitle(l10n)),
          ),
        ],
      ),
    );
  }

  /// Показать диалог права на забвение
  void _showRightToBeForgottenDialog(BuildContext context, AppLocalizations l10n, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getRightToBeForgottenTitle(l10n)),
        content: Text(
          l10n.locale.languageCode == 'kk'
              ? '⚠️ ЕСКЕРТУ: Бұл әрекет сіздің барлық деректеріңізді толығымен жойады және аккаунтыңызды өшіреді. Бұл әрекетті кері қайтару мүмкін емес. Сіз шынымен жалғастырғыңыз келе ме?'
              : '⚠️ ВНИМАНИЕ: Это действие полностью удалит все ваши данные и удалит аккаунт. Это действие нельзя отменить. Вы действительно хотите продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                final user = await authService.getCurrentAnamaUser();
                if (user != null) {
                  // Проверяем, является ли пользователь ребенком
                  // Если да, то удаление может выполнить только родитель
                  if (user.role == UserRole.teen && user.parentalConsentGiven) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.locale.languageCode == 'kk'
                                ? 'Баланың деректерін тек ата-ана жоя алады. Настройки → Управление данными ребенка'
                                : 'Данные ребенка может удалить только родитель. Настройки → Управление данными ребенка',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }

                  // Удаляем данные пользователя
                  await authService.deleteUserData(user.uid);
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  // Выходим из аккаунта
                  await authService.signOut();
                  if (!mounted) return;
                  context.go('/login');
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.locale.languageCode == 'kk'
                            ? 'Деректер жойылды'
                            : 'Данные удалены',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_getRightToBeForgottenTitle(l10n)),
          ),
        ],
      ),
    );
  }
}

