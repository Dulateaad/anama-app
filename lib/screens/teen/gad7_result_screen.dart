import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../models/gad7_question.dart';
import '../../widgets/accessible_text.dart';

/// Экран результата теста GAD-7
class Gad7ResultScreen extends StatelessWidget {
  final Gad7Result result;

  const Gad7ResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final severity = result.severity;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Результат теста GAD-7',
          child: const Text('Результат теста GAD-7'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            label: 'Результаты теста на тревожность',
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

  Widget _buildScoreCard(BuildContext context, Gad7Severity severity) {
    return Semantics(
      label: 'Общий балл: ${result.totalScore} из 21. ${severity.getLabel(context)}',
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
              'из 21',
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

  Color _getSeverityColor(Gad7Severity severity) {
    switch (severity) {
      case Gad7Severity.minimal:
        return Colors.green;
      case Gad7Severity.mild:
        return Colors.orange;
      case Gad7Severity.moderate:
        return Colors.deepOrange;
      case Gad7Severity.severe:
        return Colors.red;
    }
  }

}

