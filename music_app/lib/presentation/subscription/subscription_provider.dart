import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:music_app/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionProvider extends ChangeNotifier {
  static const _tierKey = 'user_tier';
  String _tierCode = 'free'; // 'free' or 'pro'
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _tierFeatures;

  DateTime? _endAt; // Pro subscription end time (if any)
  String?
  _source; // Debug: where the data comes from (subscription/denormalized/fallback)

  String get tierCode => _tierCode;
  String get tier => _tierCode; // Backward compatibility
  bool get isPro => _tierCode == 'pro';
  bool get isFree => _tierCode == 'free';
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get tierFeatures => _tierFeatures;
  DateTime? get endAt => _endAt;
  String? get source => _source;

  /// Remaining duration until subscription end. Null if no endAt.
  Duration? get remainingDuration {
    if (_endAt == null) return null;
    final diff = _endAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  SubscriptionProvider() {
    _load();
  }

  /// Load tier from SharedPreferences and try to sync with backend if token exists
  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    _tierCode = sp.getString(_tierKey) ?? 'free';
    notifyListeners();

    // Try to fetch current subscription from backend if logged in
    final token = sp.getString('jwt_token');
    if (token != null && token.isNotEmpty) {
      // Fire and forget; this will update tierCode when response arrives
      // Avoid blocking app startup
      // ignore: unawaited_futures
      fetchMySubscription(token);
    }
  }

  /// Set tier locally and save to SharedPreferences
  Future<void> setTier(String tier) async {
    final sp = await SharedPreferences.getInstance();
    _tierCode = tier;
    await sp.setString(_tierKey, _tierCode);
    notifyListeners();
  }

  /// Fetch user's current subscription from backend
  Future<void> fetchMySubscription(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.subscription}/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _tierCode = data['tierCode'] ?? 'free';
        _tierFeatures = data['features'];
        _source = data['source']?.toString();
        final endAtStr = data['endAt'];
        _endAt =
            endAtStr != null && endAtStr.toString().isNotEmpty
                ? DateTime.tryParse(endAtStr.toString())
                : null;

        // Save to SharedPreferences
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_tierKey, _tierCode);

        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to fetch subscription';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Upgrade user to pro tier
  Future<bool> upgradeToPro(
    String token, {
    String provider = 'vnpay',
    String? providerRef,
    double? amount,
    int durationMonths = 1,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.subscription}/upgrade'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'provider': provider,
          'providerRef': providerRef,
          'amount': amount,
          'durationMonths': durationMonths,
        }),
      );

      if (response.statusCode == 201) {
        _tierCode = 'pro';
        try {
          final data = json.decode(response.body);
          final sub = data['subscription'];
          final endAtStr = sub?['endAt'];
          _endAt =
              endAtStr != null ? DateTime.tryParse(endAtStr.toString()) : null;
          _source = 'subscription';
        } catch (_) {}

        // Save to SharedPreferences
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_tierKey, 'pro');

        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        try {
          final errorData = json.decode(response.body);
          _errorMessage = errorData['message'] ?? 'Upgrade failed';
        } catch (_) {
          _errorMessage = 'HTTP ${response.statusCode}: Upgrade failed';
        }
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Fetch available tiers
  Future<List<Map<String, dynamic>>> fetchAvailableTiers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.subscription}/tiers'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error fetching tiers: $e');
    }
    return [];
  }
}
