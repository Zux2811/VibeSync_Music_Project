import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'library_provider.dart';
import 'library_actions.dart';
import 'playlist_detail_page.dart';
import 'favorites_page.dart';
import 'pages/folder_detail_page.dart';
import 'actions/playlist_menu.dart';
import 'pages/downloaded_songs_page.dart';
import 'widgets/folder_node.dart';
import '../../../../data/models/playlist.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final Set<String> _expandedIds = <String>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().fetchLibrary();
      context.read<LibraryProvider>().fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Thư viện",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actionsIconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Tạo Playlist mới',
            onPressed: () => LibraryActions.showCreatePlaylistDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Tạo Thư mục mới',
            onPressed: () => LibraryActions.showCreateFolderDialog(context),
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchLibrary(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildFavoritesTile(context, provider.favoritesPlaylist),
              const SizedBox(height: 16),

              _buildDownloadedTile(context),
              const SizedBox(height: 16),

              // Root playlists (not inside any folder)
              ...provider.rootPlaylists.map((playlist) {
                return _buildPlaylistTile(context, playlist);
              }),

              // Folders tree (use FolderNode for per-item expand behavior)
              ...provider.folders.map((folder) {
                return FolderNode(
                  folder: folder,
                  expandedIds: _expandedIds,
                  playlistTileBuilder: _buildPlaylistTile,
                  onOpenFolder:
                      (f) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FolderDetailPage(folder: f),
                        ),
                      ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFavoritesTile(BuildContext context, Playlist playlist) {
    return ListTile(
      leading: const Icon(Icons.favorite, color: Colors.pinkAccent),
      title: Text(playlist.name, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text('${playlist.songs.length} bài hát'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FavoritesPage(favoritesPlaylist: playlist),
          ),
        );
      },
    );
  }

  Widget _buildDownloadedTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.download_done, color: Colors.lightBlueAccent),
      title: Text('Nhạc đã tải', style: Theme.of(context).textTheme.bodyLarge),
      subtitle: const Text('Phát các bài hát bạn đã tải về'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DownloadedSongsPage()),
        );
      },
    );
  }

  Widget _buildPlaylistTile(
    BuildContext context,
    Playlist playlist, {
    bool inFolder = false,
  }) {
    Widget leadingWidget;
    if (playlist.imageUrl != null && playlist.imageUrl!.isNotEmpty) {
      final url = playlist.imageUrl!;
      final isFile = !url.startsWith('http') && !url.startsWith('assets');
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child:
            isFile
                ? Image.file(
                  File(url),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.music_note, size: 30),
                )
                : (url.startsWith('http')
                    ? Image.network(
                      url,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.music_note, size: 30),
                    )
                    : Image.asset(
                      url,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.music_note, size: 30),
                    )),
      );
    } else {
      leadingWidget = const Icon(Icons.music_note_outlined, size: 40);
    }

    return Padding(
      padding: EdgeInsets.only(left: inFolder ? 30.0 : 4.0, bottom: 8.0),
      child: ListTile(
        leading: SizedBox(width: 50, height: 50, child: leadingWidget),
        title: Text(playlist.name),
        subtitle: Text('${playlist.songs.length} bài hát'),
        trailing: PlaylistMenu.build(context, playlist),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailPage(playlist: playlist),
            ),
          );
        },
      ),
    );
  }
}
