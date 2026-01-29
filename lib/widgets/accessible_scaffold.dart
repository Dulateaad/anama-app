import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Scaffold с полной поддержкой доступности
/// Автоматически добавляет семантику для screen readers
class AccessibleScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final String? floatingActionButtonLabel;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Drawer? drawer;
  final String? drawerLabel;
  final Widget? endDrawer;
  final String? endDrawerLabel;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const AccessibleScaffold({
    super.key,
    this.title,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLabel,
    this.floatingActionButtonLocation,
    this.drawer,
    this.drawerLabel,
    this.endDrawer,
    this.endDrawerLabel,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title ?? 'Экран приложения',
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        body: Semantics(
          container: true,
          child: body,
        ),
        floatingActionButton: floatingActionButton != null
            ? Semantics(
                button: true,
                label: floatingActionButtonLabel ?? 'Добавить',
                hint: 'Двойное нажатие для активации',
                child: floatingActionButton,
              )
            : null,
        floatingActionButtonLocation: floatingActionButtonLocation,
        drawer: drawer != null
            ? Semantics(
                button: true,
                label: drawerLabel ?? 'Меню навигации',
                hint: 'Открыть боковое меню',
                child: drawer,
              )
            : null,
        endDrawer: endDrawer,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }
}

