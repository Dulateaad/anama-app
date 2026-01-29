import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/privacy_constants.dart';
import '../../l10n/app_localizations.dart';

/// Экран с Политикой конфиденциальности
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    final isKazakh = langCode == 'kk';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isKazakh ? 'Құпиялылық саясаты' : 'Политика конфиденциальности',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              isKazakh ? 'Құпиялылық саясаты' : 'ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isKazakh ? '«Anama» мобильді қосымшасы' : '«Anama»',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isKazakh 
                ? 'Қолданыстағы күні: ${PrivacyConstants.policyEffectiveDate}'
                : 'Дата вступления в силу: ${PrivacyConstants.policyEffectiveDate}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            
            // Оператор
            _buildSection(
              context,
              title: isKazakh ? '2. Жеке деректер операторы' : '2. Оператор персональных данных',
              content: [
                _buildParagraph(isKazakh 
                  ? 'Оператор: ${PrivacyConstants.operatorName}'
                  : 'Оператор: ${PrivacyConstants.operatorName}'),
                if (PrivacyConstants.operatorEmail.isNotEmpty)
                  _buildParagraph(isKazakh
                    ? 'Электрондық пошта: ${PrivacyConstants.operatorEmail}'
                    : 'Электронная почта: ${PrivacyConstants.operatorEmail}'),
                if (PrivacyConstants.operatorPhone != null)
                  _buildParagraph(isKazakh
                    ? 'Телефон: ${PrivacyConstants.operatorPhone}'
                    : 'Телефон: ${PrivacyConstants.operatorPhone}'),
              ],
            ),
            
            // Контакты
            _buildSection(
              context,
              title: isKazakh ? '19. Байланыс ақпараты' : '19. Контактная информация',
              content: [
                _buildParagraph(isKazakh
                  ? 'Жеке деректерді өңдеу бойынша барлық сұрақтар бойынша Операторға хабарласуға болады:'
                  : 'По всем вопросам, связанным с обработкой персональных данных, вы можете связаться с Оператором:'),
                const SizedBox(height: 8),
                if (PrivacyConstants.operatorEmail.isNotEmpty)
                  _buildParagraph('📧 ${PrivacyConstants.operatorEmail}'),
                if (PrivacyConstants.operatorPhone != null)
                  _buildParagraph('📱 ${PrivacyConstants.operatorPhone}'),
              ],
            ),
            
            // Основные положения
            _buildSection(
              context,
              title: isKazakh ? '1. Жалпы ережелер' : '1. Общие положения',
              content: [
                _buildParagraph(isKazakh
                  ? 'Бұл Құпиялылық саясаты «Anama» мобильді қосымшасының пайдаланушыларының жеке деректерін жинау, пайдалану, сақтау және қорғау тәртібін анықтайды.'
                  : 'Настоящая Политика конфиденциальности определяет порядок сбора, использования, хранения и защиты персональных данных пользователей мобильного приложения Anama.'),
                _buildParagraph(isKazakh
                  ? 'Қосымша медициналық қызмет емес, диагностика жүргізбейді және психолог, психиатр немесе басқа медициналық маманның консультациясын ауыстырмайды.'
                  : 'Приложение не является медицинским сервисом, не осуществляет диагностику и не заменяет консультацию психолога, психиатра или иного медицинского специалиста.'),
              ],
            ),
            
            // Права пользователей
            _buildSection(
              context,
              title: isKazakh ? '16. Пайдаланушылардың құқықтары' : '16. Права пользователей',
              content: [
                _buildParagraph(isKazakh
                  ? 'Ата-ана (заңды өкіл) келесі құқықтарға ие:'
                  : 'Родитель (законный представитель) обладает следующими правами:'),
                _buildBulletPoint(isKazakh
                  ? 'Баланың деректерінің өңделуі туралы ақпарат алу'
                  : 'Получать информацию об обработке данных ребенка'),
                _buildBulletPoint(isKazakh
                  ? 'Бұрын берілген келісімді кері қайтару'
                  : 'Отзывать ранее предоставленное согласие'),
                _buildBulletPoint(isKazakh
                  ? 'Баланың деректерін жою немесе өзгертуді талап ету'
                  : 'Требовать удаление данных ребенка или изменение их содержания'),
              ],
            ),
            
            // Удаление данных
            _buildSection(
              context,
              title: isKazakh ? '10. Деректерді сақтау, өзгерту және жою' : '10. Хранение, изменение и удаление данных',
              content: [
                _buildParagraph(isKazakh
                  ? 'Жеке деректерді жою (немесе өзгерту) қосымша параметрлері арқылы немесе Операторға электрондық пошта арқылы сұрау жіберу арқылы басталуы мүмкін.'
                  : 'Удаление (или изменение) персональных данных может быть инициировано через настройки Приложения либо путём направления запроса на контактный электронный адрес Оператора.'),
                _buildParagraph(isKazakh
                  ? 'Сұраулар алынған күннен бастап 30 күнтізбелік күн ішінде өңделеді.'
                  : 'Запросы обрабатываются в срок не более 30 календарных дней с момента получения.'),
              ],
            ),
            
            // Версия
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isKazakh
                        ? 'Нұсқа: ${PrivacyConstants.policyVersion}'
                        : 'Версия: ${PrivacyConstants.policyVersion}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Ссылка на Условия использования
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description_outlined, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        isKazakh ? 'Қолдану ережелері' : 'Условия использования',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isKazakh
                      ? 'Қосымшаны пайдалану ережелері мен шарттарын оқыңыз.'
                      : 'Ознакомьтесь с правилами и условиями использования приложения.',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/terms-of-use'),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(
                      isKazakh ? 'Оқу' : 'Читать',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Предупреждение о заполнении контактов
            if (PrivacyConstants.operatorName.contains('_') || 
                PrivacyConstants.operatorEmail.contains('_'))
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          isKazakh ? 'Назар аударыңыз!' : 'Внимание!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isKazakh
                        ? 'Оператордың байланыс деректерін толтыру қажет. lib/constants/privacy_constants.dart файлын қараңыз.'
                        : 'Требуется заполнить контактные данные оператора. См. файл lib/constants/privacy_constants.dart',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...content,
      ],
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

