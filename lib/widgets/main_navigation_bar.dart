import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

class MainNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final items = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n.navHome,
      ),
      _NavItem(
        icon: Icons.apps_outlined,
        activeIcon: Icons.apps_rounded,
        label: l10n.navApps,
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: l10n.navSettings,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 9,
        bottom: bottomPadding + 9,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = currentIndex == index;
          final item = items[index];

          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutQuint,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 18 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? cs.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant.withValues(alpha: 0.8),
                    size: 26,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutQuint,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: isSelected ? null : 0,
                      child: Padding(
                        padding: EdgeInsets.only(left: isSelected ? 8.0 : 0.0),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({required this.icon, required this.activeIcon, required this.label});
}
