import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../models/phq9_question.dart';
import '../../services/auth_service.dart';
import '../../services/clinical_test_service.dart';
import 'package:provider/provider.dart';

/// Экран результата теста PHQ-9
class Phq9ResultScreen extends StatelessWidget {
  final Phq9Result result;

  const Phq9ResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final severity = result.severity;
    final riskLevel = severity.riskLevel;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Результат теста PHQ-9',
          child: const Text('Результат теста PHQ-9'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            label: 'Результаты теста на депрессию',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Общий балл
                _buildScoreCard(context, severity),
                
                const SizedBox(height: 24),
                
                // Информация о том, что результат отправлен родителю
                _buildInfoCard(context),
                
                const SizedBox(height: 24),
                
                // Кнопка возврата
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, Phq9Severity severity) {
    return Semantics(
      label: 'Общий балл: ${result.totalScore} из 27. ${severity.getLabel(context)}',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _getSeverityColor(severity).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getSeverityColor(severity),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '${result.totalScore}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getSeverityColor(severity),
              ),
            ),
            Text(
              'из 27',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  severity.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Text(
                  severity.getLabel(context),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getSeverityColor(severity),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Semantics(
      label: 'Результат теста отправлен родителю. Рекомендации будут доступны родителю.',
      child: Card(
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue[700], size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Результат отправлен родителю',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Родитель получит подробные рекомендации и сможет помочь тебе',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Вернуться на главный экран',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF3C6CF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(0, 56),
          ),
          child: const Text(
            'Вернуться на главный',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(Phq9Severity severity) {
    switch (severity) {
      case Phq9Severity.minimal:
        return Colors.green;
      case Phq9Severity.mild:
        return Colors.orange;
      case Phq9Severity.moderate:
      case Phq9Severity.moderatelySevere:
        return Colors.deepOrange;
      case Phq9Severity.severe:
        return Colors.red;
    }
  }

}

