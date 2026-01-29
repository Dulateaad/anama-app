import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../models/traffic_light_question.dart';
import '../../models/survey_response.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/accessible_text.dart';

/// Экран результатов теста "Светофор"
class TrafficLightResultScreen extends StatelessWidget {
  final TrafficLightResult result;

  const TrafficLightResultScreen({
    super.key,
    required this.result,
  });

  Color _getRiskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.green:
        return const Color(0xFF00C853);
      case RiskLevel.yellow:
        return const Color(0xFFFFB300);
      case RiskLevel.red:
        return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final riskColor = _getRiskColor(result.riskLevel);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('trafficLightResultTitle')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Дисклеймер
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.get('trafficLightDisclaimer'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Общий балл
              Semantics(
                label: '${l10n.get('trafficLightTotalScore')}: ${result.totalScore} из 21. ${result.riskLevel.title}',
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: riskColor, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        result.riskLevel.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.riskLevel.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.get('trafficLightTotalScore')}: ${result.totalScore} / 21',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Баллы по блокам
              Text(
                'Баллы по блокам:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildBlockCard(
                context,
                l10n.get('trafficLightBlockA'),
                result.blockAScore,
                9,
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildBlockCard(
                context,
                l10n.get('trafficLightBlockB'),
                result.blockBScore,
                6,
                Colors.orange,
              ),
              const SizedBox(height: 8),
              _buildBlockCard(
                context,
                l10n.get('trafficLightBlockC'),
                result.blockCScore,
                6,
                Colors.purple,
              ),

              const SizedBox(height: 24),

              // Описание уровня риска
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.riskLevel.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

              const SizedBox(height: 24),

              // Кнопка закрыть
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3C6CF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    l10n.get('done'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockCard(
    BuildContext context,
    String title,
    int score,
    int maxScore,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              '$score / $maxScore',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

