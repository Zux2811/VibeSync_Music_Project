import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/playlist.dart';
import '../../../../data/models/player_state_model.dart';
import '../../../player/player_provider.dart';
import '../../../player/player_page.dart';

class FavoritesPage extends StatefulWidget {
  final Playlist favoritesPlaylist;

  const FavoritesPage({super.key, required this.favoritesPlaylist});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.favoritesPlaylist.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildFavoritesContent(context),
      ),
    );
  }

  Widget _buildFavoritesContent(BuildContext context) {
    if (widget.favoritesPlaylist.songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài hát yêu thích',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn trái tim để thêm vào đây nhé',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.favoritesPlaylist.songs.length,
      itemBuilder: (context, index) {
        final song = widget.favoritesPlaylist.songs[index];
        return _buildSongTile(context, song, index);
      },
    );
  }

  Widget _buildSongTile(BuildContext context, Song song, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            song.imageUrl ?? '',
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) => Container(
                  width: 56,
                  height: 56,
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.music_note,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
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
          onPressed: () => _playSong(context, song),
        ),
        onTap: () => _playSong(context, song),
      ),
    );
  }

  void _playSong(BuildContext context, Song song) {
    final playerProvider = context.read<PlayerProvider>();
    playerProvider.setPlaylistAndPlay(
      widget.favoritesPlaylist.songs,
      currentSong: song,
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const PlayerPage();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
