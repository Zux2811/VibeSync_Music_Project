// lib/presentation/player/widgets/mini_player.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../player_provider.dart';

/// Mini player widget that shows at the bottom of screens - Spotify style
class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const MiniPlayer({super.key, this.onTap, this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;
        if (song == null) return const SizedBox.shrink();

        final position = provider.state.currentPosition;
        final duration = provider.state.totalDuration;
        final progress =
            duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;

        return GestureDetector(
          onTap: onTap ?? () => Navigator.pushNamed(context, '/player'),
          child: Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgLighter : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Album art
                        Hero(
                          tag: 'album_art_${song.id}',
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child:
                                  song.imageUrl != null
                                      ? Image.network(
                                        song.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => _defaultArt(isDark),
                                      )
                                      : _defaultArt(isDark),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Song info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors.white
                                          : AppColors.textDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppColors.textSecondary
                                          : AppColors.textDarkSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Device icon (like Spotify)
                            IconButton(
                              icon: Icon(
                                Icons.devices_rounded,
                                color:
                                    isDark
                                        ? AppColors.textSecondary
                                        : AppColors.textDarkSecondary,
                                size: 20,
                              ),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),

                            // Play/Pause button
                            IconButton(
                              icon: Icon(
                                provider.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color:
                                    isDark ? Colors.white : AppColors.textDark,
                                size: 32,
                              ),
                              onPressed: () => provider.togglePlayPause(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Progress bar at bottom
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor:
                          isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _defaultArt(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCard : AppColors.lightElevated,
      child: Icon(
        Icons.music_note,
        color: isDark ? Colors.white24 : Colors.black26,
        size: 24,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Wrapper widget that includes mini player at bottom
class MiniPlayerScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const MiniPlayerScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          Expanded(child: body),
          Consumer<PlayerProvider>(
            builder: (context, provider, _) {
              if (provider.currentSong == null) {
                return const SizedBox.shrink();
              }
              return const MiniPlayer();
            },
          ),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
