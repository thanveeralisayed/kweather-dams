import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A Material-based monochrome icon widget representing "K-Weather & Dams".
/// Integrates a stylized weather cloud top with a hydro dam reservoir water droplet
/// and surface wave ripples, adhering to Google Material 3 monochrome design guidelines.
class KWeatherMonochromeIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool withBackground;
  final Color? backgroundColor;

  const KWeatherMonochromeIcon({
    super.key,
    this.size = 32.0,
    this.color,
    this.withBackground = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveBg = backgroundColor ?? AppColors.surfaceContainerHigh;

    final iconWidget = CustomPaint(
      size: Size(size, size),
      painter: _KWeatherMonochromePainter(color: effectiveColor),
    );

    if (!withBackground) {
      return iconWidget;
    }

    return Container(
      width: size * 1.35,
      height: size * 1.35,
      padding: EdgeInsets.all(size * 0.175),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(size * 0.35),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(child: iconWidget),
    );
  }
}

class _KWeatherMonochromePainter extends CustomPainter {
  final Color color;

  const _KWeatherMonochromePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Weather Cloud Top Silhouette (24x24 coords)
    final cloudPath = Path();
    cloudPath.moveTo(19.35, 7.04);
    cloudPath.cubicTo(18.67, 4.59, 16.34, 3.0, 13.5, 3.0);
    cloudPath.cubicTo(11.11, 3.0, 9.0, 4.24, 7.85, 6.14);
    cloudPath.cubicTo(5.34, 6.46, 3.0, 8.71, 3.0, 11.5);
    cloudPath.cubicTo(3.0, 14.54, 5.46, 17.0, 8.5, 17.0);
    cloudPath.lineTo(19.0, 17.0);
    cloudPath.cubicTo(21.76, 17.0, 24.0, 14.76, 24.0, 12.0);
    cloudPath.cubicTo(24.0, 9.36, 21.95, 7.22, 19.35, 7.04);
    cloudPath.close();
    canvas.drawPath(cloudPath, paint);

    // 2. Hydro Dam Water Drop (Centered at x=12, y=11..24)
    final dropPath = Path();
    dropPath.moveTo(12.0, 11.0);
    dropPath.cubicTo(12.0, 11.0, 7.0, 16.2, 7.0, 19.2);
    dropPath.cubicTo(7.0, 21.96, 9.24, 24.0, 12.0, 24.0);
    dropPath.cubicTo(14.76, 24.0, 17.0, 21.96, 17.0, 19.2);
    dropPath.cubicTo(17.0, 16.2, 12.0, 11.0, 12.0, 11.0);
    dropPath.close();

    // Inner counter contour for high-contrast Material monochrome aesthetic
    final innerDrop = Path();
    innerDrop.moveTo(12.0, 22.0);
    innerDrop.cubicTo(10.5, 22.0, 9.2, 20.7, 9.2, 19.2);
    innerDrop.cubicTo(9.2, 17.6, 10.8, 15.0, 12.0, 13.5);
    innerDrop.cubicTo(13.2, 15.0, 14.8, 17.6, 14.8, 19.2);
    innerDrop.cubicTo(14.8, 20.7, 13.5, 22.0, 12.0, 22.0);
    innerDrop.close();

    dropPath.addPath(innerDrop, Offset.zero);
    dropPath.fillType = PathFillType.evenOdd;
    canvas.drawPath(dropPath, paint);

    // 3. Reservoir Water Ripple Wave Marks
    final wave1 = Path();
    wave1.moveTo(4.0, 21.0);
    wave1.quadraticBezierTo(5.5, 19.8, 7.0, 21.0);
    canvas.drawPath(wave1, strokePaint);

    final wave2 = Path();
    wave2.moveTo(17.0, 21.0);
    wave2.quadraticBezierTo(18.5, 19.8, 20.0, 21.0);
    canvas.drawPath(wave2, strokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KWeatherMonochromePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
