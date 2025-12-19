import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  // ==================== AUTH METHODS ====================

  // Đăng ký tài khoản
  static Future<Map<String, dynamic>> signUp(
    String username,
    String email,
    String password,
  ) async {
    final url = Uri.parse("${ApiConstants.auth}/register");
    try {
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final contentType = res.headers['content-type'] ?? '';
      Map<String, dynamic> data;
      if (contentType.contains('application/json')) {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        data = {'message': res.body, 'statusCode': res.statusCode};
      }
      return data;
    } catch (e) {
      return {'message': e.toString()};
    }
  }

  // Đăng nhập
  static Future<Map<String, dynamic>> signIn(
    String email,
    String password,
  ) async {
    final url = Uri.parse("${ApiConstants.auth}/login");
    try {
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));

      final contentType = res.headers['content-type'] ?? '';
      Map<String, dynamic> data;
      if (contentType.contains('application/json')) {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        data = {
          'message': res.body.isNotEmpty ? res.body : res.reasonPhrase,
          'statusCode': res.statusCode,
        };
      }

      if (res.statusCode == 200) {
        // Verify token is present on success
        if (data['token'] == null || (data['token'] as String).isEmpty) {
          return {'message': 'Server returned empty token', 'statusCode': 200};
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        return data;
      }

      return {
        'message':
            data['message'] ??
            'HTTP ${res.statusCode}: ${res.reasonPhrase ?? 'Unknown'}',
        'statusCode': res.statusCode,
      };
    } catch (e) {
      return {'message': e.toString()};
    }
  }

  // Google Sign-In: gửi idToken hoặc accessToken nhận từ Google lên backend để đổi JWT
  static Future<Map<String, dynamic>> signInWithGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    final url = Uri.parse("${ApiConstants.auth}/google");
    try {
      final body = <String, dynamic>{};
      if (idToken != null && idToken.isNotEmpty) {
        body['idToken'] = idToken;
      }
      if (accessToken != null && accessToken.isNotEmpty) {
        body['accessToken'] = accessToken;
      }

      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final contentType = res.headers['content-type'] ?? '';
      Map<String, dynamic> data;
      if (contentType.contains('application/json')) {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        data = {
          'message': res.body.isNotEmpty ? res.body : res.reasonPhrase,
          'statusCode': res.statusCode,
        };
      }

      if (res.statusCode == 200) {
        // Verify token is present on success
        if (data['token'] == null || (data['token'] as String).isEmpty) {
          return {'message': 'Server returned empty token', 'statusCode': 200};
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
      }
      return data;
    } catch (e) {
      return {'message': e.toString()};
    }
  }

  // ==================== SONG METHODS ====================

  // Lấy danh sách bài hát (có phân trang). Trả về chỉ items để tương thích cũ.
  static Future<List<Map<String, dynamic>>> getSongs({
    int page = 1,
    int limit = 50,
  }) async {
    final url = Uri.parse("${ApiConstants.songs}?page=$page&limit=$limit");
    try {
      final token = await getToken();
      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final contentType = res.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          final decoded = jsonDecode(res.body);
          if (decoded is List) {
            // fallback nếu backend chưa hỗ trợ phân trang
            return decoded.map((e) => e as Map<String, dynamic>).toList();
          } else if (decoded is Map && decoded['items'] is List) {
            return (decoded['items'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      // ignore print in production; kept for quick diagnostics
      // print('Error fetching songs: $e');
      return [];
    }
  }

  // Trả về cả metadata phân trang
  static Future<Map<String, dynamic>> getSongsPage({
    int page = 1,
    int limit = 50,
  }) async {
    final url = Uri.parse("${ApiConstants.songs}?page=$page&limit=$limit");
    try {
      final token = await getToken();
      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return {
            'items': decoded.map((e) => e as Map<String, dynamic>).toList(),
            'page': page,
            'limit': limit,
            'total': (decoded).length,
            'totalPages': 1,
            'hasNext': false,
            'hasPrev': page > 1,
          };
        } else if (decoded is Map) {
          return {
            'items':
                (decoded['items'] as List?)
                    ?.map((e) => e as Map<String, dynamic>)
                    .toList() ??
                <Map<String, dynamic>>[],
            'page': decoded['page'] ?? page,
            'limit': decoded['limit'] ?? limit,
            'total': decoded['total'] ?? 0,
            'totalPages': decoded['totalPages'] ?? 1,
            'hasNext': decoded['hasNext'] ?? false,
            'hasPrev': decoded['hasPrev'] ?? page > 1,
          };
        }
      }
      return {
        'items': <Map<String, dynamic>>[],
        'page': page,
        'limit': limit,
        'total': 0,
        'totalPages': 0,
        'hasNext': false,
        'hasPrev': page > 1,
      };
    } catch (e) {
      return {
        'items': <Map<String, dynamic>>[],
        'page': page,
        'limit': limit,
        'total': 0,
        'totalPages': 0,
        'hasNext': false,
        'hasPrev': page > 1,
        'error': e.toString(),
      };
    }
  }

  // ==================== COMMENT METHODS ====================

  // Thêm bình luận
  static Future<Map<String, dynamic>> addComment({
    required int? songId,
    required int? playlistId,
    required String content,
    int? parentId,
  }) async {
    final url = Uri.parse(ApiConstants.comments);
    try {
      final token = await getToken();
      if (token == null) {
        return {'message': 'No token found'};
      }

      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'song_id': songId,
              'playlist_id': playlistId,
              'content': content,
              'parent_id': parentId,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'message': 'Failed to add comment'};
    } catch (e) {
      return {'message': e.toString()};
    }
  }

  // Lấy bình luận theo bài hát hoặc playlist (có phân trang). Chỉ trả về items.
  static Future<List<Map<String, dynamic>>> getComments({
    int? songId,
    int? playlistId,
    int page = 1,
    int limit = 50,
  }) async {
    final base = ApiConstants.comments;

    List<Map<String, dynamic>> extractList(dynamic decoded) {
      if (decoded is List) {
        return decoded.map((item) => item as Map<String, dynamic>).toList();
      }
      if (decoded is Map) {
        final keys = ['items', 'data', 'comments'];
        for (final k in keys) {
          final v = decoded[k];
          if (v is List) {
            return v.map((e) => e as Map<String, dynamic>).toList();
          }
        }
      }
      return <Map<String, dynamic>>[];
    }

    Future<List<Map<String, dynamic>>> fetchLocal(Uri url) async {
      final token = await getToken();
      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return [];
      final decoded = jsonDecode(res.body);
      return extractList(decoded);
    }

    try {
      // Thử theo dạng camelCase trước (songId/playlistId)
      final targetCamel =
          songId != null ? 'songId=$songId' : 'playlistId=$playlistId';
      final urlCamel = Uri.parse("$base?$targetCamel&page=$page&limit=$limit");
      if (kDebugMode) debugPrint('[GET] $urlCamel');
      var items = await fetchLocal(urlCamel);
      if (kDebugMode) debugPrint('→ ${items.length} comments (camelCase)');

      // Nếu rỗng, fallback sang snake_case (song_id/playlist_id) cho các backend cũ
      if (items.isEmpty) {
        final targetSnake =
            songId != null ? 'song_id=$songId' : 'playlist_id=$playlistId';
        final urlSnake = Uri.parse(
          "$base?$targetSnake&page=$page&limit=$limit",
        );
        if (kDebugMode) debugPrint('[GET] $urlSnake');
        items = await fetchLocal(urlSnake);
        if (kDebugMode) debugPrint('→ ${items.length} comments (snake_case)');
      }
      return items;
    } catch (e) {
      return [];
    }
  }

  // Like bình luận
  static Future<Map<String, dynamic>> likeComment(int commentId) async {
    final url = Uri.parse("${ApiConstants.comments}/$commentId/like");
    try {
      final token = await getToken();
      if (token == null) {
        return {'message': 'No token found'};
      }

      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'message': 'Failed to like comment'};
    } catch (e) {
      return {'message': e.toString()};
    }
  }

  // ==================== REPORT METHODS ====================

  // Báo cáo bình luận
  static Future<Map<String, dynamic>> reportComment({
    required int commentId,
    required String message,
  }) async {
    final url = Uri.parse("${ApiConstants.reports}/$commentId");
    try {
      final token = await getToken();
      if (token == null) {
        return {'message': 'No token found'};
      }

      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'message': 'Failed to report comment'};
    } catch (e) {
      return {'message': e.toString()};
    }
  }

  // ==================== TOKEN METHODS ====================

  // Lấy token hiện tại
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // ==================== FAVORITES METHODS ====================

  // Get current user's favorite song IDs
  static Future<List<int>> getFavoritesIds() async {
    final url = Uri.parse(ApiConstants.favorites);
    try {
      final token = await getToken();
      if (token == null) return [];
      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Add a song to favorites
  static Future<bool> addFavorite(int songId) async {
    final url = Uri.parse(ApiConstants.favorites);
    try {
      final token = await getToken();
      if (token == null) return false;
      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'songId': songId}),
          )
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Remove a song from favorites
  static Future<bool> removeFavorite(int songId) async {
    final url = Uri.parse('${ApiConstants.favorites}/$songId');
    try {
      final token = await getToken();
      if (token == null) return false;
      final res = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get full song records for a list of IDs
  static Future<List<Map<String, dynamic>>> getSongsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final idsStr = ids.join(',');
    final url = Uri.parse('${ApiConstants.songs}/by-ids?ids=$idsStr');
    try {
      final token = await getToken();
      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get favorite songs (full records) for current user
  static Future<List<Map<String, dynamic>>> getFavoriteSongs() async {
    final url = Uri.parse('${ApiConstants.favorites}/songs');
    try {
      final token = await getToken();
      if (token == null) return [];
      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==================== PLAYLIST METHODS ====================

  // Rename a playlist
  static Future<bool> renamePlaylist(int playlistId, String newName) async {
    final url = Uri.parse('${ApiConstants.playlists}/$playlistId');
    try {
      final token = await getToken();
      if (token == null) return false;
      final res = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'name': newName}),
          )
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Delete a playlist
  static Future<bool> deletePlaylist(int playlistId) async {
    final url = Uri.parse('${ApiConstants.playlists}/$playlistId');
    try {
      final token = await getToken();
      if (token == null) return false;
      final res = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get all playlists (public)
  static Future<List<Map<String, dynamic>>> getPlaylists() async {
    final url = Uri.parse(ApiConstants.playlists);
    try {
      final res = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserPlaylists() async {
    final url = Uri.parse("${ApiConstants.playlists}/me");
    try {
      final token = await getToken();
      if (token == null) return [];

      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Add a song to a playlist
  static Future<bool> addSongToPlaylist(int playlistId, int songId) async {
    final url = Uri.parse(
      '${ApiConstants.playlists}/$playlistId/songs/$songId',
    );
    try {
      final token = await getToken();
      if (token == null) return false;
      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Đăng xuất
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // ==================== PASSWORD CHANGE ====================

  static Future<Map<String, dynamic>> requestPasswordChange() async {
    final url = Uri.parse("${ApiConstants.auth}/password/request-change");
    try {
      final token = await getToken();
      if (token == null) return {'message': 'Not authenticated'};

      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      return {'statusCode': res.statusCode, 'body': jsonDecode(res.body)};
    } catch (e) {
      return {'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String verificationCode,
  }) async {
    final url = Uri.parse("${ApiConstants.auth}/password/change");
    try {
      final token = await getToken();
      if (token == null) return {'message': 'Not authenticated'};

      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'oldPassword': oldPassword,
              'newPassword': newPassword,
              'verificationCode': verificationCode,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return {'statusCode': res.statusCode, 'body': jsonDecode(res.body)};
    } catch (e) {
      return {'message': e.toString()};
    }
  }

  // ==================== PROFILE METHODS ====================

  /// Upload avatar image and return the URL
  static Future<String?> uploadAvatar(Uint8List imageBytes) async {
    final url = Uri.parse("${ApiConstants.upload}/avatar");
    try {
      final token = await getToken();
      if (token == null) return null;

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          imageBytes,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['avatarUrl'] ?? data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update user profile (including avatar URL)
  static Future<bool> updateProfile({String? avatarUrl, String? name}) async {
    final url = Uri.parse("${ApiConstants.auth}/profile");
    try {
      final token = await getToken();
      if (token == null) return false;

      final body = <String, dynamic>{};
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
      if (name != null) body['name'] = name;

      final res = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
