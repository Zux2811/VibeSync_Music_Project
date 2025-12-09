import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_app/presentation/home/tabs/library/library_provider.dart';
import 'package:music_app/data/models/folder.dart';
import 'package:music_app/data/models/playlist.dart';
import 'package:music_app/presentation/home/tabs/library/playlist_detail_page.dart';
import 'package:music_app/presentation/home/tabs/library/library_actions.dart';
import 'package:music_app/presentation/home/tabs/library/actions/playlist_menu.dart';
import 'package:music_app/presentation/home/tabs/library/widgets/folder_node.dart';

class FolderDetailPage extends StatefulWidget {
  final Folder folder;
  const FolderDetailPage({super.key, required this.folder});

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  final Set<String> _expandedIds = <String>{};
  @override
  void initState() {
    super.initState();
    // Refresh to ensure latest playlists after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().fetchLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.folder.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actionsIconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Tạo thư mục con',
            onPressed:
                () => LibraryActions.showCreateSubFolderDialog(
                  context,
                  widget.folder,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.library_add_outlined),
            tooltip: 'Tạo playlist trong thư mục',
            onPressed:
                () => LibraryActions.showCreatePlaylistInFolderDialog(
                  context,
                  widget.folder,
                ),
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, provider, child) {
          // Find the folder again from the provider to get the latest data
          final folder =
              provider.findFolderById(widget.folder.id) ?? widget.folder;
          final subFolders = folder.subFolders;
          final playlists = folder.playlists;

          if (subFolders.isEmpty && playlists.isEmpty) {
            return const Center(child: Text('Thư mục này trống'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: [
              // Render sub-folders
              ...subFolders.map(
                (sub) => FolderNode(
                  folder: sub,
                  expandedIds: _expandedIds,
                  playlistTileBuilder: _buildPlaylistTile,
                  onOpenFolder:
                      (f) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FolderDetailPage(folder: f),
                        ),
                      ),
                ),
              ),

              if (subFolders.isNotEmpty && playlists.isNotEmpty)
                const Divider(height: 24, indent: 16, endIndent: 16),

              // Render playlists
              ...playlists.map((p) => _buildPlaylistTile(context, p)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaylistTile(
    BuildContext context,
    Playlist playlist, {
    bool inFolder = false,
  }) {
    // hiện hình ảnh playlist (file cục bộ, network hoặc asset)
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
      padding: EdgeInsets.only(left: inFolder ? 20.0 : 0),
      child: ListTile(
        leading: SizedBox(width: 50, height: 50, child: leadingWidget),
        title: Text(playlist.name),
        subtitle: Text('${playlist.songs.length} bài hát'),
        trailing: PlaylistMenu.build(context, playlist),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistDetailPage(playlist: playlist),
              ),
            ),
      ),
    );
  }
}
