import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

/// Экран чата помощи
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Заголовок
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(l10n),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getSubtitle(l10n),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // SOS Кнопка
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSOSCard(context, l10n),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Контакты помощи
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _getHelpContactsTitle(l10n),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            // Список контактов
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildContactCard(
                    context,
                    icon: Icons.phone,
                    iconColor: Colors.red,
                    title: _getHotline150Title(l10n),
                    subtitle: _getHotline150Subtitle(l10n),
                    onTap: () => _call('150'),
                  ),
                  const SizedBox(height: 12),
                  _buildContactCard(
                    context,
                    icon: Icons.local_hospital,
                    iconColor: Colors.blue,
                    title: _getHotline111Title(l10n),
                    subtitle: _getHotline111Subtitle(l10n),
                    onTap: () => _call('111'),
                  ),
                  const SizedBox(height: 12),
                  _buildContactCard(
                    context,
                    icon: Icons.chat,
                    iconColor: Colors.green,
                    title: _getOnlineChatTitle(l10n),
                    subtitle: _getOnlineChatSubtitle(l10n),
                    onTap: () => _openUrl('https://pomoschryadom.kz'),
                  ),
                  const SizedBox(height: 12),
                  _buildContactCard(
                    context,
                    icon: Icons.psychology,
                    iconColor: Colors.purple,
                    title: _getPsychologistTitle(l10n),
                    subtitle: _getPsychologistSubtitle(l10n),
                    onTap: () {
                      context.push('/psychologists');
                    },
                  ),
                ]),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Информационный блок
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildInfoCard(context, l10n),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      color: Colors.red[50],
      child: InkWell(
        onTap: () => _call('150'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.phone_in_talk,
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
                      'SOS — 150',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSOSSubtitle(l10n),
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.red[300],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getInfoText(l10n),
              style: TextStyle(color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Локализованные строки
  String _getTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Көмек чаты';
      case 'en': return 'Help Chat';
      default: return 'Чат помощи';
    }
  }

  String _getSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Қиын сәтте біз жанындамыз';
      case 'en': return 'We are here for you in difficult times';
      default: return 'Мы рядом в трудный момент';
    }
  }

  String _getHelpContactsTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Көмек контактілері';
      case 'en': return 'Help Contacts';
      default: return 'Контакты помощи';
    }
  }

  String _getSOSSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Тегін, анонимді, тәулік бойы';
      case 'en': return 'Free, anonymous, 24/7';
      default: return 'Бесплатно, анонимно, 24/7';
    }
  }

  String _getHotline150Title(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Сенім телефоны';
      case 'en': return 'Trust Hotline';
      default: return 'Телефон доверия';
    }
  }

  String _getHotline150Subtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return '150 — тегін, анонимді, 24/7';
      case 'en': return '150 — free, anonymous, 24/7';
      default: return '150 — бесплатно, анонимно, 24/7';
    }
  }

  String _getHotline111Title(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Шұғыл психологиялық көмек';
      case 'en': return 'Emergency Psychological Help';
      default: return 'Экстренная психологическая помощь';
    }
  }

  String _getHotline111Subtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return '111 — дереу көмек';
      case 'en': return '111 — immediate help';
      default: return '111 — немедленная помощь';
    }
  }

  String _getOnlineChatTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Онлайн-чат';
      case 'en': return 'Online Chat';
      default: return 'Онлайн-чат';
    }
  }

  String _getOnlineChatSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'pomoschryadom.kz — психологпен жаз';
      case 'en': return 'pomoschryadom.kz — chat with psychologist';
      default: return 'pomoschryadom.kz — напиши психологу';
    }
  }

  String _getPsychologistTitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Психологқа жазылу';
      case 'en': return 'Book a Psychologist';
      default: return 'Запись к психологу';
    }
  }

  String _getPsychologistSubtitle(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Мамандармен консультация';
      case 'en': return 'Consultation with specialists';
      default: return 'Консультация со специалистами';
    }
  }

  String _getComingSoon(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Жақында қолжетімді болады';
      case 'en': return 'Coming soon';
      default: return 'Скоро будет доступно';
    }
  }

  String _getInfoText(AppLocalizations l10n) {
    switch (l10n.locale.languageCode) {
      case 'kk': return 'Сен жалғыз емессің. Барлығын шешуге болады. Біреумен сөйлес.';
      case 'en': return 'You are not alone. Everything can be solved. Talk to someone.';
      default: return 'Ты не один(а). Всё можно решить. Поговори с кем-то.';
    }
  }
}

