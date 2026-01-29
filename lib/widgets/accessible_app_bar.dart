import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// AppBar с полной поддержкой доступности
/// Автоматически добавляет семантику для screen readers
class AccessibleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? semanticsLabel;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;

  const AccessibleAppBar({
    super.key,
    this.title,
    this.semanticsLabel,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: semanticsLabel ?? title ?? 'Заголовок экрана',
      child: AppBar(
        title: title != null
            ? Semantics(
                header: true,
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 20, // Крупный текст для читаемости
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        actions: actions,
        leading: leading,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        centerTitle: centerTitle,
        elevation: 0,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

