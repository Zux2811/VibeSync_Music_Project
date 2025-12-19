import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../player/player_provider.dart';

class WebPlayerBar extends StatelessWidget {
  const WebPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    final song = provider.currentSong;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (song == null) return const SizedBox.shrink();

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgLight : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Song Info
            Row(
              children: [
                // Album Art
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      song.imageUrl != null
                          ? Image.network(
                            song.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _defaultArtwork(),
                          )
                          : _defaultArtwork(),
                ),
                const SizedBox(width: 16),
                // Song Details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Player Controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous Button
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 28,
                  onPressed: () {
                    // Assume user has Pro for web version
                    provider.tryPreviousTrack(isPro: true);
                  },
                  color: isDark ? Colors.white : Colors.black87,
                ),
                const SizedBox(width: 8),
                // Play/Pause Button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      provider.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    iconSize: 26,
                    color: Colors.white,
                    onPressed: provider.togglePlayPause,
                  ),
                ),
                const SizedBox(width: 8),
                // Next Button
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 28,
                  onPressed: () {
                    // Assume user has Pro for web version
                    provider.tryNextTrack(isPro: true);
                  },
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ],
            ),

            const Spacer(),

            // Progress and Volume
            SizedBox(
              width: 280,
              child: Row(
                children: [
                  // Current Time
                  Text(
                    _formatDuration(provider.state.currentPosition),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  // Progress Bar
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value:
                            provider.state.currentPosition.inSeconds.toDouble(),
                        max: provider.state.totalDuration.inSeconds.toDouble(),
                        onChanged: (value) {
                          provider.updatePosition(
                            Duration(seconds: value.toInt()),
                          );
                        },
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.grey[300],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Total Duration
                  Text(
                    _formatDuration(provider.state.totalDuration),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // Volume Control
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: provider.volume,
                      onChanged: provider.setVolume,
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultArtwork() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Colors.grey, size: 30),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
