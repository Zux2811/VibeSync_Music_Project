// lib/presentation/home/tabs/library/library_actions.dart
// Chứa toàn bộ dialog/bottom-sheet và hành động UI cho tab Thư viện (Library).
// Mục tiêu: tách logic UI phụ trợ ra khỏi LibraryTab để file gốc gọn gàng hơn.

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'library_provider.dart';
import '../../../../data/models/folder.dart';
import '../../../../data/models/playlist.dart';

class LibraryActions {
  // Tạo Thư mục mới ở cấp gốc
  static void showCreateFolderDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tạo Thư mục mới'),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Tên thư mục'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    context.read<LibraryProvider>().createFolder(name);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Tạo'),
              ),
            ],
          ),
    );
  }

  // Tạo Playlist mới (cho phép lưu ở ngoài hoặc chọn thư mục)
  static void showCreatePlaylistDialog(BuildContext context) {
    final nameController = TextEditingController();
    String? selectedFolderId;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tạo Playlist mới'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Tên playlist'),
                  ),
                  const SizedBox(height: 16),
                  Consumer<LibraryProvider>(
                    builder: (context, provider, child) {
                      return DropdownButtonFormField<String?>(
                        isExpanded:
                            true, // <-- Thêm dòng này để sửa lỗi overflow
                        decoration: const InputDecoration(
                          labelText: 'Chọn thư mục (không bắt buộc)',
                        ),
                        value: selectedFolderId,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Lưu ở ngoài (không thuộc thư mục)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...provider.folders.map(
                            (folder) => DropdownMenuItem<String?>(
                              value: folder.id,
                              child: Text(
                                folder.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged:
                            (value) => setState(() => selectedFolderId = value),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      context.read<LibraryProvider>().createPlaylist(
                        name,
                        folderId: selectedFolderId,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Tạo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Menu ngữ cảnh cho Folder
  static void showFolderContextMenu(BuildContext context, Folder folder) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Sửa tên Thư mục'),
                onTap: () {
                  Navigator.pop(ctx);
                  showRenameDialog(context, folder.id, folder.name, true);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Xóa Thư mục',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showDeleteConfirmDialog(
                    context,
                    folder.id,
                    folder.name,
                    true,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.library_add_outlined),
                title: const Text('Tạo playlist trong thư mục'),
                onTap: () {
                  Navigator.pop(ctx);
                  showCreatePlaylistInFolderDialog(context, folder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('Tạo thư mục con'),
                onTap: () {
                  Navigator.pop(ctx);
                  showCreateSubFolderDialog(context, folder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move_outline),
                title: const Text('Di chuyển thư mục'),
                onTap: () {
                  Navigator.pop(ctx);
                  showMoveFolderDialog(context, folder);
                },
              ),
            ],
          ),
    );
  }

  // Menu ngữ cảnh cho Playlist
  static void showPlaylistContextMenu(BuildContext context, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Sửa tên Playlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  showRenameDialog(context, playlist.id, playlist.name, false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Thay đổi hình ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSetPlaylistImage(context, playlist);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move_outline),
                title: const Text('Di chuyển Playlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  showMovePlaylistDialog(context, playlist);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Xóa Playlist',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showDeleteConfirmDialog(
                    context,
                    playlist.id,
                    playlist.name,
                    false,
                  );
                },
              ),
            ],
          ),
    );
  }

  // Đổi tên Folder/Playlist
  static void showRenameDialog(
    BuildContext context,
    String id,
    String currentName,
    bool isFolder,
  ) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isFolder ? 'Sửa tên Thư mục' : 'Sửa tên Playlist'),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Tên mới'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    final lib = context.read<LibraryProvider>();
                    if (isFolder) {
                      await lib.renameFolder(id, name);
                    } else {
                      await lib.renamePlaylist(id, name);
                    }
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
    );
  }

  // Xác nhận xóa chung (Folder/Playlist)
  static void showDeleteConfirmDialog(
    BuildContext context,
    String id,
    String name,
    bool isFolder,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isFolder ? 'Xóa Thư mục?' : 'Xóa Playlist?'),
            content: Text(
              'Bạn có chắc chắn muốn xóa "$name" không? Hành động này không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  final lib = context.read<LibraryProvider>();
                  if (isFolder) {
                    await lib.deleteFolder(id);
                  } else {
                    await lib.deletePlaylist(id);
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                },
                child: const Text(
                  'Xóa',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }

  // Dialog tạo playlist bên trong một Folder
  static void showCreatePlaylistInFolderDialog(
    BuildContext context,
    Folder folder,
  ) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Tạo playlist trong "${folder.name}"'),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Tên playlist'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    context.read<LibraryProvider>().createPlaylist(
                      name,
                      folderId: folder.id,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Tạo'),
              ),
            ],
          ),
    );
  }

  // Dialog tạo thư mục con
  static void showCreateSubFolderDialog(BuildContext context, Folder folder) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Tạo thư mục trong "${folder.name}"'),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Tên thư mục'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    context.read<LibraryProvider>().createFolder(
                      name,
                      parentId: folder.id,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Tạo'),
              ),
            ],
          ),
    );
  }

  // Dialog di chuyển thư mục
  static void showMoveFolderDialog(BuildContext context, Folder folder) {
    String? selectedParentId;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final lib = context.read<LibraryProvider>();
            final available =
                lib.folders.where((f) => f.id != folder.id).toList();
            return AlertDialog(
              title: Text('Di chuyển "${folder.name}"'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    value: selectedParentId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Thư mục gốc'),
                      ),
                      ...available.map(
                        (f) => DropdownMenuItem<String?>(
                          value: f.id,
                          child: Text(f.name),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => selectedParentId = val),
                    decoration: const InputDecoration(
                      labelText: 'Chọn thư mục đích',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () async {
                    await context.read<LibraryProvider>().moveFolder(
                      folder.id,
                      selectedParentId,
                    );
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                  child: const Text('Di chuyển'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog di chuyển playlist
  static void showMovePlaylistDialog(BuildContext context, Playlist playlist) {
    String? selectedFolderId = context
        .read<LibraryProvider>()
        .findParentFolderId(playlist.id);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final provider = context.read<LibraryProvider>();
            return AlertDialog(
              title: Text('Di chuyển "${playlist.name}"'),
              content: DropdownButtonFormField<String?>(
                value: selectedFolderId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Chọn thư mục đích',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Lưu ở ngoài (Thư mục gốc)'),
                  ),
                  ...provider.folders.map(
                    (folder) => DropdownMenuItem<String?>(
                      value: folder.id,
                      child: Text(folder.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedFolderId = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    context.read<LibraryProvider>().movePlaylist(
                      playlist.id,
                      selectedFolderId,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Di chuyển'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Hàm chọn, cắt và cập nhật ảnh cho playlist
  static Future<void> _pickAndSetPlaylistImage(
    BuildContext context,
    Playlist playlist,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(
          ratioX: 1,
          ratioY: 1,
        ), // Crop as a square
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cắt ảnh Playlist',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Cắt ảnh Playlist',
            doneButtonTitle: 'Xong',
            cancelButtonTitle: 'Hủy',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        // ignore: use_build_context_synchronously
        await context.read<LibraryProvider>().updatePlaylistImage(
          playlist.id,
          croppedFile.path,
        );
      }
    }
  }

  // Public wrapper để gọi thay đổi hình ảnh từ nơi khác
  static Future<void> changePlaylistImage(
    BuildContext context,
    Playlist playlist,
  ) async {
    await _pickAndSetPlaylistImage(context, playlist);
  }

  // Bao hàm cụ thể để gọi lại nếu cần (tách biệt 2 loại xóa để dùng ở nơi khác)
  static void showDeleteFolderDialog(BuildContext context, Folder folder) {
    showDeleteConfirmDialog(context, folder.id, folder.name, true);
  }

  static void showDeletePlaylistDialog(
    BuildContext context,
    Playlist playlist,
  ) {
    showDeleteConfirmDialog(context, playlist.id, playlist.name, false);
  }
}
