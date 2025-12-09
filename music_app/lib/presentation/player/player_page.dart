// lib/presentation/player/player_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/player_state_model.dart';
import 'player_provider.dart';
import 'widgets/player_controls.dart';
import 'widgets/progress_slider.dart';

import 'widgets/player_menu.dart';
import 'widgets/playlist_selector.dart';
import 'widgets/artist_info_sheet.dart';
import '../home/tabs/library/library_provider.dart';
import '../subscription/subscription_provider.dart';
import '../subscription/upgrade_pro_page.dart';

// Comments feature modules
import 'comments/comment_provider.dart';
import 'comments/widgets/comment_list.dart';

class PlayerPage extends StatefulWidget {
  final Song? initialSong;
  final List<Song>? initialPlaylist;

  const PlayerPage({super.key, this.initialSong, this.initialPlaylist});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final PlayerProvider _playerProvider;
  late final VoidCallback _playerErrorListener;

  @override
  void initState() {
    super.initState();
    _playerProvider = context.read<PlayerProvider>();

    // Initialize from arguments if provided, else load default playlist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPlaylist != null) {
        _playerProvider.setPlaylistAndPlay(
          widget.initialPlaylist!,
          currentSong: widget.initialSong,
        );
      } else if (widget.initialSong != null) {
        _playerProvider.playSong(widget.initialSong!);
      } else {
        // Chỉ tự động load playlist mặc định nếu chưa có playlist nào
        if (_playerProvider.state.playlist.isEmpty) {
          _playerProvider.initializePlaylist();
        }
      }
    });

    // Monitor for errors and display them via SnackBar
    _monitorPlayerErrors();
  }

  /// Monitors the PlayerProvider for errors and displays them via SnackBar.
  /// Automatically clears the error after displaying it.
  void _monitorPlayerErrors() {
    _playerErrorListener = () {
      if (_playerProvider.state.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_playerProvider.state.errorMessage!),
            backgroundColor: Colors.red[400],
          ),
        );
        // Clear the error immediately after displaying it
        _playerProvider.clearError();
      }
    };
    _playerProvider.addListener(_playerErrorListener);
  }

  @override
  void dispose() {
    _playerProvider.removeListener(_playerErrorListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Now Playing',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            centerTitle: true,
            actions: [
              Consumer<SubscriptionProvider>(
                builder:
                    (context, sub, _) => PlayerMenu(
                      onAddToPlaylist: _showPlaylistSelector,
                      onViewArtist: _showArtistInfo,
                      onDownload: _handleDownload,
                      onShare: _handleShare,
                      canDownload: sub.isPro,
                    ),
              ),
            ],
          ),
          body: _buildPlayerBody(provider),
        );
      },
    );
  }

  Widget _buildPlayerBody(PlayerProvider provider) {
    if (provider.state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (provider.state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error: ${provider.state.errorMessage}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[400]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                provider.initializePlaylist();
                provider.clearError();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Album Art
            if (provider.currentSong != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    provider.currentSong!.imageUrl != null
                        ? Image.network(
                          provider.currentSong!.imageUrl!,
                          height: MediaQuery.of(context).size.width * 0.85,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                height:
                                    MediaQuery.of(context).size.width * 0.85,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 100,
                                ),
                              ),
                        )
                        : Container(
                          height: MediaQuery.of(context).size.width * 0.85,
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 100,
                          ),
                        ),
              ),
            const SizedBox(height: 24),

            // Song Details
            _SongDetails(provider: provider),
            const SizedBox(height: 16),

            // Progress Slider
            ProgressSlider(
              currentPosition: provider.state.currentPosition,
              totalDuration: provider.state.totalDuration,
              onChanged: (position) => provider.updatePosition(position),
            ),
            const SizedBox(height: 8),

            // Player Controls
            Consumer<SubscriptionProvider>(
              builder:
                  (context, sub, _) => PlayerControls(
                    provider: provider,
                    onPlayPause: () => provider.togglePlayPause(),
                    onNext: () async {
                      final ok = await provider.tryNextTrack(isPro: sub.isPro);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Free tier: Bạn đã hết lượt chuyển bài (6 lần/12 giờ)',
                            ),
                          ),
                        );
                      }
                    },
                    onPrevious: () async {
                      final ok = await provider.tryPreviousTrack(
                        isPro: sub.isPro,
                      );
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Free tier: Bạn đã hết lượt chuyển bài (6 lần/12 giờ)',
                            ),
                          ),
                        );
                      }
                    },
                    onShuffle: () => provider.toggleShuffle(),
                    onRepeat: () => provider.toggleRepeatMode(),
                  ),
            ),

            const SizedBox(height: 16),

            // Comments section (scoped provider)
            if (provider.currentSong != null)
              ChangeNotifierProvider(
                create: (_) => CommentProvider(),
                child: CommentsSection(songId: provider.currentSong!.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPlaylistSelector() async {
    final player = context.read<PlayerProvider>();
    final current = player.currentSong;
    if (current == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không có bài hát để thêm')));
      return;
    }

    // Require login
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) {
      Navigator.pushNamed(context, '/signin');
      return;
    }

    // Ensure library is loaded
    final lib = context.read<LibraryProvider>();
    if (lib.folders.isEmpty && !lib.isLoading) {
      await lib.fetchLibrary();
    }

    // Open selector
    // The selector will call back with selected playlistId
    // We handle API call + feedback here
    // ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => PlaylistSelectorBottomSheet(
            onPlaylistSelected: (playlistId) async {
              final ok = await player.addToPlaylist(playlistId);
              if (ok) {
                // Optionally refresh library to reflect changes
                await lib.fetchLibrary();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm vào playlist')),
                );
              } else {
                final msg =
                    player.state.errorMessage ?? 'Không thể thêm vào playlist';
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
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
    // Extra safety: re-check Pro status before downloading
    final sub = context.read<SubscriptionProvider>();
    if (!sub.isPro) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Yêu cầu gói Pro'),
              content: const Text(
                'bạn cần nâng cấp gói pro để tải được bài hát',
              ),
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
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã tải bài hát xuống thư mục Nhạc đã tải'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tải xuống thất bại. Vui lòng thử lại.')),
      );
    }
  }

  void _handleShare() {
    final provider = context.read<PlayerProvider>();
    if (provider.currentSong != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sharing: ${provider.currentSong!.title}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      // TODO: Implement share functionality
    }
  }
}

class _SongDetails extends StatelessWidget {
  final PlayerProvider provider;

  const _SongDetails({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.currentSong?.title ?? 'Unknown Song',
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  provider.currentSong?.artist ?? 'Unknown Artist',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  /* TODO: Share */
                },
              ),
              Consumer<LibraryProvider>(
                builder: (context, libraryProvider, _) {
                  final currentSong = provider.currentSong;
                  if (currentSong == null) {
                    return const IconButton(
                      icon: Icon(Icons.favorite_border),
                      onPressed: null, // Disabled
                    );
                  }
                  final isFavorite = libraryProvider.favoritesPlaylist.songs
                      .any((s) => s.id == currentSong.id);

                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color:
                          isFavorite
                              ? Colors.pinkAccent
                              : Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () {
                      libraryProvider.toggleFavorite(currentSong);
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
