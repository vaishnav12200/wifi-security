import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cybershield_wifi/theme/app_theme.dart';

class SafetyMeter extends StatefulWidget {
  final int score;
  final String status;
  final VoidCallback? onTap;

  const SafetyMeter({
    super.key,
    required this.score,
    required this.status,
    this.onTap,
  });

  @override
  State<SafetyMeter> createState() => _SafetyMeterState();
}

class _SafetyMeterState extends State<SafetyMeter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SafetyMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: oldWidget.score.toDouble(),
        end: widget.score.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor(int val) {
    if (val >= 90) return AppTheme.cyberGreen;
    if (val >= 75) return AppTheme.cyberCyan;
    if (val >= 50) return AppTheme.cyberAmber;
    return AppTheme.cyberRed;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final currentVal = _animation.value;
          final color = _getStatusColor(currentVal.round());
          
          return SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing background ring
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _MeterPainter(
                    percentage: currentVal / 100,
                    color: color,
                  ),
                ),
                // Inside content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SAFETY SCORE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentVal.round()}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                        color: color,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: color.withOpacity(0.5),
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        widget.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double percentage;
  final Color color;

  _MeterPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    
    // Background track paint
    final trackPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Foreground active paint
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Glowing border paint (adds cybersecurity aesthetics)
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Draw background track
    canvas.drawCircle(center, radius, trackPaint);

    // Draw arc (starts from top -PI/2)
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * percentage;

    if (percentage > 0) {
      // Draw glow under active arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
      // Draw active arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    }

    // Draw ticks around the track for cyber styling
    final tickPaint = Paint()
      ..color = AppTheme.textSecondary.withOpacity(0.3)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 36; i++) {
      final angle = (i * 10) * pi / 180;
      final start = Offset(
        center.dx + (radius - 16) * cos(angle),
        center.dy + (radius - 16) * sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 22) * cos(angle),
        center.dy + (radius - 22) * sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
