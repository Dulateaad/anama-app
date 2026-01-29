import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/survey_response.dart';
import '../services/safety_alert_service.dart';
import '../l10n/app_localizations.dart';

/// Виджет карточки поддержки Safety Alert
class SupportCardWidget extends StatelessWidget {
  final RiskLevel riskLevel;
  final String? childName;
  final String? specificAnalysis; // Конкретный анализ от ИИ
  final VoidCallback? onPsychologistTap;

  const SupportCardWidget({
    super.key,
    required this.riskLevel,
    this.childName,
    this.specificAnalysis,
    this.onPsychologistTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = l10n.locale.languageCode;
    final isKazakh = languageCode == 'kk';
    
    final cards = SafetyAlertService.getSupportCards(languageCode);
    final card = cards[riskLevel]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _getGradient(riskLevel),
        boxShadow: [
          BoxShadow(
            color: _getColor(riskLevel).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      card.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (childName != null)
                        Text(
                          childName!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Срочное сообщение для красного уровня
          if (card.urgentMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.red[900],
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.urgentMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Анализ ИИ
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Colors.white.withOpacity(0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isKazakh ? 'ИИ талдауы' : 'Анализ ИИ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  specificAnalysis ?? card.aiAnalysis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Что делать
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.actionTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card.actionText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Фразы-помощники
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: card.suggestedPhrases.map((phrase) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          phrase,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ),
          ),

          // Кнопки действий
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Кнопка связи с психологом
                if (card.showPsychologistButton)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onPsychologistTap ?? () => _contactPsychologist(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _getColor(riskLevel),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.psychology),
                      label: Text(
                        isKazakh 
                          ? '🧠 Психологпен байланысу'
                          : '🧠 Связаться с психологом',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                if (card.showPsychologistButton && card.showEmergencyNumbers)
                  const SizedBox(height: 12),

                // Экстренные номера
                if (card.showEmergencyNumbers)
                  _buildEmergencyNumbers(context, isKazakh),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumbers(BuildContext context, bool isKazakh) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            isKazakh ? 'Шұғыл желілер' : 'Экстренные службы',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEmergencyButton(
                  context,
                  number: '111',
                  label: isKazakh ? 'Сенім телефоны' : 'Телефон доверия',
                  icon: Icons.phone_in_talk,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEmergencyButton(
                  context,
                  number: '112',
                  label: isKazakh ? 'Жедел көмек' : 'Экстренная помощь',
                  icon: Icons.emergency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildEmergencyButton(
                  context,
                  number: '150',
                  label: isKazakh ? 'Балалар құқығы' : 'Защита детей',
                  icon: Icons.child_care,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEmergencyButton(
                  context,
                  number: '102',
                  label: isKazakh ? 'Полиция' : 'Полиция',
                  icon: Icons.local_police,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(
    BuildContext context, {
    required String number,
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _callNumber(number),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.red[700]),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _contactPsychologist(BuildContext context) {
    context.push('/psychologists');
  }

  Color _getColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:
        return Colors.green[700]!;
      case RiskLevel.yellow:
        return Colors.orange[700]!;
      case RiskLevel.red:
        return Colors.red[700]!;
    }
  }

  LinearGradient _getGradient(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[600]!, Colors.green[800]!],
        );
      case RiskLevel.yellow:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange[600]!, Colors.orange[800]!],
        );
      case RiskLevel.red:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red[600]!, Colors.red[900]!],
        );
    }
  }
}

/// Компактная версия карточки для уведомлений
class CompactSupportCard extends StatelessWidget {
  final RiskLevel riskLevel;
  final String message;
  final VoidCallback? onTap;

  const CompactSupportCard({
    super.key,
    required this.riskLevel,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _getBackgroundColor(riskLevel),
          border: Border.all(color: _getBorderColor(riskLevel)),
        ),
        child: Row(
          children: [
            Text(
              _getEmoji(riskLevel),
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitle(context, riskLevel),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(riskLevel),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: _getTextColor(riskLevel).withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _getTextColor(riskLevel).withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmoji(RiskLevel level) {
    switch (level) {
      case RiskLevel.green: return '🟢';
      case RiskLevel.yellow: return '🟡';
      case RiskLevel.red: return '🔴';
    }
  }

  String _getTitle(BuildContext context, RiskLevel level) {
    final l10n = AppLocalizations.of(context);
    final isKazakh = l10n.locale.languageCode == 'kk';
    
    switch (level) {
      case RiskLevel.green: 
        return isKazakh ? 'Бәрі жақсы' : 'Всё хорошо';
      case RiskLevel.yellow: 
        return isKazakh ? 'Назар аударыңыз' : 'Обратите внимание';
      case RiskLevel.red: 
        return isKazakh ? 'Шұғыл!' : 'Срочно!';
    }
  }

  Color _getBackgroundColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.green: return Colors.green[50]!;
      case RiskLevel.yellow: return Colors.orange[50]!;
      case RiskLevel.red: return Colors.red[50]!;
    }
  }

  Color _getBorderColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.green: return Colors.green[200]!;
      case RiskLevel.yellow: return Colors.orange[200]!;
      case RiskLevel.red: return Colors.red[200]!;
    }
  }

  Color _getTextColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.green: return Colors.green[900]!;
      case RiskLevel.yellow: return Colors.orange[900]!;
      case RiskLevel.red: return Colors.red[900]!;
    }
  }
}

