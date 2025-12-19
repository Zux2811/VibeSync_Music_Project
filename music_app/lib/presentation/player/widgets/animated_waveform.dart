// lib/presentation/player/widgets/animated_waveform.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Smooth animated waveform visualization for music player
class AnimatedWaveform extends StatefulWidget {
  final double progress;
  final bool isPlaying;
  final Color activeColor;
  final Color inactiveColor;
  final double height;

  const AnimatedWaveform({
    super.key,
    required this.progress,
    required this.isPlaying,
    this.activeColor = AppColors.skyBlue,
    this.inactiveColor = const Color(0xFF3A3A5A),
    this.height = 60,
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Pre-generated bar heights for consistent pattern
  late List<double> _barHeights;
  final Random _random = Random(42);

  @override
  void initState() {
    super.initState();

    // Wave animation for flowing effect
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Pulse animation for active bar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Generate bar heights
    _generateBarHeights();

    if (widget.isPlaying) {
      _waveController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  void _generateBarHeights() {
    _barHeights = List.generate(60, (index) {
      final pos = index / 60;
      // Create a more musical wave pattern
      final baseHeight =
          0.3 +
          0.4 * sin(pos * pi * 3) * sin(pos * pi * 3) +
          0.3 * _random.nextDouble();
      return baseHeight.clamp(0.15, 1.0);
    });
  }

  @override
  void didUpdateWidget(AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _waveController.repeat();
        _pulseController.repeat(reverse: true);
      } else {
        _waveController.stop();
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _WaveformPainter(
            progress: widget.progress,
            isPlaying: widget.isPlaying,
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
            barHeights: _barHeights,
            wavePhase: _waveController.value,
            pulseScale: _pulseAnimation.value,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color activeColor;
  final Color inactiveColor;
  final List<double> barHeights;
  final double wavePhase;
  final double pulseScale;

  _WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.activeColor,
    required this.inactiveColor,
    required this.barHeights,
    required this.wavePhase,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 3.0;
    final gap = 4.0;
    final totalBars = (size.width / (barWidth + gap)).floor().clamp(
      1,
      barHeights.length,
    );
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.8;

    final activePaint =
        Paint()
          ..color = activeColor
          ..strokeCap = StrokeCap.round
          ..strokeWidth = barWidth;

    final inactivePaint =
        Paint()
          ..color = inactiveColor
          ..strokeCap = StrokeCap.round
          ..strokeWidth = barWidth;

    // Glow paint for active area
    final glowPaint =
        Paint()
          ..color = activeColor.withOpacity(0.3)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = barWidth + 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final progressBarIndex = (progress * totalBars).floor();

    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + gap) + barWidth / 2 + gap / 2;
      final normalizedPos = i / totalBars;

      // Get base height from pre-generated pattern
      final heightIndex = (normalizedPos * barHeights.length).floor().clamp(
        0,
        barHeights.length - 1,
      );
      double height = barHeights[heightIndex] * maxBarHeight;

      // Add wave animation when playing
      if (isPlaying) {
        final waveOffset = sin((normalizedPos * 4 + wavePhase * 2) * pi) * 0.15;
        height *= (1.0 + waveOffset);
      }

      // Pulse effect near current position
      if (isPlaying && (i - progressBarIndex).abs() <= 2) {
        final distanceFromCurrent = (i - progressBarIndex).abs();
        final pulseEffect = pulseScale - (distanceFromCurrent * 0.1);
        height *= pulseEffect.clamp(1.0, 1.4);
      }

      height = height.clamp(4.0, maxBarHeight);

      final isActive = normalizedPos <= progress;

      // Draw glow for active bars near progress
      if (isActive && isPlaying && (progressBarIndex - i).abs() <= 3) {
        canvas.drawLine(
          Offset(x, centerY - height / 2),
          Offset(x, centerY + height / 2),
          glowPaint,
        );
      }

      // Draw bar
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        isActive ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.pulseScale != pulseScale;
  }
}
