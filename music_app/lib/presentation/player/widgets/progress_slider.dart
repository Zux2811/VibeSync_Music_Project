// lib/presentation/player/widgets/progress_slider.dart

import 'package:flutter/material.dart';

class ProgressSlider extends StatefulWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final ValueChanged<Duration> onChanged;
  final VoidCallback? onChangeStart;
  final VoidCallback? onChangeEnd;

  const ProgressSlider({
    Key? key,
    required this.currentPosition,
    required this.totalDuration,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  }) : super(key: key);

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider> {
  late double _sliderValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _updateSliderValue();
  }

  @override
  void didUpdateWidget(ProgressSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _updateSliderValue();
    }
  }

  void _updateSliderValue() {
    if (widget.totalDuration.inSeconds > 0) {
      _sliderValue =
          widget.currentPosition.inSeconds.toDouble() /
          widget.totalDuration.inSeconds.toDouble();
      _sliderValue = _sliderValue.clamp(0.0, 1.0);
    } else {
      _sliderValue = 0.0;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4.0,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 8.0,
              elevation: 4.0,
            ),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).disabledColor,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(context).colorScheme.primary.withAlpha(77),
          ),
          child: Slider(
            value: _sliderValue,
            onChanged: (value) {
              setState(() {
                _sliderValue = value;
              });
              final newPosition = Duration(
                seconds: (value * widget.totalDuration.inSeconds).toInt(),
              );
              widget.onChanged(newPosition);
            },
            onChangeStart: (_) {
              setState(() => _isDragging = true);
              widget.onChangeStart?.call();
            },
            onChangeEnd: (_) {
              setState(() => _isDragging = false);
              widget.onChangeEnd?.call();
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(widget.currentPosition),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            Text(
              _formatDuration(widget.totalDuration),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
