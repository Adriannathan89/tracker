import 'package:flutter/material.dart';

/// Stroke icons for the web shell, drawn at the same 24-unit viewBox.
class WebIcon extends StatelessWidget {
  const WebIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    if (!_WebIconPainter.supported.contains(icon)) {
      return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
    }
    final theme = IconTheme.of(context), extent = size ?? theme.size ?? 24;
    return Semantics(
      label: semanticLabel,
      child: SizedBox.square(
        dimension: extent,
        child: CustomPaint(
          painter: _WebIconPainter(
            icon,
            color ?? theme.color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _WebIconPainter extends CustomPainter {
  _WebIconPainter(this.icon, this.color);
  final IconData icon;
  final Color color;
  static const supported = [
    Icons.home_outlined,
    Icons.receipt_long_outlined,
    Icons.people_outline,
    Icons.account_balance_wallet_outlined,
    Icons.notifications_outlined,
    Icons.add,
    Icons.arrow_upward,
    Icons.arrow_downward,
    Icons.arrow_forward,
    Icons.arrow_back,
    Icons.close,
  ];
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    if (icon == Icons.home_outlined) {
      canvas.drawPath(
        Path()
          ..moveTo(3, 10)
          ..lineTo(12, 3)
          ..lineTo(21, 10)
          ..lineTo(21, 20)
          ..quadraticBezierTo(21, 21, 20, 21)
          ..lineTo(15, 21)
          ..lineTo(15, 12)
          ..lineTo(9, 12)
          ..lineTo(9, 21)
          ..lineTo(4, 21)
          ..quadraticBezierTo(3, 21, 3, 20)
          ..close(),
        paint,
      );
    } else if (icon == Icons.receipt_long_outlined) {
      canvas.drawPath(
        Path()
          ..moveTo(4, 3)
          ..lineTo(7, 5)
          ..lineTo(10, 3)
          ..lineTo(13, 5)
          ..lineTo(16, 3)
          ..lineTo(20, 5)
          ..lineTo(20, 21)
          ..lineTo(17, 19)
          ..lineTo(14, 21)
          ..lineTo(11, 19)
          ..lineTo(8, 21)
          ..lineTo(4, 19)
          ..close(),
        paint,
      );
      line(8, 9, 16, 9);
      line(8, 13, 16, 13);
    } else if (icon == Icons.people_outline) {
      canvas.drawCircle(const Offset(9, 7), 4, paint);
      canvas.drawPath(
        Path()
          ..moveTo(2, 21)
          ..lineTo(2, 19)
          ..cubicTo(2, 13.7, 16, 13.7, 16, 19)
          ..lineTo(16, 21),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(16, 3.2)
          ..cubicTo(21, 4.5, 21, 9.5, 16, 10.8),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(22, 21)
          ..lineTo(22, 19)
          ..quadraticBezierTo(22, 15.8, 19, 15.1),
        paint,
      );
    } else if (icon == Icons.account_balance_wallet_outlined) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(3, 6, 18, 15),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(3, 8)
          ..lineTo(3, 5)
          ..quadraticBezierTo(3, 3, 5, 3)
          ..lineTo(19, 3)
          ..lineTo(19, 6),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(15, 11, 7, 6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.drawCircle(const Offset(18, 14), 0.5, paint);
    } else if (icon == Icons.notifications_outlined) {
      canvas.drawPath(
        Path()
          ..moveTo(18, 8)
          ..cubicTo(18, 0, 6, 0, 6, 8)
          ..cubicTo(6, 15, 3, 17, 3, 17)
          ..lineTo(21, 17)
          ..cubicTo(21, 17, 18, 15, 18, 8),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(10, 21)
          ..quadraticBezierTo(12, 23, 14, 21),
        paint,
      );
    } else if (icon == Icons.add) {
      line(12, 5, 12, 19);
      line(5, 12, 19, 12);
    } else if (icon == Icons.close) {
      line(6, 6, 18, 18);
      line(6, 18, 18, 6);
    } else if (icon == Icons.arrow_upward || icon == Icons.arrow_downward) {
      if (icon == Icons.arrow_downward) {
        canvas.translate(24, 24);
        canvas.rotate(3.141592653589793);
      }
      line(12, 19, 12, 5);
      line(5, 12, 12, 5);
      line(12, 5, 19, 12);
    } else {
      if (icon == Icons.arrow_back) {
        canvas.translate(24, 24);
        canvas.rotate(3.141592653589793);
      }
      line(5, 12, 19, 12);
      line(12, 5, 19, 12);
      line(19, 12, 12, 19);
    }
  }

  @override
  bool shouldRepaint(covariant _WebIconPainter oldDelegate) =>
      icon != oldDelegate.icon || color != oldDelegate.color;
}
