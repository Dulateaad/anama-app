import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/future_insight.dart';
import '../l10n/app_localizations.dart';

/// Виджет для отображения инсайта "Future Insights"
/// Показывается после выполнения задания Serve & Return
class FutureInsightWidget extends StatefulWidget {
  final FutureInsight insight;
  final VoidCallback? onClose;

  const FutureInsightWidget({
    super.key,
    required this.insight,
    this.onClose,
  });

  @override
  State<FutureInsightWidget> createState() => _FutureInsightWidgetState();
}

class _FutureInsightWidgetState extends State<FutureInsightWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = l10n.locale.languageCode;
    final isKazakh = languageCode == 'kk';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple[900]!,
                    Colors.indigo[800]!,
                    Colors.blue[900]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Заголовок с иконкой нейрона
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Анимированная иконка мозга/нейрона
                        _buildBrainIcon(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isKazakh ? '🧠 Ғылыми инсайт' : '🧠 Научный инсайт',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.insight.sourceLabel,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.onClose != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: widget.onClose,
                          ),
                      ],
                    ),
                  ),

                  // Научный факт
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.science,
                              color: Colors.cyan[300],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isKazakh ? 'Ғылыми факт:' : 'Научный факт:',
                              style: TextStyle(
                                color: Colors.cyan[300],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.insight.getScientificFact(languageCode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Текст для мамы (проекция на будущее)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.withOpacity(0.2),
                            Colors.orange.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.amber[300],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isKazakh ? 'Болашаққа проекция:' : 'Проекция на будущее:',
                                style: TextStyle(
                                  color: Colors.amber[300],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.insight.getMotherText(languageCode),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ссылка на источник
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () => _openUrl(widget.insight.sourceUrl),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new,
                              color: Colors.lightBlue[200],
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Learn more: Harvard & UpToDate standards',
                              style: TextStyle(
                                color: Colors.lightBlue[200],
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrainIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.purple[300]!.withOpacity(0.3 + value * 0.3),
                Colors.indigo[400]!.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(value * 0.5),
                blurRadius: 15 * value,
                spreadRadius: 2 * value,
              ),
            ],
          ),
          child: Center(
            child: Transform.scale(
              scale: 0.8 + value * 0.2,
              child: const Text(
                '🧠',
                style: TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Кнопка-нейрон для открытия инсайта
class NeuronButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const NeuronButton({
    super.key,
    required this.onPressed,
    this.isActive = true,
  });

  @override
  State<NeuronButton> createState() => _NeuronButtonState();
}

class _NeuronButtonState extends State<NeuronButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + _pulseController.value * 0.15;
        final glow = _pulseController.value * 0.6;

        return GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purple[400]!,
                  Colors.indigo[600]!,
                  Colors.blue[800]!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(glow),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.blue.withOpacity(glow * 0.5),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Transform.scale(
              scale: scale,
              child: const Center(
                child: Text(
                  '🧠',
                  style: TextStyle(fontSize: 36),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Диалог для показа инсайта
Future<void> showFutureInsightDialog(
  BuildContext context,
  FutureInsight insight,
) async {
  await showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: FutureInsightWidget(
        insight: insight,
        onClose: () => Navigator.of(context).pop(),
      ),
    ),
  );
}

