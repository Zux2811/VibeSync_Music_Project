// lib/presentation/player/widgets/player_controls.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../data/models/player_state_model.dart';
import '../player_provider.dart';

class PlayerControls extends StatelessWidget {
  final PlayerProvider provider;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;

  const PlayerControls({
    Key? key,
    required this.provider,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onShuffle,
    required this.onRepeat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Shuffle Button
        IconButton(
          icon: FaIcon(
            FontAwesomeIcons.shuffle,
            color:
                provider.isShuffle
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).iconTheme.color,
            size: 20,
          ),
          onPressed: onShuffle,
          tooltip: 'Shuffle',
        ),

        // Previous Button
        IconButton(
          icon: FaIcon(
            FontAwesomeIcons.backwardStep,
            size: 24,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: onPrevious,
          tooltip: 'Previous',
        ),

        // Custom Play/Pause Button
        _PlayPauseButton(isPlaying: provider.isPlaying, onPressed: onPlayPause),

        // Next Button
        IconButton(
          icon: FaIcon(
            FontAwesomeIcons.forwardStep,
            size: 24,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: onNext,
          tooltip: 'Next',
        ),

        // Repeat Mode Button
        IconButton(
          icon: FaIcon(
            _getRepeatIcon(provider.repeatMode),
            color:
                provider.repeatMode != RepeatMode.noRepeat
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).iconTheme.color,
            size: 20,
          ),
          onPressed: onRepeat,
          tooltip: _getRepeatTooltip(provider.repeatMode),
        ),
      ],
    );
  }

  IconData _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.noRepeat:
        return FontAwesomeIcons.repeat;
      case RepeatMode.repeatAll:
        return FontAwesomeIcons.repeat;
      case RepeatMode.repeatOne:
        return FontAwesomeIcons.arrowRotateRight;
    }
  }

  String _getRepeatTooltip(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.noRepeat:
        return 'No Repeat';
      case RepeatMode.repeatAll:
        return 'Repeat All';
      case RepeatMode.repeatOne:
        return 'Repeat One';
    }
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayPauseButton({required this.isPlaying, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(230),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(128),
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: FaIcon(
          isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
          size: 28,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: onPressed,
        iconSize: 58, // This makes the touch target bigger
        padding: const EdgeInsets.all(15),
      ),
    );
  }
}
