// lib/presentation/player/player_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/player_state_model.dart';
import 'player_provider.dart';
import 'widgets/player_menu.dart';
import 'widgets/playlist_selector.dart';
import 'widgets/artist_info_sheet.dart';
import 'widgets/animated_waveform.dart';
import 'widgets/circular_volume_control.dart';
import '../home/tabs/library/library_provider.dart';
import '../subscription/subscription_provider.dart';
import '../subscription/upgrade_pro_page.dart';

// Comments feature modules
import 'comments/comment_provider.dart';
import 'comments/widgets/comment_list.dart';

// Color aliases using AppColors
const Color kSkyBlue = AppColors.primary;
const Color kSkyBlueLight = AppColors.primaryLight;
const Color kSkyBlueDark = AppColors.primaryDark;
const Color kDarkBg = AppColors.darkBg;
const Color kDarkBgLight = AppColors.darkBgLight;

class PlayerPage extends StatefulWidget {
  final Song? initialSong;
  final List<Song>? initialPlaylist;

  const PlayerPage({super.key, this.initialSong, this.initialPlaylist});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with TickerProviderStateMixin {
  late final PlayerProvider _playerProvider;
  late final VoidCallback _playerErrorListener;
  late AnimationController _rotationController;
  double _volume = 1.0;
  bool _showVolumeControl = false;

  @override
  void initState() {
    super.initState();
    _playerProvider = context.read<PlayerProvider>();

    // Rotation animation for vinyl
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPlaylist != null) {
        _playerProvider.setPlaylistAndPlay(
          widget.initialPlaylist!,
          currentSong: widget.initialSong,
        );
      } else if (widget.initialSong != null) {
        _playerProvider.playSong(widget.initialSong!);
      } else {
        if (_playerProvider.state.playlist.isEmpty) {
          _playerProvider.initializePlaylist();
        }
      }
    });

    _monitorPlayerErrors();
  }

  void _monitorPlayerErrors() {
    _playerErrorListener = () {
      if (_playerProvider.state.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_playerProvider.state.errorMessage!),
            backgroundColor: Colors.red[400],
          ),
        );
        _playerProvider.clearError();
      }

      // Control rotation based on playing state
      if (_playerProvider.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    };
    _playerProvider.addListener(_playerErrorListener);
  }

  @override
  void dispose() {
    _playerProvider.removeListener(_playerErrorListener);
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        // Update rotation based on playing state
        if (provider.isPlaying && !_rotationController.isAnimating) {
          _rotationController.repeat();
        } else if (!provider.isPlaying && _rotationController.isAnimating) {
          _rotationController.stop();
        }

        final song = provider.currentSong;

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          body: Stack(
            children: [
              // Background with album art blur effect
              if (song?.imageUrl != null)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(song!.imageUrl!),
                          fit: BoxFit.cover,
                          opacity: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              // Dark overlay gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.darkBg.withOpacity(0.3),
                        AppColors.darkBg.withOpacity(0.8),
                        AppColors.darkBg,
                      ],
                      stops: const [0.0, 0.5, 0.8],
                    ),
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // App Bar
                    _buildAppBar(context, provider),

                    // Main Content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Album Art (clean, no vinyl)
                            _buildAlbumArt(provider),

                            const SizedBox(height: 32),

                            // Song Info
                            _buildSongInfo(provider),

                            const SizedBox(height: 24),

                            // Progress Slider
                            _buildWaveformProgress(provider),

                            const SizedBox(height: 20),

                            // Control Buttons
                            _buildControls(context, provider),

                            const SizedBox(height: 24),

                            // Bottom Actions
                            _buildBottomActions(context, provider),

                            const SizedBox(height: 16),

                            // Comments Section
                            if (provider.currentSong != null)
                              _buildCommentsSection(provider),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, PlayerProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Minimize Button (arrow down)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Minimize player',
            ),
          ),

          // Title
          const Text(
            'Now Playing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Menu
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white70),
                onPressed: _handleShare,
              ),
              Consumer2<SubscriptionProvider, PlayerProvider>(
                builder:
                    (context, sub, player, _) => PlayerMenu(
                      onAddToPlaylist: _showPlaylistSelector,
                      onViewArtist: _showArtistInfo,
                      onDownload: _handleDownload,
                      onShare: _handleShare,
                      onToggleAutoMix: () => player.toggleAutoMix(),
                      canDownload: sub.isPro,
                      isAutoMixEnabled: player.isAutoMixEnabled,
                      crossfadeDuration: player.crossfadeDuration,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Modern album art display - Spotify style
  Widget _buildAlbumArt(PlayerProvider provider) {
    final song = provider.currentSong;
    final size = MediaQuery.of(context).size.width * 0.8;

    return GestureDetector(
      onDoubleTap:
          () => setState(() => _showVolumeControl = !_showVolumeControl),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  song?.imageUrl != null
                      ? Image.network(
                        song!.imageUrl!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultAlbumArt(),
                      )
                      : _defaultAlbumArt(),
            ),

            // Volume control overlay
            if (_showVolumeControl)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CircularVolumeControl(
                    volume: _volume,
                    size: size * 0.8,
                    onVolumeChanged: (vol) {
                      setState(() => _volume = vol);
                      _playerProvider.setVolume(vol);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _volume > 0.5
                              ? Icons.volume_up
                              : (_volume > 0
                                  ? Icons.volume_down
                                  : Icons.volume_off),
                          color: AppColors.primary,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_volume * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Legacy vinyl art (kept for reference)
  Widget _buildVinylArt(PlayerProvider provider) {
    final song = provider.currentSong;
    final size = MediaQuery.of(context).size.width * 0.75;
    final vinylSize = size * 0.85;

    return GestureDetector(
      onDoubleTap:
          () => setState(() => _showVolumeControl = !_showVolumeControl),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kSkyBlue.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),

            // Circular Volume Control (2/3 arc around album)
            if (_showVolumeControl)
              CircularVolumeControl(
                volume: _volume,
                size: size,
                onVolumeChanged: (vol) {
                  setState(() => _volume = vol);
                  _playerProvider.setVolume(vol);
                },
                child: const SizedBox.shrink(),
              ),

            // Vinyl record background
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: vinylSize,
                height: vinylSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.grey[800]!,
                      Colors.grey[900]!,
                      Colors.black,
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vinyl grooves
                    ...List.generate(8, (index) {
                      final radius = (vinylSize / 2) * (0.4 + index * 0.07);
                      return Container(
                        width: radius * 2,
                        height: radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[700]!.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      );
                    }),

                    // Center album art
                    Container(
                      width: vinylSize * 0.55,
                      height: vinylSize * 0.55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kSkyBlue, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: kSkyBlue.withOpacity(0.4),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            song?.imageUrl != null
                                ? Image.network(
                                  song!.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => _defaultAlbumArt(),
                                )
                                : _defaultAlbumArt(),
                      ),
                    ),

                    // Center hole
                    Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: kDarkBg,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating icons
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: kSkyBlue,
                  size: 20,
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: GestureDetector(
                onTap:
                    () => setState(
                      () => _showVolumeControl = !_showVolumeControl,
                    ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        _showVolumeControl
                            ? kSkyBlue.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border:
                        _showVolumeControl
                            ? Border.all(color: kSkyBlue, width: 1)
                            : null,
                  ),
                  child: Icon(
                    _showVolumeControl
                        ? Icons.volume_up
                        : Icons.volume_up_outlined,
                    color: _showVolumeControl ? kSkyBlue : Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ),

            // Volume percentage indicator
            if (_showVolumeControl)
              Positioned(
                bottom: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kSkyBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kSkyBlue.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Volume: ${(_volume * 100).round()}%',
                    style: const TextStyle(
                      color: kSkyBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAlbumArt() {
    return Container(
      color: kDarkBgLight,
      child: const Icon(Icons.music_note, color: kSkyBlue, size: 60),
    );
  }

  Widget _buildSongInfo(PlayerProvider provider) {
    final song = provider.currentSong;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Play count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, color: Colors.grey[500], size: 14),
              const SizedBox(width: 4),
              Text(
                '${(1000 + (song?.id ?? 0) * 123) % 10000} Plays',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Song title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  song?.title ?? 'Unknown Title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Favorite button
              Consumer<LibraryProvider>(
                builder: (context, libraryProvider, _) {
                  if (song == null) return const SizedBox.shrink();
                  final isFavorite = libraryProvider.favoritesPlaylist.songs
                      .any((s) => s.id == song.id);
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.pinkAccent : Colors.grey,
                      size: 24,
                    ),
                    onPressed: () => libraryProvider.toggleFavorite(song),
                  );
                },
              ),
            ],
          ),

          // Artist
          Text(
            song?.artist ?? 'Unknown Artist',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformProgress(PlayerProvider provider) {
    final position = provider.state.currentPosition;
    final duration = provider.state.totalDuration;
    final progress =
        duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Smooth animated waveform visualization
          AnimatedWaveform(
            progress: progress,
            isPlaying: provider.isPlaying,
            height: 60,
            activeColor: kSkyBlue,
            inactiveColor: const Color(0xFF3A3A5A),
          ),
          const SizedBox(height: 16),

          // Time display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / ${_formatDuration(duration)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),

          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kSkyBlue,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: kSkyBlue,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * duration.inMilliseconds).round(),
                );
                provider.updatePosition(newPosition);
              },
            ),
          ),

          // AutoMix indicator
          if (provider.state.isAutoMixEnabled)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    provider.state.isCrossfading
                        ? kSkyBlue.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      provider.state.isCrossfading
                          ? kSkyBlue
                          : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.state.isCrossfading
                        ? Icons.sync
                        : Icons.auto_awesome,
                    size: 14,
                    color:
                        provider.state.isCrossfading
                            ? kSkyBlue
                            : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.state.isCrossfading
                        ? 'Đang chuyển bài...'
                        : 'AutoMix ${provider.state.crossfadeDurationSeconds}s',
                    style: TextStyle(
                      color:
                          provider.state.isCrossfading
                              ? kSkyBlue
                              : Colors.white70,
                      fontSize: 12,
                      fontWeight:
                          provider.state.isCrossfading
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                  if (provider.state.isCrossfading) ...[
                    const SizedBox(width: 6),
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kSkyBlue,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, PlayerProvider provider) {
    return Consumer<SubscriptionProvider>(
      builder:
          (context, sub, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous
                _buildControlButton(
                  icon: Icons.skip_previous_rounded,
                  size: 32,
                  onPressed: () async {
                    final ok = await provider.tryPreviousTrack(
                      isPro: sub.isPro,
                    );
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Free tier: Bạn đã hết lượt chuyển bài',
                          ),
                        ),
                      );
                    }
                  },
                ),

                // Play/Pause
                GestureDetector(
                  onTap: () => provider.togglePlayPause(),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kSkyBlue, kSkyBlueDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kSkyBlue.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      provider.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

                // Next
                _buildControlButton(
                  icon: Icons.skip_next_rounded,
                  size: 32,
                  onPressed: () async {
                    final ok = await provider.tryNextTrack(isPro: sub.isPro);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Free tier: Bạn đã hết lượt chuyển bài',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, PlayerProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Playlist
          _buildActionButton(
            icon: Icons.queue_music,
            label: 'Queue',
            onPressed: _showPlaylistSelector,
          ),

          // Play Mode (Combined Shuffle/Repeat)
          _buildPlayModeButton(provider),

          // AutoMix
          _buildActionButton(
            icon: Icons.auto_awesome,
            label: 'AutoMix',
            isActive: provider.state.isAutoMixEnabled,
            onPressed: () => provider.toggleAutoMix(),
          ),

          // Download
          Consumer<SubscriptionProvider>(
            builder:
                (context, sub, _) => _buildActionButton(
                  icon: Icons.download,
                  label: 'Download',
                  onPressed: _handleDownload,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayModeButton(PlayerProvider provider) {
    final mode = provider.playMode;
    IconData icon;
    String label;
    bool isActive = mode != PlayMode.normal;

    switch (mode) {
      case PlayMode.normal:
        icon = Icons.arrow_forward;
        label = 'Normal';
        break;
      case PlayMode.shuffle:
        icon = Icons.shuffle;
        label = 'Shuffle';
        break;
      case PlayMode.repeatOne:
        icon = Icons.repeat_one;
        label = 'Repeat 1';
        break;
      case PlayMode.repeatAll:
        icon = Icons.repeat;
        label = 'Repeat';
        break;
    }

    return _buildActionButton(
      icon: icon,
      label: label,
      isActive: isActive,
      onPressed: () => provider.cyclePlayMode(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isActive
                      ? kSkyBlue.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: isActive ? Border.all(color: kSkyBlue, width: 1) : null,
            ),
            child: Icon(
              icon,
              color: isActive ? kSkyBlue : Colors.white70,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? kSkyBlue : Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(PlayerProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.comment, color: kSkyBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ChangeNotifierProvider(
            create: (_) => CommentProvider(),
            child: CommentsSection(songId: provider.currentSong!.id),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // === Handler methods ===

  Future<void> _showPlaylistSelector() async {
    final player = context.read<PlayerProvider>();
    final current = player.currentSong;
    if (current == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không có bài hát để thêm')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) {
      Navigator.pushNamed(context, '/signin');
      return;
    }

    final lib = context.read<LibraryProvider>();
    if (lib.folders.isEmpty && !lib.isLoading) {
      await lib.fetchLibrary();
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => PlaylistSelectorBottomSheet(
            onPlaylistSelected: (playlistId) async {
              final ok = await player.addToPlaylist(playlistId);
              if (ok) {
                await lib.fetchLibrary();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã thêm vào playlist')),
                  );
                }
              }
            },
          ),
    );
  }

  void _showArtistInfo() {
    final provider = context.read<PlayerProvider>();
    if (provider.currentSong != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder:
            (context) => ArtistInfoBottomSheet(
              artistName: provider.currentSong!.artist,
              onClose: () => Navigator.pop(context),
            ),
      );
    }
  }

  Future<void> _handleDownload() async {
    final sub = context.read<SubscriptionProvider>();
    if (!sub.isPro) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Yêu cầu gói Pro'),
              content: const Text('Bạn cần nâng cấp gói Pro để tải bài hát'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Để sau'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UpgradeProPage()),
                    );
                  },
                  child: const Text('Nâng cấp Pro'),
                ),
              ],
            ),
      );
      return;
    }

    final provider = context.read<PlayerProvider>();
    final ok = await provider.downloadCurrentSong();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Đã tải bài hát' : 'Tải xuống thất bại'),
        backgroundColor: ok ? kSkyBlue : Colors.red,
      ),
    );
  }

  void _handleShare() {
    final provider = context.read<PlayerProvider>();
    if (provider.currentSong != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chia sẻ: ${provider.currentSong!.title}'),
          backgroundColor: kSkyBlue,
        ),
      );
    }
  }
}

// WaveformPainter moved to widgets/animated_waveform.dart
