import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Нижняя навигация в стиле "островок"
class AnamaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isTeen;

  const AnamaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isTeen = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF3C6CF).withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: _getHomeLabel(l10n),
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: l10n.get('chat'),
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: _getSettingsLabel(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHomeLabel(AppLocalizations l10n) {
    final locale = l10n.locale.languageCode;
    switch (locale) {
      case 'kk': return 'Басты';
      case 'en': return 'Home';
      default: return 'Главная';
    }
  }

  String _getSettingsLabel(AppLocalizations l10n) {
    final locale = l10n.locale.languageCode;
    switch (locale) {
      case 'kk': return 'Баптау';
      case 'en': return 'Settings';
      default: return 'Настройки';
    }
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? primaryColor : Colors.grey[400],
                size: isSelected ? 26 : 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
