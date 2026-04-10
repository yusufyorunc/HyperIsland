import 'package:flutter/material.dart';

class AnimatedSettingsTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  final TabController controller;
  final List<(IconData, String)> tabs;

  const AnimatedSettingsTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: _ElasticTabBar(controller: controller, tabs: tabs),
    );
  }
}

class _ElasticTabBar extends StatefulWidget {
  final TabController controller;
  final List<(IconData, String)> tabs;

  const _ElasticTabBar({required this.controller, required this.tabs});

  @override
  State<_ElasticTabBar> createState() => _ElasticTabBarState();
}

class _ElasticTabBarState extends State<_ElasticTabBar> {
  final ScrollController _scrollController = ScrollController();

  static const double _kHorizontalPadding = 16.0;
  static const double _kIconWidth = 18.0;
  static const double _kInnerPadding = 8.0;
  static const double _kSeparatorWidth = 8.0;
  static const double _kListViewPadding = 16.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    return AnimatedBuilder(
      animation: widget.controller.animation!,
      builder: (context, child) {
        return ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: _kListViewPadding,
            vertical: 12,
          ),
          itemCount: widget.tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: _kSeparatorWidth),
          itemBuilder: (context, index) {
            final (icon, label) = widget.tabs[index];
            final double value = widget.controller.animation!.value;
            final double distance = (value - index).abs();
            final double t = (1.0 - distance).clamp(0.0, 1.0);

            final fgColor = Color.lerp(cs.onSurfaceVariant, cs.onSurface, t);

            return Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(
                  alpha: 0.5 * (1.0 - t),
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.controller.animateTo(index),
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _kHorizontalPadding,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: _kIconWidth, color: fgColor),
                          ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: t,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: _kInnerPadding,
                                ),
                                child: Opacity(
                                  opacity: t,
                                  child: Text(
                                    label,
                                    style: textStyle.copyWith(
                                      fontWeight: t > 0.5
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: fgColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
