import 'package:flutter/material.dart';

/// Custom page route transitions for smooth navigation
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final SlideDirection direction;
  final Duration duration;

  SlidePageRoute({
    required this.child,
    this.direction = SlideDirection.rightToLeft,
    this.duration = const Duration(milliseconds: 300),
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: _getSlideAnimation(animation),
      child: child,
    );
  }

  Animation<Offset> _getSlideAnimation(Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );

    switch (direction) {
      case SlideDirection.leftToRight:
        return Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero)
            .animate(curved);
      case SlideDirection.rightToLeft:
        return Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .animate(curved);
      case SlideDirection.topToBottom:
        return Tween(begin: const Offset(0.0, -1.0), end: Offset.zero)
            .animate(curved);
      case SlideDirection.bottomToTop:
        return Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
            .animate(curved);
    }
  }
}

enum SlideDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

/// Fade page transition with scale effect
class FadeScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;

  FadeScalePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    );

    final scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }
}

/// Smooth tab transition animation
class SmoothTabTransition extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;
  final Duration duration;

  const SmoothTabTransition({
    super.key,
    required this.currentIndex,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<SmoothTabTransition> createState() => _SmoothTabTransitionState();
}

class _SmoothTabTransitionState extends State<SmoothTabTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(SmoothTabTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (_animation.value == 0.0) {
          return widget.children[_previousIndex];
        } else if (_animation.value == 1.0) {
          return widget.children[widget.currentIndex];
        } else {
          return Stack(
            children: [
              // Previous tab fading out
              Opacity(
                opacity: 1.0 - _animation.value,
                child: Transform.translate(
                  offset: Offset(-50 * _animation.value, 0),
                  child: widget.children[_previousIndex],
                ),
              ),
              // Current tab fading in
              Opacity(
                opacity: _animation.value,
                child: Transform.translate(
                  offset: Offset(50 * (1.0 - _animation.value), 0),
                  child: widget.children[widget.currentIndex],
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

/// Hero animation helper for shared elements
class AnimatedHero extends StatelessWidget {
  final String tag;
  final Widget child;
  final Duration duration;

  const AnimatedHero({
    super.key,
    required this.tag,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder:
          (context, animation, direction, fromContext, toContext) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Shared element transition helper
class SharedElementTransition {
  static Route<T> createRoute<T>({
    required Widget child,
    required String heroTag,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }
}
