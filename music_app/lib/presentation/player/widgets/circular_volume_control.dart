// lib/presentation/player/widgets/circular_volume_control.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Circular volume control that wraps around album art
class CircularVolumeControl extends StatefulWidget {
  final double volume; // 0.0 to 1.0
  final ValueChanged<double> onVolumeChanged;
  final double size;
  final Widget child;

  const CircularVolumeControl({
    super.key,
    required this.volume,
    required this.onVolumeChanged,
    required this.size,
    required this.child,
  });

  @override
  State<CircularVolumeControl> createState() => _CircularVolumeControlState();
}

class _CircularVolumeControlState extends State<CircularVolumeControl>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
    _glowController.forward();
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    _glowController.reverse();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final position = details.localPosition;

    // Calculate angle from center
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    var angle = atan2(dy, dx);

    // Convert to 0-1 range (starting from bottom, going clockwise)
    // Start angle at bottom (-90 degrees = -pi/2)
    angle = angle + pi / 2;
    if (angle < 0) angle += 2 * pi;

    // Map to volume (0 to 240 degrees = 2/3 of circle)
    final maxAngle = 4 * pi / 3; // 240 degrees
    var volume = angle / maxAngle;
    volume = volume.clamp(0.0, 1.0);

    widget.onVolumeChanged(volume);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _VolumeArcPainter(
              volume: widget.volume,
              isDragging: _isDragging,
              glowIntensity: _glowAnimation.value,
            ),
            child: Center(child: widget.child),
          );
        },
      ),
    );
  }
}

class _VolumeArcPainter extends CustomPainter {
  final double volume;
  final bool isDragging;
  final double glowIntensity;

  _VolumeArcPainter({
    required this.volume,
    required this.isDragging,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Arc parameters - start from bottom left, go to bottom right (240 degrees)
    const startAngle = 150 * pi / 180; // Start at 150 degrees (bottom left)
    const sweepAngle = 240 * pi / 180; // Sweep 240 degrees

    // Background arc (track)
    final trackPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Volume arc (filled portion)
    final volumeSweep = sweepAngle * volume;

    // Glow effect when dragging
    if (isDragging && glowIntensity > 0) {
      final glowPaint =
          Paint()
            ..color = AppColors.skyBlue.withOpacity(0.3 * glowIntensity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        volumeSweep,
        false,
        glowPaint,
      );
    }

    // Gradient for volume arc
    final volumePaint =
        Paint()
          ..shader = SweepGradient(
            startAngle: startAngle,
            endAngle: startAngle + sweepAngle,
            colors: [
              AppColors.skyBlueDark,
              AppColors.skyBlue,
              AppColors.skyBlueLight,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round;

    if (volume > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        volumeSweep,
        false,
        volumePaint,
      );
    }

    // Draw knob at current position
    if (volume > 0) {
      final knobAngle = startAngle + volumeSweep;
      final knobX = center.dx + radius * cos(knobAngle);
      final knobY = center.dy + radius * sin(knobAngle);

      // Knob glow
      final knobGlowPaint =
          Paint()
            ..color = AppColors.skyBlue.withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(knobX, knobY), 10, knobGlowPaint);

      // Knob
      final knobPaint =
          Paint()
            ..color = AppColors.skyBlue
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(knobX, knobY), 8, knobPaint);

      // Inner dot
      final innerDotPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(knobX, knobY), 3, innerDotPaint);
    }

    // Volume icon at bottom
    _drawVolumeIcon(canvas, center, radius, volume);
  }

  void _drawVolumeIcon(
    Canvas canvas,
    Offset center,
    double radius,
    double volume,
  ) {
    final iconY = center.dy + radius + 24;
    final iconX = center.dx;

    // Volume percentage text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(volume * 100).round()}%',
        style: TextStyle(
          color: AppColors.skyBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(iconX - textPainter.width / 2, iconY - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _VolumeArcPainter oldDelegate) {
    return oldDelegate.volume != volume ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}
