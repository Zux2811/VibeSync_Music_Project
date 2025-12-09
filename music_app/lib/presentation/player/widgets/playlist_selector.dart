// lib/presentation/player/widgets/playlist_selector.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_app/presentation/home/tabs/library/library_provider.dart';

class PlaylistSelectorBottomSheet extends StatefulWidget {
  final Function(int) onPlaylistSelected;

  const PlaylistSelectorBottomSheet({
    Key? key,
    required this.onPlaylistSelected,
  }) : super(key: key);

  @override
  State<PlaylistSelectorBottomSheet> createState() =>
      _PlaylistSelectorBottomSheetState();
}

class _PlaylistSelectorBottomSheetState
    extends State<PlaylistSelectorBottomSheet> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ensure library is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lib = context.read<LibraryProvider>();
      if (lib.folders.isEmpty && lib.rootPlaylists.isEmpty && !lib.isLoading) {
        await lib.fetchLibrary();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final divider = Theme.of(context).dividerColor;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add to Playlist',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    // Search (optional)
                    TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search playlist',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              Divider(color: divider),

              // Body
              Flexible(
                child: Consumer<LibraryProvider>(
                  builder: (context, lib, _) {
                    if (lib.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Flatten playlists
                    final playlistsFromFolders = lib.folders.expand(
                      (f) => f.playlists.map(
                        (p) => {'id': p.id, 'name': p.name, 'folder': f.name},
                      ),
                    );

                    final playlistsFromRoot = lib.rootPlaylists.map(
                      (p) => {
                        'id': p.id,
                        'name': p.name,
                        'folder': '', // Root playlists have no folder
                      },
                    );

                    final all =
                        [
                          ...playlistsFromRoot,
                          ...playlistsFromFolders,
                        ].toList();

                    // Filter by search
                    final query = _search.text.trim().toLowerCase();
                    final filtered =
                        query.isEmpty
                            ? all
                            : all
                                .where(
                                  (e) =>
                                      (e['name'] as String)
                                          .toLowerCase()
                                          .contains(query) ||
                                      (e['folder'] as String)
                                          .toLowerCase()
                                          .contains(query),
                                )
                                .toList();

                    if (filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 24),
                            const Icon(Icons.info_outline, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              lib.folders.isEmpty && lib.rootPlaylists.isEmpty
                                  ? 'Bạn chưa có playlist. Hãy tạo trong Library.'
                                  : 'Không tìm thấy playlist phù hợp',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(color: divider),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final title = item['name'] as String? ?? '';
                        final folder = item['folder'] as String? ?? '';
                        final idStr = item['id']?.toString() ?? '';
                        return ListTile(
                          leading: const Icon(Icons.playlist_play),
                          title: Text(title),
                          subtitle:
                              folder.isNotEmpty
                                  ? Text('Folder: $folder')
                                  : null,
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            final idNum = int.tryParse(idStr);
                            if (idNum == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ID playlist không hợp lệ'),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context);
                            widget.onPlaylistSelected(idNum);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
