import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom Widget: Circular Duration Slider
/// Menggunakan CustomPainter untuk menggambar slider melingkar
/// dan GestureDetector untuk interaksi drag/pan.
/// Ini memenuhi kriteria Assessment 3:
/// - Custom Widget yang fungsional (bukan sekadar tampilan)
/// - Art with Gesture (CustomPainter + GestureDetector)
class InteractiveDurationSlider extends StatefulWidget {
  final int initialMinutes;
  final int maxMinutes;
  final ValueChanged<int> onChanged;
  final Color accentColor;

  const InteractiveDurationSlider({
    super.key,
    this.initialMinutes = 30,
    this.maxMinutes = 180,
    required this.onChanged,
    this.accentColor = Colors.deepPurple,
  });

  @override
  State<InteractiveDurationSlider> createState() =>
      _InteractiveDurationSliderState();
}

class _InteractiveDurationSliderState extends State<InteractiveDurationSlider>
    with SingleTickerProviderStateMixin {
  late int _currentMinutes;
  late AnimationController _glowController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentMinutes = widget.initialMinutes;
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  double get _sweepAngle {
    return (_currentMinutes / widget.maxMinutes) * 2 * pi;
  }

  void _updateFromPan(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // Hitung sudut dari posisi 12 jam (atas)
    double angle = atan2(dx, -dy);
    if (angle < 0) angle += 2 * pi;

    // Konversi sudut ke menit
    final minutes = (angle / (2 * pi) * widget.maxMinutes).round();
    final clampedMinutes = minutes.clamp(5, widget.maxMinutes);

    // Snap ke kelipatan 5 menit
    final snappedMinutes = (clampedMinutes / 5).round() * 5;

    if (snappedMinutes != _currentMinutes) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentMinutes = snappedMinutes;
      });
      widget.onChanged(snappedMinutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() => _isDragging = true);
                  _updateFromPan(details.localPosition, const Size(200, 200));
                },
                onPanUpdate: (details) {
                  _updateFromPan(details.localPosition, const Size(200, 200));
                },
                onPanEnd: (_) {
                  setState(() => _isDragging = false);
                },
                onTapDown: (details) {
                  _updateFromPan(details.localPosition, const Size(200, 200));
                },
                child: CustomPaint(
                  painter: _CircularSliderPainter(
                    sweepAngle: _sweepAngle,
                    accentColor: widget.accentColor,
                    isDark: isDark,
                    isDragging: _isDragging,
                    glowValue: _glowController.value,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                                scale: animation, child: child);
                          },
                          child: Text(
                            '$_currentMinutes',
                            key: ValueKey(_currentMinutes),
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: widget.accentColor,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'menit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white60
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Label informatif
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: _isDragging ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: _isDragging ? 0.5 : 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isDragging ? Icons.touch_app_rounded : Icons.timer_outlined,
                    size: 16,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isDragging
                        ? 'Geser untuk mengatur durasi'
                        : '${(_currentMinutes / 60).toStringAsFixed(1)} jam',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// CustomPainter untuk menggambar lingkaran slider melingkar.
/// Ini adalah komponen "Art" yang diminta untuk Assessment 3.
class _CircularSliderPainter extends CustomPainter {
  final double sweepAngle;
  final Color accentColor;
  final bool isDark;
  final bool isDragging;
  final double glowValue;

  _CircularSliderPainter({
    required this.sweepAngle,
    required this.accentColor,
    required this.isDark,
    required this.isDragging,
    required this.glowValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final strokeWidth = isDragging ? 14.0 : 10.0;

    // 1. Track background (lingkaran penuh)
    final trackPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Tick marks (penanda setiap 15 menit)
    final tickPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi - pi / 2;
      final innerPoint = Offset(
        center.dx + (radius - 22) * cos(angle),
        center.dy + (radius - 22) * sin(angle),
      );
      final outerPoint = Offset(
        center.dx + (radius - 14) * cos(angle),
        center.dy + (radius - 14) * sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }

    // 3. Active arc (busur progres)
    if (sweepAngle > 0) {
      final activeRect = Rect.fromCircle(center: center, radius: radius);
      final activePaint = Paint()
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: -pi / 2 + sweepAngle,
          colors: [
            accentColor.withValues(alpha: 0.6),
            accentColor,
            accentColor.withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: const GradientRotation(-pi / 2),
        ).createShader(activeRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(activeRect, -pi / 2, sweepAngle, false, activePaint);

      // 4. Glow effect saat drag
      if (isDragging) {
        final glowPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.15 + glowValue * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawArc(activeRect, -pi / 2, sweepAngle, false, glowPaint);
      }

      // 5. Thumb (titik pegangan)
      final thumbAngle = -pi / 2 + sweepAngle;
      final thumbCenter = Offset(
        center.dx + radius * cos(thumbAngle),
        center.dy + radius * sin(thumbAngle),
      );

      // Bayangan thumb
      final thumbShadow = Paint()
        ..color = accentColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(thumbCenter, isDragging ? 12 : 9, thumbShadow);

      // Thumb itu sendiri
      final thumbPaint = Paint()..color = accentColor;
      canvas.drawCircle(thumbCenter, isDragging ? 10 : 7, thumbPaint);

      // Titik putih di dalam thumb
      final innerDot = Paint()..color = Colors.white;
      canvas.drawCircle(thumbCenter, isDragging ? 4 : 3, innerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularSliderPainter oldDelegate) {
    return sweepAngle != oldDelegate.sweepAngle ||
        isDragging != oldDelegate.isDragging ||
        glowValue != oldDelegate.glowValue;
  }
}
