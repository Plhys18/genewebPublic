import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../auth_provider.dart';
import '../analysis/analysis_series.dart';
import '../analysis/organism.dart';
import '../genes/gene_model.dart';
import '../screens/lock_screen.dart';
import '../analysis/Analysis_history_entry.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static SharedPreferences? _prefs;
  static const String _baseUrl = "http://0.0.0.0:8001/api";

  static const String _tokenKey = "jwt_access";
  static const String _refreshTokenKey = "jwt_refresh";
  static const String _tokenExpiryKey = "jwt_expiry";

  String? _jwtToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  bool get isAuthenticated => _jwtToken != null;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _instance._loadJwtToken();
  }

  Future<void> _loadJwtToken() async {
    _jwtToken = _prefs?.getString(_tokenKey);
    _refreshToken = _prefs?.getString(_refreshTokenKey);

    String? expiryStr = _prefs?.getString(_tokenExpiryKey);
    if (expiryStr != null) {
      _tokenExpiry = DateTime.tryParse(expiryStr);
    }

    if (_tokenExpiry != null && _tokenExpiry!.isBefore(DateTime.now())) {
      await _clearJwtToken();
    }
  }

  Future<void> _saveJwtToken(String accessToken, String refreshToken, {Duration expiresIn = const Duration(hours: 1)}) async {
    if (_prefs == null) return;

    await _prefs!.setString(_tokenKey, accessToken);
    await _prefs!.setString(_refreshTokenKey, refreshToken);

    final expiry = DateTime.now().add(expiresIn);
    await _prefs!.setString(_tokenExpiryKey, expiry.toIso8601String());

    _jwtToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = expiry;
  }

  Future<void> _clearJwtToken() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_refreshTokenKey);
    await _prefs!.remove(_tokenExpiryKey);
    await _prefs!.remove('user_data');
    await _prefs!.remove('last_login');
    _jwtToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }

  String _fixUrl(String endpoint) {
    if (!endpoint.endsWith('/')) {
      endpoint += '/';
    }
    return "$_baseUrl/$endpoint";
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_fixUrl("auth/login/")),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey("access") && data.containsKey("refresh")) {
          final expiresIn = Duration(seconds: data["expires_in"] ?? 3600);
          await _saveJwtToken(data["access"], data["refresh"], expiresIn: expiresIn);
          return true;
        }
      }
      return false;
    } catch (error) {
      debugPrint('Login error: $error');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (_jwtToken != null && _refreshToken != null) {
        await http.post(
          Uri.parse(_fixUrl("auth/logout/")),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_jwtToken",
          },
          body: jsonEncode({"refresh": _refreshToken}),
        );
      }
    } catch (error) {
      debugPrint('Logout error: $error');
    } finally {
      await _clearJwtToken();
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse(_fixUrl("auth/token/refresh/")),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final expiresIn = Duration(seconds: data["expires_in"] ?? 3600);
        await _saveJwtToken(data["access"], _refreshToken!, expiresIn: expiresIn);
        return true;
      } else {
        await _clearJwtToken();
        return false;
      }
    } catch (error) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getRequest(String endpoint) async {
    await _loadJwtToken();
    if (_jwtToken == null && _endpointRequiresAuth(endpoint)) {
      throw Exception("Authentication required");
    }
    try {
      if (_tokenExpiry != null &&
          _tokenExpiry!.difference(DateTime.now()).inMinutes < 5 &&
          _refreshToken != null) {
        await _refreshAccessToken();
      }

      final response = await http.get(
        Uri.parse(_fixUrl(endpoint)),
        headers: {
          "Accept": "application/json",
          if (_jwtToken != null) "Authorization": "Bearer $_jwtToken",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return getRequest(endpoint);
        } else {
          throw Exception("Authentication failed. Please log in again.");
        }
      } else {
        throw Exception("GET request failed: ${response.statusCode}");
      }
    } catch (error) {
      throw error;
    }
  }

  Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> body) async {
    await _loadJwtToken();

    try {
      if (_tokenExpiry != null &&
          _tokenExpiry!.difference(DateTime.now()).inMinutes < 5 &&
          _refreshToken != null) {
        await _refreshAccessToken();
      }

      final response = await http.post(
        Uri.parse(_fixUrl(endpoint)),
        headers: {
          "Content-Type": "application/json",
          if (_jwtToken != null) "Authorization": "Bearer $_jwtToken",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return postRequest(endpoint, body);
        } else {
          throw Exception("Authentication failed. Please log in again.");
        }
      } else {
        throw Exception("POST request failed: ${response.statusCode}");
      }
    } catch (error) {
      throw error;
    }
  }

  Future<List<Organism>> getOrganisms() async {
    final data = await getRequest("analysis/organisms");
    if (data.containsKey("organisms")) {
      return List<Organism>.from(data["organisms"].map((e) => Organism.fromJson(e)));
    } else {
      throw Exception("API response does not contain 'organisms' key.");
    }
  }

  Future<Map<String, dynamic>> getOrganismDetails(String organismName) async {
    return await postRequest("analysis/organism_details", {"organism": organismName});
  }

  Future<List<AnalysisHistoryEntry>> fetchAnalysesHistory() async {
    try {
      final response = await getRequest('analysis/history/');
      final analysesList = response['history'] as List? ?? [];

      return analysesList
          .map((json) => AnalysisHistoryEntry.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching analysis history: $e');
      rethrow;
    }
  }

  // Future<AnalysisSeries> fetchAnalysisDetails(int analysisId) async {
  //   final data = await getRequest("analysis/history/$analysisId/");
  //   if (!data.containsKey("id") || !data.containsKey("name")) {
  //     throw Exception("Unexpected API response format: Missing 'id' or 'name'");
  //   }
  //   return AnalysisSeries.fromJson(data);
  // }
  Future<Map<String, dynamic>> fetchAnalysisSettings(int analysisId) async {
    final response = await getRequest('analysis/settings/$analysisId');
    return response;
  }

  /// Fetches detailed results for a specific analysis by ID
  Future<AnalysisSeries> fetchAnalysisDetails(int analysisId) async {
    final response = await getRequest('analysis/details/$analysisId');

    if (response['filtered_results'] != null && response['filtered_results'] is List && (response['filtered_results'] as List).isNotEmpty) {
      final result = (response['filtered_results'] as List).first;
      return AnalysisSeries.fromJson(result);
    }

    throw Exception('No valid analysis data found');
  }

  /// Fetches the user profile information
  Future<Map<String, dynamic>> fetchUserProfile() async {
    return await getRequest('user/profile/');
  }

  // Future<int?> fetchLatestAnalysisId() async {
  //   try {
  //     final data = await getRequest("analysis/history");
  //
  //     if (data["history"].isEmpty) {
  //       return null;
  //     }
  //
  //     final latestEntry = data["history"].first;
  //     final latestId = latestEntry["id"];
  //
  //     return latestId;
  //   } catch (error) {
  //     return null;
  //   }
  // }
  bool _endpointRequiresAuth(String endpoint) {
    List<String> authEndpoints = [
      'user/profile',
      'preferences',
      'analysis/history',
      'analysis/details'
    ];

    return authEndpoints.any((e) => endpoint.startsWith(e));
  }
}