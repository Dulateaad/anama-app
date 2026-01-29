import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Виджет текста с поддержкой доступности
/// Обеспечивает достаточную контрастность и семантику для экранных дикторов
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final String? semanticsLabel;
  final bool excludeSemantics;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.semanticsLabel,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    // Минимальный контраст для WCAG AA: 4.5:1 для обычного текста, 3:1 для крупного
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final accessibleStyle = defaultStyle?.copyWith(
      // Увеличиваем контрастность для лучшей читаемости
      color: _ensureContrast(defaultStyle?.color ?? Colors.black, context),
      fontWeight: defaultStyle?.fontWeight ?? FontWeight.w400,
    );

    final textWidget = Text(
      text,
      style: accessibleStyle,
      textAlign: textAlign,
      maxLines: maxLines,
    );

    if (excludeSemantics) {
      return ExcludeSemantics(child: textWidget);
    }

    return Semantics(
      label: semanticsLabel ?? text,
      child: textWidget,
    );
  }

  /// Обеспечивает достаточную контрастность цвета текста
  Color _ensureContrast(Color? color, BuildContext context) {
    if (color == null) {
      return Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black;
    }

    // Если цвет уже достаточно контрастный, возвращаем его
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    if (_hasSufficientContrast(color, backgroundColor)) {
      return color;
    }

    // Иначе возвращаем более контрастный цвет
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  /// Проверяет достаточность контраста (WCAG AA: минимум 4.5:1)
  bool _hasSufficientContrast(Color foreground, Color background) {
    final fgLuminance = _getRelativeLuminance(foreground);
    final bgLuminance = _getRelativeLuminance(background);
    
    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
    
    final contrast = (lighter + 0.05) / (darker + 0.05);
    return contrast >= 4.5;
  }

  /// Вычисляет относительную яркость цвета (для WCAG)
  double _getRelativeLuminance(Color color) {
    final r = _linearize(color.red / 255.0);
    final g = _linearize(color.green / 255.0);
    final b = _linearize(color.blue / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double _linearize(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    }
    return ((value + 0.055) / 1.055).pow(2.4);
  }
}

extension on double {
  double pow(double exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent.toInt(); i++) {
      result *= this;
    }
    return result;
  }
}

/// Кнопка с поддержкой доступности
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? child;
  final ButtonStyle? style;
  final String? hint;

  const AccessibleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.child,
    this.style,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      enabled: onPressed != null,
      child: child ?? ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      ),
    );
  }
}

/// Поле ввода с поддержкой доступности
class AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      hint: hint,
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          // Увеличиваем контрастность границ
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black38,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

