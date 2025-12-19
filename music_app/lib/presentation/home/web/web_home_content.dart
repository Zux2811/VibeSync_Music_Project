import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/sources/api_service.dart';
import '../../../data/sources/artist_service.dart';
import '../../../data/models/player_state_model.dart';
import '../../../data/models/artist_model.dart';
import '../../player/player_provider.dart';
import '../../subscription/upgrade_pro_page.dart';

class WebHomeContent extends StatefulWidget {
  const WebHomeContent({super.key});

  @override
  State<WebHomeContent> createState() => _WebHomeContentState();
}

class _WebHomeContentState extends State<WebHomeContent> {
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
        ApiService.getSongsPage(page: 1, limit: 20),
        ArtistService.getArtists(limit: 10),
      ]);

      if (mounted) {
        setState(() {
          _songs =
              (results[0] as Map<String, dynamic>)['items']
                  ?.cast<Map<String, dynamic>>() ??
              [];
          _artists = results[1] as List<Artist>;
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Content Area
        Expanded(
          flex: 3,
          child: SingleChildScrollView(padding: const EdgeInsets.all(24)),
        ),

        // Right Sidebar
        Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildPremiumBanner(),
                const SizedBox(height: 24),
                _buildTopArtistsSection(),
              ],
            ),
          ),
        ),
      ],
    );
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Explore more',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
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

  String _formatDuration(dynamic seconds) {
    if (seconds == null || seconds == 0) return '0:00';
    final int secs =
        seconds is int ? seconds : int.tryParse(seconds.toString()) ?? 0;
    final minutes = secs ~/ 60;
    final remainingSeconds = secs % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Sky blue theme color
  static const Color _primaryColor = Color(0xFF42A5F5);
  static const Color _primaryDark = Color(0xFF1E88E5);

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpgradeProPage()),
        );
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [_primaryColor, _primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Upgrade to',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Unlock all features',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
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
        ...List.generate(_artists.length > 6 ? 6 : _artists.length, (index) {
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
        padding: const EdgeInsets.symmetric(vertical: 8),
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
            const SizedBox(width: 12),
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
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(
                    artist,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Duration
            Text(
              duration,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            // Play button
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF42A5F5).withOpacity(0.3),
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
            const SizedBox(width: 8),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
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
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatCount(followers)} Followers • ${_formatCount(plays)} Plays',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
