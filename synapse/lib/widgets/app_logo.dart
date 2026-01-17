import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom app logo widget - Red glowing starburst/asterisk design
class AppLogo extends StatelessWidget {
  final double size;
  
  const AppLogo({
    super.key,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AppLogoPainter(),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.7;
    
    // Create paint for glow effect
    final glowPaint = Paint()
      ..color = AppTheme.netflixRed.withOpacity(0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
    // Create paint for main elements
    final mainPaint = Paint()
      ..color = AppTheme.netflixRed
      ..style = PaintingStyle.fill;
    
    final linePaint = Paint()
      ..color = AppTheme.netflixRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12
      ..strokeCap = StrokeCap.round;
    
    // Draw central circle with glow
    final centerRadius = radius * 0.2;
    canvas.drawCircle(center, centerRadius * 1.8, glowPaint);
    canvas.drawCircle(center, centerRadius, mainPaint);
    
    // Draw 8 radiating lines with endpoint circles
    final endpointRadius = radius * 0.12;
    final lineLength = radius * 0.8;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45 - 90) * (math.pi / 180); // Start from top
      final endX = center.dx + lineLength * math.cos(angle);
      final endY = center.dy + lineLength * math.sin(angle);
      final endpoint = Offset(endX, endY);
      
      // Draw line
      canvas.drawLine(center, endpoint, linePaint);
      
      // Draw glow for endpoint
      canvas.drawCircle(endpoint, endpointRadius * 1.5, glowPaint);
      
      // Draw endpoint circle
      canvas.drawCircle(endpoint, endpointRadius, mainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
