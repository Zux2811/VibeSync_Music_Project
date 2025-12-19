import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
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
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Consumer<LibraryProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              slivers: [
                // Header with title and actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        // User avatar (like Spotify)
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isDark
                                    ? AppColors.darkBgLighter
                                    : AppColors.lightElevated,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 18,
                            color:
                                isDark
                                    ? Colors.white70
                                    : AppColors.textDarkSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Your Library",
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.textDark,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                          onPressed:
                              () => LibraryActions.showCreatePlaylistDialog(
                                context,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter chips
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterChip('Playlists', true, isDark),
                        _buildFilterChip('Artists', false, isDark),
                        _buildFilterChip('Albums', false, isDark),
                        _buildFilterChip('Downloaded', false, isDark),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Loading or error state
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.errorMessage != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(provider.errorMessage!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.fetchLibrary(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildListDelegate([
                      // Favorites
                      _buildFavoritesTile(
                        context,
                        provider.favoritesPlaylist,
                        isDark,
                      ),

                      // Downloaded
                      _buildDownloadedTile(context, isDark),

                      // Root playlists
                      ...provider.rootPlaylists.map((playlist) {
                        return _buildPlaylistTile(
                          context,
                          playlist,
                          isDark: isDark,
                        );
                      }),

                      // Folders
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

                      // Bottom spacing
                      const SizedBox(height: 100),
                    ]),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (value) {},
        backgroundColor: isDark ? AppColors.darkBgLighter : Colors.white,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color:
              isSelected
                  ? Colors.black
                  : (isDark ? Colors.white : AppColors.textDark),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildFavoritesTile(
    BuildContext context,
    Playlist playlist,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FavoritesPage(favoritesPlaylist: playlist),
            ),
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Gradient icon background (Spotify Liked Songs style)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5D4CF7), Color(0xFFB7A8FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liked Songs',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Playlist • ${playlist.songs.length} songs',
                      style: TextStyle(
                        color:
                            isDark
                                ? AppColors.textSecondary
                                : AppColors.textDarkSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadedTile(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DownloadedSongsPage()),
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.download_done,
                  color: Colors.black,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Downloaded',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Downloaded songs',
                      style: TextStyle(
                        color:
                            isDark
                                ? AppColors.textSecondary
                                : AppColors.textDarkSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(
    BuildContext context,
    Playlist playlist, {
    bool inFolder = false,
    bool isDark = true,
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
