import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/genius_card.dart';
import '../../models/survey_response.dart';
import '../../services/notification_service.dart';

/// Экран "Гении в зоне риска" — стильная карточка для скриншота
class GeniusCardScreen extends StatefulWidget {
  final RiskLevel riskLevel;
  final int? userAge;
  final String? parentId; // Для уведомлений
  final String? teenId;

  const GeniusCardScreen({
    super.key,
    required this.riskLevel,
    this.userAge,
    this.parentId,
    this.teenId,
  });

  @override
  State<GeniusCardScreen> createState() => _GeniusCardScreenState();
}

class _GeniusCardScreenState extends State<GeniusCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late GeniusCard _card;

  @override
  void initState() {
    super.initState();
    _card = GeniusCardsDatabase.getCardForRisk(
      widget.riskLevel,
      age: widget.userAge,
    );

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Отправляем уведомление родителю для желтой/красной зоны
    _sendParentNotification();
  }

  void _sendParentNotification() async {
    if (widget.parentId == null || widget.teenId == null) return;

    if (widget.riskLevel == RiskLevel.yellow) {
      // Уведомление о тревожном состоянии
      await NotificationService().sendAlertToParent(
        parentId: widget.parentId!,
        title: '⚠️ Тревожное состояние',
        body: 'У ребенка желтый уровень. Рекомендуем обратить внимание.',
        riskLevel: RiskLevel.yellow,
      );
    } else if (widget.riskLevel == RiskLevel.red) {
      // Критическое уведомление
      await NotificationService().sendAlertToParent(
        parentId: widget.parentId!,
        title: '🔴 Критический уровень',
        body: 'Требуется немедленное внимание. Откройте приложение.',
        riskLevel: RiskLevel.red,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _getBackgroundGradient(),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Кнопка закрытия
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ),
              ),

              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildCard(),
                  ),
                ),
              ),

              // Нижние кнопки
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Кнопка "Сохранить скриншот"
                    _buildScreenshotHint(),
                    const SizedBox(height: 16),
                    // Для красной зоны — кнопка консультации
                    if (widget.riskLevel == RiskLevel.red) ...[
                      _buildConsultationButton(),
                      const SizedBox(height: 12),
                    ],
                    // Кнопка продолжить
                    _buildContinueButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getShadowColor(),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Верхняя часть — статус светофора
            _buildStatusHeader(),

            // Контент карточки с прокруткой
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Аватар/Эмодзи
                      _buildAvatar(),
                      const SizedBox(height: 16),

                      // Имя и достижение
                      Text(
                        _card.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _card.achievement,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // История
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getLightColor(),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _card.story,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Главное сообщение
                      Text(
                        _card.message,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Для желтой зоны — рекомендация психолога
                      if (widget.riskLevel == RiskLevel.yellow) ...[
                        const SizedBox(height: 20),
                        _buildPsychologistRecommendation(),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Футер с логотипом
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getStatusGradient(),
        ),
      ),
      child: Column(
        children: [
          Text(
            _getStatusEmoji(),
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _getStatusSubtitle(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (_card.imageUrl.isEmpty) {
      // Для зеленой зоны — градиентный круг с эмодзи
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getStatusGradient(),
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _card.emoji,
            style: const TextStyle(fontSize: 40),
          ),
        ),
      );
    }

    // Для желтой/красной — фото знаменитости
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _getMainColor(),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: _getMainColor().withOpacity(0.3),
            blurRadius: 15,
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: _card.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: _getLightColor(),
            child: Center(
              child: CircularProgressIndicator(
                color: _getMainColor(),
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            print('⚠️ Ошибка загрузки изображения: $url');
            print('   Ошибка: $error');
            // Пробуем fallback на обычный Image.network
            return Image.network(
              _card.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                print('❌ Fallback тоже не сработал для: ${_card.name}');
                return Container(
                  color: _getLightColor(),
                  child: Center(
                    child: Text(_card.emoji, style: const TextStyle(fontSize: 36)),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: _getLightColor(),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _getMainColor(),
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            );
          },
          httpHeaders: const {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
          },
        ),
      ),
    );
  }

  Widget _buildPsychologistRecommendation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Рекомендуем поговорить с психологом. Это поможет быстрее перейти в зеленую зону.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3C6CF), Color(0xFFE8A5B3)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text('A', style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              )),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'anama.app',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_alt, color: Colors.white.withOpacity(0.9), size: 18),
          const SizedBox(width: 8),
          Text(
            'Сделай скриншот и сохрани',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Открыть запись к психологу
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Запись к психологу будет доступна скоро'),
              backgroundColor: Colors.red,
            ),
          );
        },
        icon: const Icon(Icons.medical_services),
        label: const Text('Анонимная консультация -10%'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          elevation: 0,
        ),
        child: Text(
          widget.riskLevel == RiskLevel.green
              ? 'Круто, продолжаем! 🔥'
              : 'Понятно, работаем дальше 💪',
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Хелперы для цветов
  // ═══════════════════════════════════════════════════════════════

  LinearGradient _getBackgroundGradient() {
    switch (widget.riskLevel) {
      case RiskLevel.green:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00C853), Color(0xFF1DE9B6)],
        );
      case RiskLevel.yellow:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
        );
      case RiskLevel.red:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE53935), Color(0xFFD81B60)],
        );
    }
  }

  List<Color> _getStatusGradient() {
    switch (widget.riskLevel) {
      case RiskLevel.green:
        return [const Color(0xFF00C853), const Color(0xFF1DE9B6)];
      case RiskLevel.yellow:
        return [const Color(0xFFFFB300), const Color(0xFFFF8F00)];
      case RiskLevel.red:
        return [const Color(0xFFE53935), const Color(0xFFD81B60)];
    }
  }

  Color _getMainColor() {
    switch (widget.riskLevel) {
      case RiskLevel.green:
        return const Color(0xFF00C853);
      case RiskLevel.yellow:
        return const Color(0xFFFFB300);
      case RiskLevel.red:
        return const Color(0xFFE53935);
    }
  }

  Color _getLightColor() {
    switch (widget.riskLevel) {
      case RiskLevel.green:
        return const Color(0xFFE8F5E9);
      case RiskLevel.yellow:
        return const Color(0xFFFFF8E1);
      case RiskLevel.red:
        return const Color(0xFFFFEBEE);
    }
  }

  Color _getShadowColor() {
    switch (widget.riskLevel) {
      case RiskLevel.green:
        return const Color(0xFF00C853).withOpacity(0.4);
      case RiskLevel.yellow:
        return const Color(0xFFFFB300).withOpacity(0.4);
      case RiskLevel.red:
        return const Color(0xFFE53935).withOpacity(0.4);
    }
  }

  String _getStatusEmoji() {
    switch (widget.riskLevel) {
      case RiskLevel.green:
        return '🟢';
      case RiskLevel.yellow:
        return '🟡';
      case RiskLevel.red:
        return '🔴';
    }
  }

  String _getStatusTitle() {
    switch (widget.riskLevel) {
      case RiskLevel.green:
        return 'ЗЕЛЕНЫЙ СВЕТ';
      case RiskLevel.yellow:
        return 'ЖЕЛТАЯ ЗОНА';
      case RiskLevel.red:
        return 'КРАСНАЯ ЗОНА';
    }
  }

  String _getStatusSubtitle() {
    switch (widget.riskLevel) {
      case RiskLevel.green:
        return 'Ты в потоке! 🔥';
      case RiskLevel.yellow:
        return 'Этап роста';
      case RiskLevel.red:
        return 'Мы рядом 💜';
    }
  }
}

