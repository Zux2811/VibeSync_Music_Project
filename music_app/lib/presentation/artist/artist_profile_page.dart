import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/artist_model.dart';
import '../../data/models/player_state_model.dart';
import '../../data/sources/artist_service.dart';
import '../player/player_provider.dart';

class ArtistProfilePage extends StatefulWidget {
  final int artistId;

  const ArtistProfilePage({super.key, required this.artistId});

  @override
  State<ArtistProfilePage> createState() => _ArtistProfilePageState();
}

class _ArtistProfilePageState extends State<ArtistProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Artist? _artist;
  List<Song> _songs = [];
  List<Album> _albums = [];
  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadArtistData();
  }

  Future<void> _loadArtistData() async {
    setState(() => _isLoading = true);
    try {
      final artist = await ArtistService.getArtistById(widget.artistId);
      final songs = await ArtistService.getArtistSongs(widget.artistId);
      final albums = await ArtistService.getArtistAlbums(widget.artistId);

      if (mounted) {
        setState(() {
          _artist = artist;
          _songs = songs;
          _albums = albums;
          _isFollowing = artist?.isFollowing ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final success = await ArtistService.toggleFollowArtist(widget.artistId);
    if (success && mounted) {
      setState(() => _isFollowing = !_isFollowing);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_artist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Artist not found')),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: responsive.isDesktop ? 350 : 280,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover image
                    if (_artist!.coverUrl != null)
                      Image.network(
                        _artist!.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) =>
                                Container(color: primaryColor.withOpacity(0.3)),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    // Artist info
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: responsive.isDesktop ? 60 : 45,
                            backgroundImage:
                                _artist!.avatarUrl != null
                                    ? NetworkImage(_artist!.avatarUrl!)
                                    : null,
                            child:
                                _artist!.avatarUrl == null
                                    ? Icon(
                                      Icons.person,
                                      size: responsive.isDesktop ? 50 : 35,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _artist!.displayName,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              responsive.isDesktop ? 32 : 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_artist!.isVerified)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.verified,
                                          color: Colors.blue,
                                          size: responsive.isDesktop ? 28 : 22,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatNumber(_artist!.followers)} followers • ${_formatNumber(_artist!.totalPlays)} plays',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: responsive.isDesktop ? 16 : 14,
                                  ),
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
            ),
          ];
        },
        body: Column(
          children: [
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Follow button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleFollow,
                      icon: Icon(_isFollowing ? Icons.check : Icons.add),
                      label: Text(_isFollowing ? 'Following' : 'Follow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isFollowing ? Colors.grey : primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Play all button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _songs.isNotEmpty
                              ? () {
                                final provider = context.read<PlayerProvider>();
                                provider.setPlaylistAndPlay(_songs);
                                Navigator.pushNamed(context, '/player');
                              }
                              : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // More options
                  IconButton(
                    onPressed: () => _showMoreOptions(context),
                    icon: const Icon(Icons.more_vert),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Songs'),
                Tab(text: 'Albums'),
                Tab(text: 'About'),
              ],
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSongsTab(),
                  _buildAlbumsTab(),
                  _buildAboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsTab() {
    if (_songs.isEmpty) {
      return const Center(child: Text('No songs yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                song.imageUrl != null
                    ? Image.network(
                      song.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                    : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note),
                    ),
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () {
              final provider = context.read<PlayerProvider>();
              provider.setPlaylistAndPlay(_songs, currentSong: song);
              Navigator.pushNamed(context, '/player');
            },
          ),
          onTap: () {
            final provider = context.read<PlayerProvider>();
            provider.setPlaylistAndPlay(_songs, currentSong: song);
            Navigator.pushNamed(context, '/player');
          },
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    final responsive = Responsive(context);

    if (_albums.isEmpty) {
      return const Center(child: Text('No albums yet'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsive.gridColumns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return _AlbumCard(album: album);
      },
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_artist!.bio != null && _artist!.bio!.isNotEmpty) ...[
            Text(
              'Bio',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_artist!.bio!),
            const SizedBox(height: 24),
          ],
          // Stats
          Text(
            'Stats',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(label: 'Songs', value: _songs.length.toString()),
              const SizedBox(width: 12),
              _StatCard(label: 'Albums', value: _albums.length.toString()),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Followers',
                value: _formatNumber(_artist!.followers),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Social links
          if (_artist!.socialLinks.isNotEmpty) ...[
            Text(
              'Connect',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: _buildSocialLinks()),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSocialLinks() {
    final links = <Widget>[];
    final socialLinks = _artist!.socialLinks;

    if (socialLinks['facebook'] != null) {
      links.add(_SocialButton(icon: Icons.facebook, label: 'Facebook'));
    }
    if (socialLinks['youtube'] != null) {
      links.add(_SocialButton(icon: Icons.play_circle, label: 'YouTube'));
    }
    if (socialLinks['spotify'] != null) {
      links.add(_SocialButton(icon: Icons.music_note, label: 'Spotify'));
    }
    if (socialLinks['instagram'] != null) {
      links.add(_SocialButton(icon: Icons.camera_alt, label: 'Instagram'));
    }
    if (socialLinks['website'] != null) {
      links.add(_SocialButton(icon: Icons.language, label: 'Website'));
    }

    return links;
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SocialButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;

  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // Navigate to album detail
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child:
                    album.coverUrl != null
                        ? Image.network(
                          album.coverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                        : Container(
                          color:
                              isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                          child: const Center(
                            child: Icon(Icons.album, size: 48),
                          ),
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${album.totalTracks} tracks • ${album.albumType}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
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
