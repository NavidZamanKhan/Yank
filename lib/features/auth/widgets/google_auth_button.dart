import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:yank/core/motion/yank_motion.dart';

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => PressScale(
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF747775),
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          side: const BorderSide(color: Color(0xFF747775)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6250B5),
                ),
              )
            else
              const ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 20,
                  child: CustomPaint(painter: _GoogleMark()),
                ),
              ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                loading ? 'Continuing...' : 'Continue with Google',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A local vector rendition for the prototype, with no asset/network dependency.
/// When connecting OAuth, use Google's current approved asset or SDK button.
class _GoogleMark extends CustomPainter {
  const _GoogleMark();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final shape = Path()
      ..addArc(const Rect.fromLTWH(2, 2, 20, 20), .24 * math.pi, 1.52 * math.pi)
      ..arcTo(
        const Rect.fromLTWH(6.4, 6.4, 11.2, 11.2),
        -.24 * math.pi,
        -1.52 * math.pi,
        false,
      )
      ..close();
    final tail = Path()
      ..moveTo(12, 10)
      ..lineTo(21.8, 10)
      ..cubicTo(22.9, 16.8, 18.4, 22, 12, 22)
      ..lineTo(12, 17.6)
      ..cubicTo(15.3, 17.6, 17, 16, 17.5, 14)
      ..lineTo(12, 14)
      ..close();
    final paint = Paint()
      ..shader = const SweepGradient(
        center: Alignment.center,
        colors: [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
          Color(0xFF4285F4),
        ],
        stops: [0, .28, .48, .72, 1],
      ).createShader(const Rect.fromLTWH(2, 2, 20, 20));
    canvas.drawPath(Path.combine(PathOperation.union, shape, tail), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleMark oldDelegate) => false;
}
