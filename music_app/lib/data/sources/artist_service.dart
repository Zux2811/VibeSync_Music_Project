import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../models/artist_model.dart';
import '../models/player_state_model.dart';

class ArtistService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all artists
  static Future<List<Artist>> getArtists({int page = 1, int limit = 20}) async {
    final url = Uri.parse('${ApiConstants.artists}?page=$page&limit=$limit');
    try {
      final token = await _getToken();
      final res = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['items'] as List? ?? [])
            .map((e) => Artist.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching artists: $e');
      return [];
    }
  }

  /// Get artist by ID
  static Future<Artist?> getArtistById(int id) async {
    final url = Uri.parse('${ApiConstants.artists}/$id');
    try {
      final token = await _getToken();
      final res = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return Artist.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching artist: $e');
      return null;
    }
  }

  /// Get artist's songs
  static Future<List<Song>> getArtistSongs(int artistId) async {
    final url = Uri.parse('${ApiConstants.artists}/$artistId/songs');
    try {
      final token = await _getToken();
      final res = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['items'] as List? ?? [])
            .map((e) => Song.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching artist songs: $e');
      return [];
    }
  }

  /// Get artist's albums
  static Future<List<Album>> getArtistAlbums(int artistId) async {
    final url = Uri.parse('${ApiConstants.artists}/$artistId/albums');
    try {
      final token = await _getToken();
      final res = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['items'] as List? ?? [])
            .map((e) => Album.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching artist albums: $e');
      return [];
    }
  }

  /// Follow/unfollow artist
  static Future<bool> toggleFollowArtist(int artistId) async {
    final url = Uri.parse('${ApiConstants.artists}/$artistId/follow');
    try {
      final token = await _getToken();
      if (token == null) return false;
      final res = await http
          .post(url, headers: _headers(token))
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      return false;
    }
  }

  /// Get my artist stats
  static Future<ArtistStats?> getMyStats() async {
    final url = Uri.parse('${ApiConstants.artists}/me/stats');
    try {
      final token = await _getToken();
      if (token == null) return null;
      final res = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return ArtistStats.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      return null;
    }
  }

  /// Get my songs (for artists)
  static Future<List<Song>> getMySongs() async {
    final url = Uri.parse(
      '${ApiConstants.artists}/me/songs?includeHidden=true',
    );
    try {
      final token = await _getToken();
      if (token == null) return [];
      final res = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['items'] as List? ?? [])
            .map((e) => Song.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching my songs: $e');
      return [];
    }
  }

  /// Get my albums (for artists)
  static Future<List<Album>> getMyAlbums() async {
    final url = Uri.parse(
      '${ApiConstants.artists}/me/albums?includeUnpublished=true',
    );
    try {
      final token = await _getToken();
      if (token == null) return [];
      final res = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data.map((e) => Album.fromJson(e)).toList();
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching my albums: $e');
      return [];
    }
  }

  /// Submit artist verification request
  static Future<bool> submitVerificationRequest(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('${ApiConstants.artistVerification}/request');
    try {
      final token = await _getToken();
      if (token == null) return false;
      final res = await http
          .post(url, headers: _headers(token), body: jsonEncode(data))
          .timeout(const Duration(seconds: 30));
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('Error submitting verification: $e');
      return false;
    }
  }

  /// Get my verification requests
  static Future<List<ArtistVerificationRequest>>
  getMyVerificationRequests() async {
    final url = Uri.parse('${ApiConstants.artistVerification}/my-requests');
    try {
      final token = await _getToken();
      if (token == null) return [];
      final res = await http
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((e) => ArtistVerificationRequest.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching verification requests: $e');
      return [];
    }
  }
}
