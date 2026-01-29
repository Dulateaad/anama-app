import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'accessible_text.dart';

/// Карточка с поддержкой доступности
/// Автоматически добавляет семантику и контрастность
class AccessibleCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Color? color;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const AccessibleCard({
    super.key,
    this.title,
    this.subtitle,
    this.child,
    this.onTap,
    this.semanticLabel,
    this.color,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      margin: margin ?? const EdgeInsets.all(8),
      elevation: onTap != null ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: onTap != null
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Colors.transparent,
          width: onTap != null ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                AccessibleText(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20, // Крупный текст для читаемости
                      ),
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                AccessibleText(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                      ),
                ),
              ],
              if (child != null) ...[
                if (title != null || subtitle != null)
                  const SizedBox(height: 12),
                child!,
              ],
            ],
          ),
        ),
      ),
    );

    final label = semanticLabel ??
        (title != null
            ? '${title}${subtitle != null ? ". $subtitle" : ""}'
            : 'Карточка');

    if (onTap != null) {
      return Semantics(
        button: true,
        label: label,
        hint: 'Двойное нажатие для открытия',
        child: card,
      );
    }

    return Semantics(
      container: true,
      label: label,
      child: card,
    );
  }
}

