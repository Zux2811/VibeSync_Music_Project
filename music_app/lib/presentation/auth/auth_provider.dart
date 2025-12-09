import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/core/constants/api_constants.dart';
import 'package:music_app/data/models/user_model.dart';
import 'package:music_app/data/sources/api_service.dart';
import 'package:music_app/data/repositories/download_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  User? _user;
  bool _isFetchingUser = false;
  String? _fetchUserError;
  bool _isUploadingAvatar = false;

  bool get isLoading => _isLoading; // For login
  String? get errorMessage => _errorMessage; // For login
  User? get user => _user;
  bool get isFetchingUser => _isFetchingUser;
  String? get fetchUserError => _fetchUserError;
  bool get isUploadingAvatar => _isUploadingAvatar;

  /// Registers a new user account with the provided credentials.
  ///
  /// This method delegates HTTP calls to ApiService.signUp and handles
  /// state management and SharedPreferences updates.
  /// New users are assigned 'free' tier by default.
  /// Avatar upload and user profile loading are handled separately in the
  /// onboarding flow (avatar selection → theme selection → avatar upload).
  ///
  /// Returns `true` if registration succeeds, `false` otherwise.
  /// On success, the JWT token is saved to SharedPreferences.
  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delegate HTTP call to ApiService
      final data = await ApiService.signUp(username, email, password);

      // Check for success (statusCode 201 or presence of token)
      final statusCode = data['statusCode'] as int?;
      final token = data['token'] as String?;

      if ((statusCode == 201 || statusCode == null) &&
          token != null &&
          token.isNotEmpty) {
        // Save token to SharedPreferences and mark onboarding as incomplete
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        // New users get 'free' tier by default
        await prefs.setString('user_tier', 'free');
        await prefs.setBool('onboarding_complete', false);
        // Mark device as authenticated for first-time registration
        await prefs.setBool('device_authenticated_before', true);

        // Avatar upload and user fetch will be handled after theme selection
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logs in a user with email and password.
  /// Delegates HTTP calls to ApiService.signIn and handles state management.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delegate HTTP call to ApiService
      final data = await ApiService.signIn(email, password);

      final statusCode = data['statusCode'] as int?;
      final token = data['token'] as String?;

      // Consider success if token is present (backend returns pure JSON without statusCode on success)
      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        // Save tier from response
        final tierCode = data['tierCode'] ?? 'free';
        await prefs.setString('user_tier', tierCode);
        // Mark device as authenticated and onboarding as complete for returning users
        await prefs.setBool('device_authenticated_before', true);
        await prefs.setBool('onboarding_complete', true);

        await fetchUser();
        // Migrate legacy global downloads list into user-scoped on first login
        await DownloadRepository.adoptLegacyDownloadsForCurrentUser();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            data['message'] ??
            (statusCode != null ? 'HTTP $statusCode' : 'Đăng nhập thất bại.');
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Logs in a user via Google Sign-In.
  /// Delegates HTTP calls to ApiService.signInWithGoogle and handles state management.
  Future<bool> loginWithGoogle(String idToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delegate HTTP call to ApiService
      final data = await ApiService.signInWithGoogle(idToken);

      final statusCode = data['statusCode'] as int?;
      final token = data['token'] as String?;

      // Consider success if token is present (backend returns pure JSON without statusCode on success)
      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        // Save tier from response
        final tierCode = data['tierCode'] ?? 'free';
        await prefs.setString('user_tier', tierCode);
        // Mark device as authenticated and onboarding as complete for Google users
        await prefs.setBool('device_authenticated_before', true);
        await prefs.setBool('onboarding_complete', true);

        await fetchUser();
        // Migrate legacy global downloads list into user-scoped on first login
        await DownloadRepository.adoptLegacyDownloadsForCurrentUser();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            data['message'] ??
            (statusCode != null
                ? 'HTTP $statusCode'
                : 'Đăng nhập Google thất bại.');
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('onboarding_complete');
    await prefs.remove('user_avatar');
    await prefs.remove('current_user_id');
    // Keep device_authenticated_before flag so returning users skip onboarding
    _user = null;
    notifyListeners();
  }

  Future<void> fetchUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      _fetchUserError = "Not authenticated. Please log in again.";
      notifyListeners();
      return;
    }

    _isFetchingUser = true;
    _fetchUserError = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.auth}/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _user = User.fromJson(json.decode(response.body));
        // Save tier and user id to SharedPreferences for quick access and namespacing
        if (_user != null) {
          await prefs.setString('user_tier', _user!.tierCode);
          await prefs.setString('current_user_id', _user!.id);
        }
        _fetchUserError = null;
      } else {
        _user = null;
        _fetchUserError =
            "Failed to load user data (Code: ${response.statusCode})";
      }
    } catch (e) {
      _user = null;
      _fetchUserError = "An error occurred: $e";
    }

    _isFetchingUser = false;
    notifyListeners();
  }

  Future<void> updateUserBio(String newBio) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.put(
      Uri.parse('${ApiConstants.auth}/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'bio': newBio}),
    );

    if (response.statusCode == 200) {
      await fetchUser();
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to update bio');
    }
  }

  /// Uploads an avatar image file and updates the user profile.
  ///
  /// Returns `true` if the upload succeeds and user data is fetched,
  /// `false` if the upload fails or token is missing.
  Future<bool> uploadAvatar(File imageFile) async {
    _isUploadingAvatar = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      _isUploadingAvatar = false;
      notifyListeners();
      return false;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.upload}/avatar'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('avatar', imageFile.path),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        await fetchUser();
        _isUploadingAvatar = false;
        notifyListeners();
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint('Failed to upload avatar: $respStr');
        _isUploadingAvatar = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      _isUploadingAvatar = false;
      notifyListeners();
      return false;
    }
  }
}
