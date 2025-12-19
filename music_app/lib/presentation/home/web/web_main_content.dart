import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/sources/api_service.dart';
import '../../../data/sources/artist_service.dart';
import '../../../data/models/player_state_model.dart';
import '../../../data/models/artist_model.dart';
import '../../player/player_provider.dart';

class WebMainContent extends StatefulWidget {
  const WebMainContent({super.key});

  @override
  State<WebMainContent> createState() => _WebMainContentState();
}

class _WebMainContentState extends State<WebMainContent> {
  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> _songs = [];
  List<Artist> _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getPlaylists(),
        ApiService.getSongsPage(page: 1, limit: 20),
        ArtistService.getArtists(limit: 10),
      ]);

      if (mounted) {
        setState(() {
          _playlists = results[0] as List<Map<String, dynamic>>;
          _songs =
              (results[1] as Map<String, dynamic>)['items']
                  ?.cast<Map<String, dynamic>>() ??
              [];
          _artists = results[2] as List<Artist>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Playlist and Top Artist in horizontal layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // My Playlist section - takes more space
              Expanded(flex: 2, child: _buildPlaylistSection()),
              const SizedBox(width: 32),
              // Top Artist section - aligned horizontally
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBgLight : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: _buildTopArtistsSection(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Trending section below
          _buildTrendingSection(),
        ],
      ),
    );
  }

  Widget _buildPlaylistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Playlist',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Explore more',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _playlists.length > 5 ? 5 : _playlists.length,
            itemBuilder: (context, index) {
              final playlist = _playlists[index];
              return _PlaylistCard(
                title: playlist['name'] ?? 'Playlist',
                subtitle: '${playlist['songCount'] ?? 0} tracks',
                imageUrl: playlist['imageUrl'],
                gradientColors: _getGradientColors(index),
                onTap: () {
                  // Navigate to playlist detail
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<Color> _getGradientColors(int index) {
    final gradients = [
      [const Color(0xFFFF6B35), const Color(0xFFFF9068)],
      [const Color(0xFFFF4757), const Color(0xFFFF6B7A)],
      [const Color(0xFFFFA502), const Color(0xFFFFBF00)],
      [const Color(0xFF42A5F5), const Color(0xFF1E88E5)],
      [const Color(0xFF26A69A), const Color(0xFF00897B)],
    ];
    return gradients[index % gradients.length];
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trending',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Explore more',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_songs.length > 6 ? 6 : _songs.length, (index) {
          final song = _songs[index];
          return _TrendingSongTile(
            index: index + 1,
            title: song['title'] ?? 'Unknown',
            artist: song['artist'] ?? 'Unknown',
            duration: _formatDuration(song['duration'] ?? 0),
            imageUrl: song['imageUrl'],
            onTap: () {
              final provider = context.read<PlayerProvider>();
              final songObj = Song.fromJson(song);
              provider.setPlaylistAndPlay(
                _songs.map((m) => Song.fromJson(m)).toList(),
                currentSong: songObj,
              );
              Navigator.pushNamed(context, '/player');
            },
          );
        }),
      ],
    );
  }

  Widget _buildTopArtistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Artist',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...List.generate(_artists.length > 7 ? 7 : _artists.length, (index) {
          final artist = _artists[index];
          return _TopArtistTile(
            name: artist.displayName,
            followers: artist.followers,
            plays: artist.totalPlays,
            imageUrl: artist.avatarUrl,
            isVerified: artist.isVerified,
            onTap: () {
              Navigator.pushNamed(context, '/artist/${artist.id}');
            },
          );
        }),
        if (_artists.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No artists available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  String _formatDuration(dynamic seconds) {
    if (seconds == null || seconds == 0) return '0:00';
    final int secs =
        seconds is int ? seconds : int.tryParse(seconds.toString()) ?? 0;
    final minutes = secs ~/ 60;
    final remainingSeconds = secs % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

// Playlist Card Widget
class _PlaylistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _PlaylistCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card with gradient
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: gradientColors[0],
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Trending Song Tile Widget
class _TrendingSongTile extends StatelessWidget {
  final int index;
  final String title;
  final String artist;
  final String duration;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _TrendingSongTile({
    required this.index,
    required this.title,
    required this.artist,
    required this.duration,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            // Index
            SizedBox(
              width: 30,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  imageUrl != null
                      ? Image.network(
                        imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultImage(),
                      )
                      : _defaultImage(),
            ),
            const SizedBox(width: 16),
            // Title and Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          artist,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Duration
            Text(
              duration,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            // Play button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // More button
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[500], size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.music_note, color: Colors.grey),
    );
  }
}

// Top Artist Tile Widget
class _TopArtistTile extends StatelessWidget {
  final String name;
  final int followers;
  final int plays;
  final String? imageUrl;
  final bool isVerified;
  final VoidCallback? onTap;

  const _TopArtistTile({
    required this.name,
    required this.followers,
    required this.plays,
    this.imageUrl,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image:
                    imageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
                color: imageUrl == null ? Colors.grey[300] : null,
              ),
              child:
                  imageUrl == null
                      ? Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatCount(followers)} Followers',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.play_circle_outline,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatCount(plays)} Plays',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)}k';
    }
    return count.toString();
  }
}
