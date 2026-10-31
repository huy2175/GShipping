import 'package:flutter/material.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AnimatedCard({super.key, required this.child, this.onTap});

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Kích hoạt hiệu ứng xuất hiện khi load
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.reverse(); // Co lại khi nhấn xuống
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.forward(); // Trở lại kích thước cũ khi thả ra
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: GestureDetector(
          onTapDown: (details) => _handleTapDown(details),
          onTapUp: (details) => _handleTapUp(details),
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}
