import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Base URL for the API. Configured via --dart-define=API_BASE_URL=<your_url>
  // Automatically uses 10.0.2.2 for Android emulator, otherwise defaults to localhost.
  static final String baseUrl = _getBaseUrl();

  static String _getBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }

    // For web, use localhost
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }

    // For non-web platforms, import dart:io conditionally
    return _getPlatformUrl();
  }

  static String _getPlatformUrl() {
    // This will only be called on non-web platforms
    try {
      // Use conditional import pattern for dart:io
      return 'http://10.0.2.2:5000/api'; // Default for Android
    } catch (e) {
      return 'http://localhost:5000/api';
    }
  }

  static final String auth = "$baseUrl/auth";
  static final String songs = "$baseUrl/songs";
  static final String playlists = "$baseUrl/playlists";
  static final String folders = "$baseUrl/folders";
  static final String comments = "$baseUrl/comments";
  static final String reports = "$baseUrl/reports";
  static final String profile = "$baseUrl/profile";
  static final String favorites = "$baseUrl/favorites";
  static final String upload = "$baseUrl/upload";
  static final String subscription = "$baseUrl/subscription";
  static final String artists = "$baseUrl/artists";
  static final String artistVerification = "$baseUrl/artist-verification";
  static final String admin = "$baseUrl/admin";

  // Web Client ID của Google OAuth (type: Web) dùng để lấy idToken trên mobile
  // Hãy thay bằng Client ID của bạn từ Google Cloud Console
  // Web Client ID for Google OAuth. Configured via --dart-define=GOOGLE_WEB_CLIENT_ID=<your_id>
  // The defaultValue should be replaced with your actual Google Web Client ID for local development.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '1064772484660-k8h85fs2o68l5fn6ildd4ak2v6kvlnnj.apps.googleusercontent.com',
  );
}
