import 'package:flutter/material.dart';

class BackToTopButton extends StatefulWidget {
  final ScrollController scrollController;
  final double threshold;
  final double bottomPadding;

  const BackToTopButton({
    super.key,
    required this.scrollController,
    this.threshold = 420.0,
    this.bottomPadding = 16.0,
  });

  @override
  State<BackToTopButton> createState() => _BackToTopButtonState();
}

class _BackToTopButtonState extends State<BackToTopButton> {
  bool _show = false;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (!widget.scrollController.hasClients) return;
    final offset = widget.scrollController.offset;
    final isScrollingUp = offset < _lastOffset;
    final shouldShow = offset > widget.threshold && isScrollingUp;

    if (shouldShow != _show) {
      if (mounted) {
        setState(() => _show = shouldShow);
      }
    }
    _lastOffset = offset;
  }

  Future<void> _scrollToTop() async {
    if (!widget.scrollController.hasClients) return;
    final position = widget.scrollController.position;

    if (position.pixels > 3000) {
      position.jumpTo(1000);
      await Future.delayed(const Duration(milliseconds: 5));
    }

    if (!widget.scrollController.hasClients) return;
    await widget.scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomPadding, right: 8),
      child: AnimatedScale(
        scale: _show ? 1 : 0,
        curve: Curves.elasticOut,
        duration: const Duration(milliseconds: 600),
        child: AnimatedOpacity(
          opacity: _show ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: FloatingActionButton(
            heroTag: null,
            elevation: 3,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: _scrollToTop,
            child: const Icon(Icons.arrow_upward_rounded),
          ),
        ),
      ),
    );
  }
}
