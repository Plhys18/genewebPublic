import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../analysis/organism.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl = "http://localhost:8000/api";

  String? _jwtToken;
  String? _refreshToken;

  /// Load JWT tokens from storage
  Future<void> _loadJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString("jwt_access");
    _refreshToken = prefs.getString("jwt_refresh");

    print("🔹 [JWT LOADED] Access Token: $_jwtToken");
    print("🔹 [JWT LOADED] Refresh Token: $_refreshToken");
  }

  /// Save JWT tokens to storage
  Future<void> _saveJwtToken(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("jwt_access", accessToken);
    await prefs.setString("jwt_refresh", refreshToken);
    _jwtToken = accessToken;
    _refreshToken = refreshToken;

    print("✅ [JWT SAVED] Access & Refresh tokens updated.");
  }

  /// Remove JWT tokens (logout)
  Future<void> _clearJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt_access");
    await prefs.remove("jwt_refresh");
    _jwtToken = null;
    _refreshToken = null;

    print("🚪 [LOGOUT] JWT tokens cleared.");
  }

  /// Ensure URL formatting
  String _fixUrl(String endpoint) {
    if (!endpoint.endsWith('/')) {
      endpoint += '/';
    }
    return "$_baseUrl/$endpoint";
  }

  /// Handle token refresh when access token expires (401)
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) {
      print("❌ [TOKEN REFRESH FAILED] No refresh token available.");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(_fixUrl("auth/refresh")),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveJwtToken(data["access"], _refreshToken!);
        print("🔄 [TOKEN REFRESH SUCCESS] New access token obtained.");
        return true;
      } else {
        print("❌ [TOKEN REFRESH FAILED] Server rejected refresh request.");
        await _clearJwtToken(); // Force logout
        return false;
      }
    } catch (error) {
      print("🚨 [TOKEN REFRESH ERROR] $error");
      return false;
    }
  }

  /// General GET request with authentication
  Future<Map<String, dynamic>> getRequest(String endpoint) async {
    await _loadJwtToken();

    final response = await http.get(
      Uri.parse(_fixUrl(endpoint)),
      headers: {
        "Accept": "application/json",
        if (_jwtToken != null) "Authorization": "Bearer $_jwtToken",
      },
    );

    print("🌐 [GET REQUEST] ${_fixUrl(endpoint)}");
    print("🔹 Headers: ${response.request?.headers}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      print("⚠️ [401 UNAUTHORIZED] Trying to refresh token...");
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return getRequest(endpoint);
      } else {
        throw Exception("❌ Authentication failed. Please log in again.");
      }
    } else {
      throw Exception("❌ GET request failed: ${response.statusCode}");
    }
  }

  /// General POST request with authentication
  Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> body) async {
    await _loadJwtToken();

    final response = await http.post(
      Uri.parse(_fixUrl(endpoint)),
      headers: {
        "Content-Type": "application/json",
        if (_jwtToken != null) "Authorization": "Bearer $_jwtToken",
      },
      body: jsonEncode(body),
    );

    print("🌐 [POST REQUEST] ${_fixUrl(endpoint)}");
    print("🔹 Body: $body");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      print("⚠️ [401 UNAUTHORIZED] Trying to refresh token...");
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return postRequest(endpoint, body);
      } else {
        throw Exception("❌ Authentication failed. Please log in again.");
      }
    } else {
      throw Exception("❌ POST request failed: ${response.statusCode}");
    }
  }

  /// Fetch available organisms
  Future<List<Organism>> getOrganisms() async {
    final data = await getRequest("analysis/organisms");
    return List<Organism>.from(data["organisms"].map((e) => Organism.fromJson(e)));
  }

  /// Set the active organism
  Future<Map<String, dynamic>> setActiveOrganism(String organismName) async {
    print("🌍 [SET ORGANISM] Changing active organism to: $organismName");
    return await postRequest("analysis/set_active_organism", {"organism": organismName});
  }

  /// Get the active organism
  Future<Map<String, dynamic>> getActiveOrganism() async {
    print("📌 [GET ACTIVE ORGANISM] Fetching current organism...");
    return await getRequest("analysis/get_active_organism");
  }
  /// Get the active organism
  Future<Map<String, dynamic>> getActiveOrganismSourceGenesInformations() async {
    print("📌 [GET ACTIVE ORGANISM SOURCE GENES] Fetching current organism...");
    return await getRequest("analysis/get_active_organism_source_gene_informations");
  }


  /// User login and store tokens
  Future<bool> login(String username, String password) async {
    print("🔑 [LOGIN ATTEMPT] Username: $username");

    final response = await postRequest("auth/login", {
      'username': username,
      'password': password,
    });

    if (response.containsKey("access")) {
      await _saveJwtToken(response["access"], response["refresh"]);
      print("✅ [LOGIN SUCCESS] JWT tokens stored.");
      return true;
    } else {
      print("❌ [LOGIN FAILED] Incorrect credentials.");
      return false;
    }
  }

  /// Logout (clear stored tokens)
  Future<void> logout() async {
    print("🚪 [LOGOUT] Clearing stored credentials...");
    await _clearJwtToken();
  }

  Future<List<Map<String, dynamic>>> fetchAnalyses() async {
    var data = await getRequest("analysis/history");

    return List<Map<String, dynamic>>.from(data["history"].map((entry) {
      return {
        "id": entry["id"] as int,
        "name": entry["name"] as String,
        "created_at": entry["created_at"] as String,
      };
    }));
  }

  Future<Map<String, dynamic>> fetchAnalysisDetails(int analysisId) async {
    var data = await getRequest("analysis/history/$analysisId/");

    return {
      "id": data["id"],
      "name": data["name"],
      "created_at": data["created_at"],
      "color": data["color"] != null ? Color(data["color"]) : null,
      "distribution": data["distribution"],
    };
  }



  /// Helper method to parse the results field correctly
  List<Map<String, dynamic>> _parseResults(dynamic results) {
    if (results is List) {
      return List<Map<String, dynamic>>.from(results);
    } else if (results is Map) {
      return results.entries.map((e) {
        return {
          "key": e.key,
          "value": e.value,
        };
      }).toList();
    }
    return [];
  }
}
