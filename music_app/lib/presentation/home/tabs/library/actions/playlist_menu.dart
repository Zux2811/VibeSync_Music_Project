import 'package:flutter/material.dart';

import 'package:music_app/presentation/home/tabs/library/library_actions.dart';
import 'package:music_app/data/models/playlist.dart';

class PlaylistMenu {
  static Widget build(BuildContext context, Playlist playlist) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'rename':
            LibraryActions.showRenameDialog(
              context,
              playlist.id,
              playlist.name,
              false,
            );
            break;
          case 'image':
            await LibraryActions.changePlaylistImage(context, playlist);
            break;
          case 'move':
            LibraryActions.showMovePlaylistDialog(context, playlist);
            break;
          case 'delete':
            LibraryActions.showDeletePlaylistDialog(context, playlist);
            break;
        }
      },
      itemBuilder:
          (ctx) => [
            PopupMenuItem(
              value: 'rename',
              child: Row(
                children: const [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 12),
                  Text('Đổi tên playlist'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'image',
              child: Row(
                children: const [
                  Icon(Icons.image_outlined),
                  SizedBox(width: 12),
                  Text('Thay đổi hình ảnh'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'move',
              child: Row(
                children: const [
                  Icon(Icons.drive_file_move_outline),
                  SizedBox(width: 12),
                  Text('Di chuyển playlist'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete_outline, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Text(
                    'Xóa playlist',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
    );
  }
}
