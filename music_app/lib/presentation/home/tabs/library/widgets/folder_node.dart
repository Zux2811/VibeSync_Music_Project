import 'package:flutter/material.dart';
import 'package:music_app/data/models/folder.dart';
import 'package:music_app/data/models/playlist.dart';
import 'package:music_app/presentation/home/tabs/library/library_actions.dart';

class FolderNode extends StatefulWidget {
  final Folder folder;
  final double indent;
  // Trạng thái mở rộng toàn cục (giúp không bị đóng khi list rebuild)
  final Set<String> expandedIds;
  // Builder dùng để render playlist item theo style của trang chính
  final Widget Function(BuildContext, Playlist, {bool inFolder})
  playlistTileBuilder;
  // Khi người dùng nhấn vào tile (không phải mũi tên), mở trang folder
  final void Function(Folder) onOpenFolder;

  const FolderNode({
    super.key,
    required this.folder,
    required this.expandedIds,
    required this.playlistTileBuilder,
    required this.onOpenFolder,
    this.indent = 0,
  });

  @override
  State<FolderNode> createState() => _FolderNodeState();
}

class _FolderNodeState extends State<FolderNode> {
  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final bool expanded = widget.expandedIds.contains(folder.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: widget.indent),
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: expanded ? 0.5 : 0.0,
                    child: const Icon(Icons.expand_more),
                  ),
                  onPressed:
                      () => setState(() {
                        if (expanded) {
                          widget.expandedIds.remove(folder.id);
                        } else {
                          widget.expandedIds.add(folder.id);
                        }
                      }),
                  tooltip: expanded ? 'Thu gọn' : 'Mở rộng',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'create_playlist':
                        LibraryActions.showCreatePlaylistInFolderDialog(
                          context,
                          folder,
                        );
                        break;
                      case 'create_folder':
                        LibraryActions.showCreateSubFolderDialog(
                          context,
                          folder,
                        );
                        break;
                      case 'rename':
                        LibraryActions.showRenameDialog(
                          context,
                          folder.id,
                          folder.name,
                          true,
                        );
                        break;
                      case 'move':
                        LibraryActions.showMoveFolderDialog(context, folder);
                        break;
                      case 'delete':
                        LibraryActions.showDeleteFolderDialog(context, folder);
                        break;
                    }
                  },
                  itemBuilder:
                      (ctx) => [
                        PopupMenuItem(
                          value: 'create_playlist',
                          child: Row(
                            children: const [
                              Icon(Icons.library_add_outlined),
                              SizedBox(width: 12),
                              Text('Tạo playlist trong thư mục'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'create_folder',
                          child: Row(
                            children: const [
                              Icon(Icons.create_new_folder_outlined),
                              SizedBox(width: 12),
                              Text('Tạo thư mục con'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: const [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 12),
                              Text('Đổi tên thư mục'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'move',
                          child: Row(
                            children: const [
                              Icon(Icons.drive_file_move_outline),
                              SizedBox(width: 12),
                              Text('Di chuyển thư mục'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Xóa thư mục',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            onTap: () => widget.onOpenFolder(folder),
          ),
        ),
        if (expanded) ...[
          // Subfolders
          ...folder.subFolders.map(
            (sub) => FolderNode(
              folder: sub,
              expandedIds: widget.expandedIds,
              indent: widget.indent + 20,
              playlistTileBuilder: widget.playlistTileBuilder,
              onOpenFolder: widget.onOpenFolder,
            ),
          ),
          // Playlists
          ...folder.playlists.map(
            (p) => widget.playlistTileBuilder(context, p, inFolder: true),
          ),
        ],
      ],
    );
  }
}
