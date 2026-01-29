import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Зоны мозга, которые развиваются при выполнении заданий
enum BrainZone {
  prefrontalCortex,   // Префронтальная кора — планирование, самоконтроль
  limbicSystem,       // Лимбическая система — эмоции, привязанность
  motorCortex,        // Моторная кора — движения
  temporalLobe,       // Височная доля — речь, слух
  parietalLobe,       // Теменная доля — пространство, тактильность
  visualCortex,       // Зрительная кора — зрение
  cerebellum,         // Мозжечок — координация
  hippocampus,        // Гиппокамп — память
}

extension BrainZoneExtension on BrainZone {
  String get nameRu {
    switch (this) {
      case BrainZone.prefrontalCortex: return 'Префронтальная кора';
      case BrainZone.limbicSystem: return 'Лимбическая система';
      case BrainZone.motorCortex: return 'Моторная кора';
      case BrainZone.temporalLobe: return 'Височная доля';
      case BrainZone.parietalLobe: return 'Теменная доля';
      case BrainZone.visualCortex: return 'Зрительная кора';
      case BrainZone.cerebellum: return 'Мозжечок';
      case BrainZone.hippocampus: return 'Гиппокамп';
    }
  }

  String get nameKk {
    switch (this) {
      case BrainZone.prefrontalCortex: return 'Префронталды қыртыс';
      case BrainZone.limbicSystem: return 'Лимбиялық жүйе';
      case BrainZone.motorCortex: return 'Моторлық қыртыс';
      case BrainZone.temporalLobe: return 'Самай бөлігі';
      case BrainZone.parietalLobe: return 'Төбе бөлігі';
      case BrainZone.visualCortex: return 'Көру қыртысы';
      case BrainZone.cerebellum: return 'Мишық';
      case BrainZone.hippocampus: return 'Гиппокамп';
    }
  }

  String get skill {
    switch (this) {
      case BrainZone.prefrontalCortex: return '🎯 Планирование и самоконтроль';
      case BrainZone.limbicSystem: return '💗 Эмоции и привязанность';
      case BrainZone.motorCortex: return '🏃 Движения и моторика';
      case BrainZone.temporalLobe: return '🗣️ Речь и слух';
      case BrainZone.parietalLobe: return '🧩 Пространство и осязание';
      case BrainZone.visualCortex: return '👁️ Зрение и узнавание';
      case BrainZone.cerebellum: return '⚖️ Баланс и координация';
      case BrainZone.hippocampus: return '🧠 Память и обучение';
    }
  }

  Color get color {
    switch (this) {
      case BrainZone.prefrontalCortex: return const Color(0xFF00FFFF); // Cyan
      case BrainZone.limbicSystem: return const Color(0xFFFF69B4);     // Pink
      case BrainZone.motorCortex: return const Color(0xFF00FF00);      // Green
      case BrainZone.temporalLobe: return const Color(0xFFFFD700);     // Gold
      case BrainZone.parietalLobe: return const Color(0xFFFF6B35);     // Orange
      case BrainZone.visualCortex: return const Color(0xFF9B59B6);     // Purple
      case BrainZone.cerebellum: return const Color(0xFF3498DB);       // Blue
      case BrainZone.hippocampus: return const Color(0xFFE74C3C);      // Red
    }
  }
}

/// Виджет визуализации мозга с неоновым свечением
class BrainVisualization extends StatefulWidget {
  final Set<BrainZone> activatedZones;
  final BrainZone? highlightZone;
  final VoidCallback? onZoneTap;
  final double size;

  const BrainVisualization({
    super.key,
    required this.activatedZones,
    this.highlightZone,
    this.onZoneTap,
    this.size = 250,
  });

  @override
  State<BrainVisualization> createState() => _BrainVisualizationState();
}

class _BrainVisualizationState extends State<BrainVisualization>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: BrainPainter(
              activatedZones: widget.activatedZones,
              highlightZone: widget.highlightZone,
              pulseValue: _pulseAnimation.value,
              glowValue: _glowAnimation.value,
            ),
          ),
        );
      },
    );
  }
}

/// Painter для рисования мозга с неоновым эффектом
class BrainPainter extends CustomPainter {
  final Set<BrainZone> activatedZones;
  final BrainZone? highlightZone;
  final double pulseValue;
  final double glowValue;

  BrainPainter({
    required this.activatedZones,
    this.highlightZone,
    required this.pulseValue,
    required this.glowValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.4;

    // Рисуем фон мозга
    _drawBrainOutline(canvas, center, baseRadius, size);

    // Рисуем нейронные связи (базовые линии)
    _drawNeuralNetwork(canvas, center, baseRadius);

    // Рисуем зоны мозга
    for (final zone in BrainZone.values) {
      final isActivated = activatedZones.contains(zone);
      final isHighlighted = highlightZone == zone;
      _drawBrainZone(canvas, center, baseRadius, zone, isActivated, isHighlighted);
    }

    // Рисуем пульсирующие точки на активированных зонах
    for (final zone in activatedZones) {
      _drawPulsingNode(canvas, center, baseRadius, zone);
    }
  }

  void _drawBrainOutline(Canvas canvas, Offset center, double radius, Size size) {
    // Основной контур мозга (стилизованный)
    final outlinePaint = Paint()
      ..color = Colors.grey[800]!.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    
    // Форма мозга (вид сбоку)
    path.moveTo(center.dx - radius * 0.9, center.dy);
    
    // Верхняя часть (извилины)
    path.cubicTo(
      center.dx - radius * 0.9, center.dy - radius * 0.6,
      center.dx - radius * 0.5, center.dy - radius * 0.9,
      center.dx, center.dy - radius * 0.8,
    );
    path.cubicTo(
      center.dx + radius * 0.5, center.dy - radius * 0.9,
      center.dx + radius * 0.9, center.dy - radius * 0.5,
      center.dx + radius * 0.7, center.dy,
    );
    
    // Нижняя часть
    path.cubicTo(
      center.dx + radius * 0.8, center.dy + radius * 0.4,
      center.dx + radius * 0.3, center.dy + radius * 0.6,
      center.dx - radius * 0.2, center.dy + radius * 0.5,
    );
    
    // Мозжечок
    path.cubicTo(
      center.dx - radius * 0.5, center.dy + radius * 0.7,
      center.dx - radius * 0.8, center.dy + radius * 0.4,
      center.dx - radius * 0.9, center.dy,
    );

    canvas.drawPath(path, outlinePaint);
  }

  void _drawNeuralNetwork(Canvas canvas, Offset center, double radius) {
    final networkPaint = Paint()
      ..color = Colors.purple[900]!.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final random = math.Random(42); // Фиксированный seed для консистентности
    
    // Рисуем случайные нейронные связи
    for (int i = 0; i < 30; i++) {
      final startAngle = random.nextDouble() * math.pi * 2;
      final endAngle = random.nextDouble() * math.pi * 2;
      final startRadius = radius * (0.3 + random.nextDouble() * 0.5);
      final endRadius = radius * (0.3 + random.nextDouble() * 0.5);

      final start = Offset(
        center.dx + math.cos(startAngle) * startRadius,
        center.dy + math.sin(startAngle) * startRadius,
      );
      final end = Offset(
        center.dx + math.cos(endAngle) * endRadius,
        center.dy + math.sin(endAngle) * endRadius,
      );

      canvas.drawLine(start, end, networkPaint);
    }
  }

  void _drawBrainZone(
    Canvas canvas,
    Offset center,
    double radius,
    BrainZone zone,
    bool isActivated,
    bool isHighlighted,
  ) {
    final zoneCenter = _getZonePosition(center, radius, zone);
    final zoneRadius = radius * 0.15;

    if (!isActivated) {
      // Неактивированная зона — тусклая
      final inactivePaint = Paint()
        ..color = Colors.grey[700]!.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(zoneCenter, zoneRadius, inactivePaint);
      return;
    }

    // Активированная зона с неоновым свечением
    final zoneColor = zone.color;
    
    // Внешнее свечение (glow)
    for (int i = 3; i > 0; i--) {
      final glowPaint = Paint()
        ..color = zoneColor.withOpacity(glowValue * 0.15 * i)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, zoneRadius * 0.5 * i);
      canvas.drawCircle(zoneCenter, zoneRadius * (1 + i * 0.3), glowPaint);
    }

    // Основной круг зоны
    final zonePaint = Paint()
      ..color = zoneColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(zoneCenter, zoneRadius * pulseValue, zonePaint);

    // Яркий контур
    final borderPaint = Paint()
      ..color = zoneColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(zoneCenter, zoneRadius * pulseValue, borderPaint);

    // Связи от этой зоны к другим активированным зонам
    for (final otherZone in activatedZones) {
      if (otherZone != zone) {
        final otherCenter = _getZonePosition(center, radius, otherZone);
        _drawNeonConnection(canvas, zoneCenter, otherCenter, zoneColor);
      }
    }
  }

  void _drawNeonConnection(Canvas canvas, Offset start, Offset end, Color color) {
    // Свечение линии
    final glowPaint = Paint()
      ..color = color.withOpacity(glowValue * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(start, end, glowPaint);

    // Основная линия
    final linePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(start, end, linePaint);
  }

  void _drawPulsingNode(Canvas canvas, Offset center, double radius, BrainZone zone) {
    final zoneCenter = _getZonePosition(center, radius, zone);
    final zoneColor = zone.color;

    // Пульсирующий эффект
    final pulseRadius = radius * 0.05 * pulseValue;
    final pulsePaint = Paint()
      ..color = zoneColor.withOpacity(glowValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(zoneCenter, pulseRadius, pulsePaint);
  }

  Offset _getZonePosition(Offset center, double radius, BrainZone zone) {
    // Позиции зон на схематичном изображении мозга
    switch (zone) {
      case BrainZone.prefrontalCortex:
        return Offset(center.dx - radius * 0.6, center.dy - radius * 0.3);
      case BrainZone.motorCortex:
        return Offset(center.dx - radius * 0.1, center.dy - radius * 0.7);
      case BrainZone.parietalLobe:
        return Offset(center.dx + radius * 0.3, center.dy - radius * 0.5);
      case BrainZone.temporalLobe:
        return Offset(center.dx - radius * 0.4, center.dy + radius * 0.2);
      case BrainZone.visualCortex:
        return Offset(center.dx + radius * 0.6, center.dy - radius * 0.1);
      case BrainZone.limbicSystem:
        return Offset(center.dx, center.dy);
      case BrainZone.hippocampus:
        return Offset(center.dx + radius * 0.2, center.dy + radius * 0.2);
      case BrainZone.cerebellum:
        return Offset(center.dx - radius * 0.3, center.dy + radius * 0.5);
    }
  }

  @override
  bool shouldRepaint(covariant BrainPainter oldDelegate) {
    return oldDelegate.activatedZones != activatedZones ||
        oldDelegate.highlightZone != highlightZone ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.glowValue != glowValue;
  }
}

/// Карточка прогресса развития мозга
class BrainProgressCard extends StatefulWidget {
  final String parentId;
  final BrainZone? newlyActivatedZone;

  const BrainProgressCard({
    super.key,
    required this.parentId,
    this.newlyActivatedZone,
  });

  @override
  State<BrainProgressCard> createState() => _BrainProgressCardState();
}

class _BrainProgressCardState extends State<BrainProgressCard>
    with SingleTickerProviderStateMixin {
  Set<BrainZone> _activatedZones = {};
  late AnimationController _newZoneController;
  late Animation<double> _newZoneAnimation;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    
    _newZoneController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _newZoneAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _newZoneController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _newZoneController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BrainProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.newlyActivatedZone != null &&
        widget.newlyActivatedZone != oldWidget.newlyActivatedZone) {
      _activateNewZone(widget.newlyActivatedZone!);
    }
  }

  Future<void> _loadProgress() async {
    final doc = await FirebaseFirestore.instance
        .collection('brain_progress')
        .doc(widget.parentId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final zones = (data['activatedZones'] as List<dynamic>?)
          ?.map((e) => BrainZone.values.firstWhere(
                (z) => z.name == e,
                orElse: () => BrainZone.limbicSystem,
              ))
          .toSet() ?? {};
      
      if (mounted) {
        setState(() => _activatedZones = zones);
      }
    }
  }

  Future<void> _activateNewZone(BrainZone zone) async {
    // Анимация появления новой зоны
    _newZoneController.forward(from: 0);

    // Добавляем зону
    setState(() {
      _activatedZones = {..._activatedZones, zone};
    });

    // Сохраняем в Firestore
    await FirebaseFirestore.instance
        .collection('brain_progress')
        .doc(widget.parentId)
        .set({
      'activatedZones': _activatedZones.map((z) => z.name).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'totalZones': _activatedZones.length,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final progress = _activatedZones.length / BrainZone.values.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo[900]!,
              Colors.purple[900]!,
              Colors.black,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Заголовок
              Row(
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Развитие мозга малыша',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(_activatedZones.length)} / ${BrainZone.values.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Визуализация мозга
              Center(
                child: BrainVisualization(
                  activatedZones: _activatedZones,
                  highlightZone: widget.newlyActivatedZone,
                  size: 220,
                ),
              ),

              const SizedBox(height: 20),

              // Прогресс бар
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Прогресс развития',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Активированные зоны
              if (_activatedZones.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _activatedZones.map((zone) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: zone.color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: zone.color.withOpacity(0.5)),
                      ),
                      child: Text(
                        zone.skill.split(' ').first, // Только emoji
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                ),

              // Новая активированная зона
              if (widget.newlyActivatedZone != null)
                AnimatedBuilder(
                  animation: _newZoneAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _newZoneAnimation.value,
                      child: Opacity(
                        opacity: _newZoneAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.newlyActivatedZone!.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.newlyActivatedZone!.color,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text('✨', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Новая зона активирована!',
                                      style: TextStyle(
                                        color: widget.newlyActivatedZone!.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      widget.newlyActivatedZone!.skill,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
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
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Хелпер для определения зоны мозга по типу задания
class BrainZoneMapper {
  static BrainZone? getZoneForTask(Map<String, dynamic> task) {
    final brainZone = task['brainZone'] as String?;
    final taskTitle = (task['taskTitle'] as String?)?.toLowerCase() ?? '';
    final steps = (task['steps'] as List<dynamic>?)?.join(' ').toLowerCase() ?? '';
    final fullText = '$taskTitle $steps $brainZone'.toLowerCase();

    // Определяем зону по ключевым словам
    if (fullText.contains('глаза') || fullText.contains('взгляд') || 
        fullText.contains('смотр') || fullText.contains('көз')) {
      return BrainZone.visualCortex;
    }
    if (fullText.contains('эмоци') || fullText.contains('чувств') || 
        fullText.contains('любов') || fullText.contains('сезім')) {
      return BrainZone.limbicSystem;
    }
    if (fullText.contains('движ') || fullText.contains('ходи') || 
        fullText.contains('бега') || fullText.contains('қозғал')) {
      return BrainZone.motorCortex;
    }
    if (fullText.contains('говор') || fullText.contains('слов') || 
        fullText.contains('речь') || fullText.contains('сөйле')) {
      return BrainZone.temporalLobe;
    }
    if (fullText.contains('памят') || fullText.contains('запомн') || 
        fullText.contains('есте')) {
      return BrainZone.hippocampus;
    }
    if (fullText.contains('баланс') || fullText.contains('равновес') || 
        fullText.contains('координ')) {
      return BrainZone.cerebellum;
    }
    if (fullText.contains('план') || fullText.contains('контрол') || 
        fullText.contains('внима') || fullText.contains('назар')) {
      return BrainZone.prefrontalCortex;
    }
    if (fullText.contains('простран') || fullText.contains('форм') || 
        fullText.contains('трога') || fullText.contains('кеңістік')) {
      return BrainZone.parietalLobe;
    }

    // По умолчанию — лимбическая система (все Serve & Return развивают привязанность)
    return BrainZone.limbicSystem;
  }
}

