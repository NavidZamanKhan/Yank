import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:yank/core/utils/local_path_resolver.dart';

/// Artwork renderer supporting real image files, network URLs, and vector sample posters.
class PosterArtwork extends StatelessWidget {
  const PosterArtwork({
    super.key,
    this.variant = 'slow',
    this.fit = BoxFit.cover,
  });
  final String variant;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (variant.startsWith('http://') || variant.startsWith('https://')) {
      return Image.network(
        variant,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    }

    final clean = variant.replaceFirst(RegExp(r'^file://'), '');
    final file = LocalPathResolver.resolveFile(clean);
    if (file != null && file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    }

    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) => Semantics(
    image: true,
    label: switch (variant) {
      'scenic' => 'Take the scenic route, illustrated landscape poster',
      'form' => 'Form and feeling, typographic poster',
      _ => 'Slow down, olive typographic poster',
    },
    child: CustomPaint(painter: _PosterPainter(variant), size: Size.infinite),
  );
}

class _PosterPainter extends CustomPainter {
  const _PosterPainter(this.variant);
  final String variant;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final scale = size.width / 360;
    final height = size.height / scale;
    canvas.save();
    canvas.scale(scale);
    if (variant == 'scenic') {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 360, height),
        Paint()..color = const Color(0xFFE8E0F0),
      );
      canvas.drawCircle(
        Offset(290, height * .3),
        math.min(29, height * .18),
        Paint()..color = const Color(0xFFB8A6CD),
      );
      final hills = Path()
        ..moveTo(140, height)
        ..cubicTo(210, height * .18, 250, height * .9, 360, height * .48)
        ..lineTo(360, height)
        ..close();
      canvas.drawPath(hills, Paint()..color = const Color(0xFF78816C));
      final lower = Path()
        ..moveTo(70, height)
        ..quadraticBezierTo(230, height * .42, 360, height * .8)
        ..lineTo(360, height)
        ..close();
      canvas.drawPath(lower, Paint()..color = const Color(0xFF495946));
      _text(
        canvas,
        'take the\nscenic route.',
        Offset(20, math.min(25, height * .15)),
        math.min(48, height * .29),
        const Color(0xFF34352F),
      );
    } else if (variant == 'form') {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 360, height),
        Paint()..color = const Color(0xFFE9E5DE),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(258, -15, 68, height + 30),
          const Radius.circular(36),
        ),
        Paint()..color = const Color(0xFF766692),
      );
      _text(
        canvas,
        'form &\nfeeling.',
        Offset(20, math.min(24, height * .15)),
        math.min(67, height * .35),
        const Color(0xFF2D2933),
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 360, height),
        Paint()..color = const Color(0xFFD8DFB8),
      );
      canvas.save();
      canvas.translate(278, height / 2);
      canvas.rotate(.47);
      final paint = Paint()
        ..color = const Color(0xFF526145)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 106, height: height + 35),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 75, height: height + 3),
        paint,
      );
      canvas.restore();
      _text(
        canvas,
        'slow\ndown.',
        Offset(21, math.min(28, height * .14)),
        math.min(80, height * .36),
        const Color(0xFF303827),
      );
    }
    canvas.restore();
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset,
    double size,
    Color color,
  ) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: size,
          height: .97,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 270);
    text.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _PosterPainter oldDelegate) =>
      variant != oldDelegate.variant;
}
