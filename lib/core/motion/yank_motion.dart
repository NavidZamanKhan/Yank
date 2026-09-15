import 'package:flutter/material.dart';

abstract final class YankMotion {
  static const quick = Duration(milliseconds: 150);
  static const settle = Duration(milliseconds: 240);
  static const panel = Duration(milliseconds: 280);
  static Duration duration(BuildContext context, Duration normal) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;
}

/// Visual press feedback only. App state always travels through a feature Bloc.
/// The press compresses by 3.5%; release uses a small overshoot to make an action
/// feel physical without moving neighboring layout. The Listener observes input
/// without competing with the child's tap, swipe, or accessibility semantics.
/// Reduced motion removes both scaling and animation, including on pointer cancel.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});
  final Widget child;
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;
  void _set(bool down) {
    if (_down != down) {
      setState(() => _down = down);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !reduced ? .965 : 1,
        duration: YankMotion.duration(
          context,
          _down ? const Duration(milliseconds: 85) : YankMotion.settle,
        ),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
