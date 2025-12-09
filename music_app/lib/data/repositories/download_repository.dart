import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_state_model.dart';

class DownloadRepository {
  // Legacy global key (pre user-scoped). Kept for backward compatibility when no user is logged in.
  static const _legacyDownloadsKey = 'downloaded_songs_v1';
  static const _folderName = 'downloads';

  /// Returns the current user id stored in SharedPreferences by AuthProvider.fetchUser().
  /// Returns null if no user is logged in (guest mode).
  static Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');
    return (userId != null && userId.isNotEmpty) ? userId : null;
  }

  /// Build a per-user key. Falls back to legacy key when userId is null (guest).
  static String _keyForUser(String? userId) {
    return userId == null
        ? _legacyDownloadsKey
        : '${_legacyDownloadsKey}:$userId';
  }

  /// Returns the app's downloads directory path (scoped per user when logged in)
  static Future<Directory> _getDownloadsDir() async {
    final userId = await _getCurrentUserId();
    final dir = await getApplicationDocumentsDirectory();
    final base = userId == null ? _folderName : '$_folderName/$userId';
    final downloads = Directory('${dir.path}/$base');
    if (!await downloads.exists()) {
      await downloads.create(recursive: true);
    }
    return downloads;
  }

  /// Download audio to local file and persist metadata
  static Future<bool> downloadSong(Song song) async {
    try {
      if (song.audioUrl.isEmpty) return false;
      final downloadsDir = await _getDownloadsDir();

      // Choose filename based on title-artist-id
      final safeTitle = song.title.replaceAll(RegExp(r'[^a-zA-Z0-9-_ ]'), '_');
      final safeArtist = song.artist.replaceAll(
        RegExp(r'[^a-zA-Z0-9-_ ]'),
        '_',
      );
      final fileName = '${safeTitle}_${safeArtist}_${song.id}.mp3';
      final file = File('${downloadsDir.path}/$fileName');

      // Skip if already downloaded
      if (await file.exists()) {
        // still persist to registry if missing
        await _persistDownloaded(song, file.path);
        return true;
      }

      final resp = await http.get(Uri.parse(song.audioUrl));
      if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
        return false;
      }
      await file.writeAsBytes(resp.bodyBytes);

      await _persistDownloaded(song, file.path);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _persistDownloaded(Song song, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getCurrentUserId();
    final key = _keyForUser(userId);
    final raw = prefs.getString(key);
    List<Map<String, dynamic>> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = json.decode(raw);
        if (data is List) {
          list = data.cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    }

    final idx = list.indexWhere((m) => (m['id'] ?? 0) == song.id);
    final map = {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'imageUrl': song.imageUrl,
      'duration': song.duration.inSeconds,
      'filePath': filePath,
    };
    if (idx >= 0) {
      list[idx] = map;
    } else {
      list.add(map);
    }
    final userId2 = await _getCurrentUserId();
    await prefs.setString(_keyForUser(userId2), json.encode(list));
  }

  /// Returns downloaded songs metadata converted to Song objects
  static Future<List<Song>> getDownloadedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getCurrentUserId();
    final raw = prefs.getString(_keyForUser(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = json.decode(raw);
      if (data is! List) return [];
      return data.map<Song>((m) {
        final path = (m['filePath'] ?? '').toString();
        final localUri = path.isNotEmpty ? 'file://$path' : '';
        return Song(
          id: m['id'] ?? 0,
          title: (m['title'] ?? 'Unknown').toString(),
          artist: (m['artist'] ?? 'Unknown Artist').toString(),
          audioUrl: localUri,
          imageUrl: m['imageUrl']?.toString(),
          album: m['album']?.toString(),
          duration: Duration(seconds: (m['duration'] ?? 0) as int),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Remove a downloaded song (metadata + file)

  /// Optionally adopt legacy (global) downloaded list into the current user's namespace.
  /// Use this once after login if you want existing downloads to appear under the user account.
  /// Note: This does not move files; it only re-keys the metadata.
  static Future<bool> adoptLegacyDownloadsForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getCurrentUserId();
    if (userId == null) return false; // Only adopt when a user is logged in

    final legacyRaw = prefs.getString(_legacyDownloadsKey);
    if (legacyRaw == null || legacyRaw.isEmpty) return false;

    // If user already has scoped list, do nothing to avoid duplicate records
    final scopedKey = _keyForUser(userId);
    final scopedRaw = prefs.getString(scopedKey);
    if (scopedRaw != null && scopedRaw.isNotEmpty) return false;

    await prefs.setString(scopedKey, legacyRaw);
    // Optionally clear legacy list to avoid showing in guest mode
    await prefs.remove(_legacyDownloadsKey);
    return true;
  }

  static Future<bool> removeDownloaded(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getCurrentUserId();
    final raw = prefs.getString(_keyForUser(userId));
    if (raw == null || raw.isEmpty) return false;
    try {
      final data = json.decode(raw);
      if (data is! List) return false;
      final list = data.cast<Map<String, dynamic>>();
      final idx = list.indexWhere((m) => (m['id'] ?? 0) == id);
      if (idx < 0) return false;
      final filePath = list[idx]['filePath']?.toString();
      if (filePath != null && filePath.isNotEmpty) {
        final f = File(filePath);
        if (await f.exists()) {
          await f.delete();
        }
      }
      list.removeAt(idx);
      final userId2 = await _getCurrentUserId();
      await prefs.setString(_keyForUser(userId2), json.encode(list));
      return true;
    } catch (_) {
      return false;
    }
  }
}
