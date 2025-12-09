import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/core/constants/api_constants.dart';
import 'package:music_app/data/models/folder.dart';
import 'package:music_app/data/models/playlist.dart';
import 'package:music_app/data/models/player_state_model.dart';
import 'package:music_app/data/sources/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/core/utils/logger.dart';

class LibraryProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Playlist _favoritesPlaylist = Playlist(
    id: 'favorites',
    name: 'Bài hát đã thích',
  );
  List<Folder> _folders = [];
  List<Playlist> _rootPlaylists = []; // Playlists not in any folder

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Playlist get favoritesPlaylist => _favoritesPlaylist;
  List<Folder> get folders => _folders;
  List<Playlist> get rootPlaylists => _rootPlaylists;

  void clearLibrary() {
    _folders = [];
    _rootPlaylists = [];
    _favoritesPlaylist = Playlist(id: 'favorites', name: 'Bài hát đã thích');
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Helper để lấy headers kèm token
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      // Ném lỗi hoặc xử lý trường hợp không có token
      throw Exception('Người dùng chưa đăng nhập hoặc token không tồn tại.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchFavorites() async {
    try {
      // Fetch full song records for favorites
      final songJsonList = await ApiService.getFavoriteSongs();

      // Convert JSON maps to Song objects using the Song factory
      final songs = songJsonList.map((json) => Song.fromJson(json)).toList();

      // Update the favorites playlist with the full song data
      _favoritesPlaylist = Playlist(
        id: 'favorites',
        name: 'Bài hát đã thích',
        songs: songs,
      );

      logger.i('Fetched ${songs.length} favorite songs');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch favorites: $e';
      logger.e('Error fetching favorites', error: e);
      notifyListeners();
    }
  }

  Future<void> fetchLibrary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.folders),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          // Legacy response: pure array of folders
          _folders = decoded.map<Folder>((e) => Folder.fromJson(e)).toList();
          _rootPlaylists = [];
        } else if (decoded is Map) {
          final List<dynamic> f = decoded['folders'] ?? [];
          final List<dynamic> rp = decoded['rootPlaylists'] ?? [];
          _folders = f.map<Folder>((e) => Folder.fromJson(e)).toList();
          _rootPlaylists =
              rp.map<Playlist>((e) => Playlist.fromJson(e)).toList();
        } else {
          _folders = [];
          _rootPlaylists = [];
        }
      } else {
        _errorMessage = 'Lỗi ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createFolder(String name, {String? parentId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      logger.i({
        'message': 'Creating folder',
        'name': name,
        'parentId': parentId,
      });
      final headers = await _getAuthHeaders();

      final body = <String, dynamic>{'name': name};
      if (parentId != null) {
        final pidNum = int.tryParse(parentId);
        body['parentId'] = pidNum ?? parentId;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.folders),
        headers: headers,
        body: json.encode(body),
      );

      logger.d({
        'message': 'Create folder response',
        'status': response.statusCode,
        'body': response.body,
      });

      if (response.statusCode == 201) {
        await fetchLibrary(); // reload after create
      } else {
        _errorMessage = 'Lỗi ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
      logger.e('Failed to create folder', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPlaylist(String name, {String? folderId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Build body; folderId is optional (allow root playlists)
      final body = <String, dynamic>{'name': name};
      if (folderId != null && folderId.isNotEmpty) {
        final folderIdNum = int.tryParse(folderId);
        body['folderId'] = folderIdNum ?? folderId;
      } else {
        body['folderId'] = null; // explicitly root
      }

      final response = await http.post(
        Uri.parse(ApiConstants.playlists),
        headers: await _getAuthHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        await fetchLibrary();
      } else {
        _errorMessage = 'Lỗi ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> renameFolder(String folderId, String newName) async {
    _isLoading = true;
    notifyListeners();
    try {
      final idNum = int.tryParse(folderId);
      final response = await http.put(
        Uri.parse('${ApiConstants.folders}/${idNum ?? folderId}'),
        headers: await _getAuthHeaders(),
        body: json.encode({'name': newName}),
      );
      if (response.statusCode == 200) {
        await fetchLibrary();
      } else {
        _errorMessage =
            'Lỗi ${response.statusCode}: Không thể đổi tên thư mục.';
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> moveFolder(String folderId, String? newParentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final idNum = int.tryParse(folderId);
      final parentNum = newParentId != null ? int.tryParse(newParentId) : null;
      final response = await http.put(
        Uri.parse('${ApiConstants.folders}/${idNum ?? folderId}'),
        headers: await _getAuthHeaders(),
        body: json.encode({'parentId': parentNum ?? newParentId}),
      );
      if (response.statusCode == 200) {
        await fetchLibrary();
      } else {
        _errorMessage =
            'Lỗi ${response.statusCode}: Không thể di chuyển thư mục.';
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFolder(String folderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final idNum = int.tryParse(folderId);
      final response = await http.delete(
        Uri.parse('${ApiConstants.folders}/${idNum ?? folderId}'),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        await fetchLibrary();
      } else {
        _errorMessage = 'Lỗi ${response.statusCode}: Không thể xóa thư mục.';
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final idNum = int.tryParse(playlistId);
    if (idNum == null) {
      _errorMessage = 'Playlist ID không hợp lệ.';
      notifyListeners();
      return;
    }

    final success = await ApiService.renamePlaylist(idNum, newName);
    if (success) {
      // Find and update the local playlist name
      for (var folder in _folders) {
        for (var playlist in folder.playlists) {
          if (playlist.id == playlistId) {
            playlist.name = newName;
            notifyListeners();
            return;
          }
        }
      }
    } else {
      _errorMessage = 'Không thể đổi tên playlist. Vui lòng thử lại.';
      notifyListeners();
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final idNum = int.tryParse(playlistId);
    if (idNum == null) {
      _errorMessage = 'Playlist ID không hợp lệ.';
      notifyListeners();
      return;
    }

    final success = await ApiService.deletePlaylist(idNum);
    if (success) {
      // Remove from local list to update UI instantly
      for (var folder in _folders) {
        folder.playlists.removeWhere((p) => p.id == playlistId);
      }
      notifyListeners();
    } else {
      _errorMessage = 'Không thể xóa playlist. Vui lòng thử lại.';
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Song song) async {
    try {
      final isFavorite = _favoritesPlaylist.songs.any((s) => s.id == song.id);
      bool ok = false;
      if (isFavorite) {
        ok = await ApiService.removeFavorite(song.id);
        if (ok) {
          _favoritesPlaylist.songs.removeWhere((s) => s.id == song.id);
        }
      } else {
        ok = await ApiService.addFavorite(song.id);
        if (ok) {
          _favoritesPlaylist.songs.add(song);
        }
      }
      if (!ok) {
        _errorMessage = 'Không thể cập nhật yêu thích. Vui lòng thử lại.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi khi cập nhật yêu thích: $e';
    }
    notifyListeners();
  }

  // Tìm folder ID của playlist
  Folder? findFolderById(String id) {
    Folder? find(List<Folder> folderList) {
      for (var folder in folderList) {
        if (folder.id == id) return folder;
        final found = find(folder.subFolders);
        if (found != null) return found;
      }
      return null;
    }

    return find(_folders);
  }

  String? findParentFolderId(String playlistId) {
    for (var folder in _folders) {
      for (var playlist in folder.playlists) {
        if (playlist.id == playlistId) {
          return folder.id;
        }
      }
    }
    return null; // Playlist không nằm trong folder nào (root playlist)
  }

  // Di chuyển playlist sang folder khác
  Future<void> movePlaylist(String playlistId, String? newFolderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final idNum = int.tryParse(playlistId);
      if (idNum == null) {
        _errorMessage = 'Playlist ID không hợp lệ.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final folderNum = newFolderId != null ? int.tryParse(newFolderId) : null;
      final response = await http.put(
        Uri.parse('${ApiConstants.playlists}/$idNum'),
        headers: await _getAuthHeaders(),
        body: json.encode({'folderId': folderNum ?? newFolderId}),
      );

      if (response.statusCode == 200) {
        await fetchLibrary();
      } else {
        _errorMessage =
            'Lỗi ${response.statusCode}: Không thể di chuyển playlist.';
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật ảnh cho playlist
  Future<void> updatePlaylistImage(String playlistId, String imagePath) async {
    _isLoading = true;
    notifyListeners();
    try {
      final idNum = int.tryParse(playlistId);
      if (idNum == null) {
        _errorMessage = 'Playlist ID không hợp lệ.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Tạo multipart request để gửi file ảnh
      final uri = Uri.parse('${ApiConstants.playlists}/$idNum/image');
      final request = http.MultipartRequest('PUT', uri);

      // Chỉ thêm header Authorization cho multipart (không set Content-Type)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final response = await request.send();
      if (response.statusCode == 200) {
        await fetchLibrary();
      } else {
        _errorMessage =
            'Lỗi ${response.statusCode}: Không thể cập nhật ảnh playlist.';
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
