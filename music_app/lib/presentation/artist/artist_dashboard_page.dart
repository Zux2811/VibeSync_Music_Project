import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/artist_model.dart';
import '../../data/models/player_state_model.dart';
import '../../data/sources/artist_service.dart';

class ArtistDashboardPage extends StatefulWidget {
  const ArtistDashboardPage({super.key});

  @override
  State<ArtistDashboardPage> createState() => _ArtistDashboardPageState();
}

class _ArtistDashboardPageState extends State<ArtistDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ArtistStats? _stats;
  List<Song> _songs = [];
  List<Album> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ArtistService.getMyStats();
      final songs = await ArtistService.getMySongs();
      final albums = await ArtistService.getMyAlbums();
      if (mounted) {
        setState(() {
          _stats = stats;
          _songs = songs;
          _albums = albums;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Stats cards
                  Padding(
                    padding: EdgeInsets.all(responsive.horizontalPadding),
                    child: _buildStatsSection(responsive),
                  ),
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.music_note), text: 'My Songs'),
                      Tab(icon: Icon(Icons.album), text: 'Albums'),
                      Tab(icon: Icon(Icons.person), text: 'Profile'),
                    ],
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey,
                  ),
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSongsTab(),
                        _buildAlbumsTab(),
                        _buildProfileTab(),
                      ],
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('Upload'),
        backgroundColor: primaryColor,
      ),
    );
  }

  Widget _buildStatsSection(Responsive responsive) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: responsive.isDesktop ? 4 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: responsive.isDesktop ? 2 : 1.5,
      children: [
        _StatCard(
          icon: Icons.headphones,
          label: 'Total Plays',
          value: _formatNumber(_stats?.totalPlays ?? 0),
          color: Colors.blue,
        ),
        _StatCard(
          icon: Icons.people,
          label: 'Followers',
          value: _formatNumber(_stats?.totalFollowers ?? 0),
          color: Colors.green,
        ),
        _StatCard(
          icon: Icons.music_note,
          label: 'Songs',
          value: (_stats?.totalSongs ?? 0).toString(),
          color: Colors.orange,
        ),
        _StatCard(
          icon: Icons.album,
          label: 'Albums',
          value: (_stats?.totalAlbums ?? 0).toString(),
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSongsTab() {
    if (_songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No songs yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showUploadSongDialog(context),
              icon: const Icon(Icons.upload),
              label: const Text('Upload your first song'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return _SongListTile(
            song: song,
            onEdit: () => _showEditSongDialog(context, song),
            onDelete: () => _confirmDeleteSong(context, song),
            onToggleVisibility: () => _toggleSongVisibility(song),
          );
        },
      ),
    );
  }

  Widget _buildAlbumsTab() {
    final responsive = Responsive(context);

    if (_albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No albums yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showCreateAlbumDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create your first album'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
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
          return _AlbumCard(
            album: album,
            onEdit: () => _showEditAlbumDialog(context, album),
            onDelete: () => _confirmDeleteAlbum(context, album),
          );
        },
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile editing section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Artist Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit Profile'),
                    subtitle: const Text(
                      'Update your bio, photos, and social links',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showEditProfileDialog(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('Change Avatar'),
                    subtitle: const Text('Update your profile picture'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _uploadArtistImage('avatar'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.panorama),
                    title: const Text('Change Cover'),
                    subtitle: const Text('Update your cover image'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _uploadArtistImage('cover'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Verification status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _stats?.verified == true
                        ? Icons.verified
                        : Icons.info_outline,
                    color: _stats?.verified == true ? Colors.blue : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stats?.verified == true
                              ? 'Verified Artist'
                              : 'Not Verified',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _stats?.verified == true
                              ? 'Your account is verified'
                              : 'Complete verification to get the verified badge',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('Upload Song'),
                onTap: () {
                  Navigator.pop(context);
                  _showUploadSongDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.album),
                title: const Text('Create Album'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateAlbumDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUploadSongDialog(BuildContext context) {
    // TODO: Implement song upload dialog with file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Song upload dialog - To be implemented')),
    );
  }

  void _showEditSongDialog(BuildContext context, Song song) {
    // TODO: Implement edit song dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit song: ${song.title}')));
  }

  void _confirmDeleteSong(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Song'),
            content: Text('Are you sure you want to delete "${song.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Call delete API
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _toggleSongVisibility(Song song) {
    // TODO: Toggle song visibility API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Toggle visibility for: ${song.title}')),
    );
  }

  void _showCreateAlbumDialog(BuildContext context) {
    // TODO: Implement create album dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create album dialog - To be implemented')),
    );
  }

  void _showEditAlbumDialog(BuildContext context, Album album) {
    // TODO: Implement edit album dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit album: ${album.title}')));
  }

  void _confirmDeleteAlbum(BuildContext context, Album album) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Album'),
            content: Text('Are you sure you want to delete "${album.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Call delete API
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    // TODO: Implement edit profile dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile dialog - To be implemented')),
    );
  }

  void _uploadArtistImage(String type) {
    // TODO: Implement image upload
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Upload $type - To be implemented')));
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
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _SongListTile extends StatelessWidget {
  final Song song;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;

  const _SongListTile({
    required this.song,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
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
          '${_formatDuration(song.duration)} • ${song.album ?? "Single"}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton(
          itemBuilder:
              (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'visibility',
                  child: Text('Toggle Visibility'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'visibility':
                onToggleVisibility();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AlbumCard({
    required this.album,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
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
                    if (!album.isPublished)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Draft',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
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
                      '${album.totalTracks} tracks',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: PopupMenuButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
            ),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
          ),
        ),
      ],
    );
  }
}
