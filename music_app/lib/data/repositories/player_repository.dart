// lib/data/repositories/player_repository.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../sources/api_service.dart';
import '../models/player_state_model.dart';
import '../../core/utils/logger.dart';
import 'download_repository.dart';

class PlayerRepository {
  static const _favoritesKey = 'favorite_song_ids';

  // Lấy danh sách bài hát
  Future<List<Song>> getSongs() async {
    try {
      final songsData = await ApiService.getSongs();
      return songsData.map((json) => Song.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load songs: $e');
    }
  }

  // Thêm bài hát vào yêu thích
  Future<void> addToFavorites(int songId) async {
    try {
      // Cập nhật local trước để UI phản hồi ngay
      final prefs = await SharedPreferences.getInstance();
      final currentFavorites = await getFavorites();
      if (!currentFavorites.contains(songId)) {
        currentFavorites.add(songId);
        await prefs.setStringList(
          _favoritesKey,
          currentFavorites.map((id) => id.toString()).toList(),
        );
      }
      // Sau đó gọi API
      await ApiService.addFavorite(songId);
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  // Xóa bài hát khỏi yêu thích
  Future<void> removeFromFavorites(int songId) async {
    try {
      // Cập nhật local trước
      final prefs = await SharedPreferences.getInstance();
      final currentFavorites = await getFavorites();
      if (currentFavorites.contains(songId)) {
        currentFavorites.remove(songId);
        await prefs.setStringList(
          _favoritesKey,
          currentFavorites.map((id) => id.toString()).toList(),
        );
      }
      // Sau đó gọi API
      await ApiService.removeFavorite(songId);
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  // Lấy danh sách yêu thích (danh sách ID bài hát)
  Future<List<int>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList(_favoritesKey) ?? [];
    return favoriteIds.map((id) => int.tryParse(id) ?? 0).toList();
  }

  // Thêm bài hát vào playlist
  Future<void> addToPlaylist(int playlistId, int songId) async {
    try {
      final ok = await ApiService.addSongToPlaylist(playlistId, songId);
      if (!ok) {
        throw Exception('Backend rejected add to playlist');
      }
    } catch (e) {
      throw Exception('Failed to add to playlist: $e');
    }
  }

  // Tải xuống bài hát
  Future<bool> downloadSong(Song song) async {
    try {
      // Use DownloadRepository to save song locally
      final dl = await DownloadRepository.downloadSong(song);
      if (!dl) throw Exception('Download failed');
      logger.i('Downloaded song: ${song.title}');
      return true;
    } catch (e) {
      throw Exception('Failed to download song: $e');
    }
  }

  // Lấy thông tin nghệ sĩ
  Future<Map<String, dynamic>> getArtistInfo(String artistName) async {
    try {
      // TODO: Implement API call when backend endpoint is ready
      return {
        'name': artistName,
        'bio': 'Artist bio coming soon',
        'image': null,
      };
    } catch (e) {
      throw Exception('Failed to load artist info: $e');
    }
  }
}
