import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../analysis/Analysis_history_entry.dart';
import '../analysis/analysis_series.dart';
import '../analysis/organism.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl = "https://golembackend.duckdns.org:8000/api/";

  String? _jwtToken;
  String? _refreshToken;

  /// Load JWT tokens from storage
  Future<void> _loadJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString("jwt_access");
    _refreshToken = prefs.getString("jwt_refresh");
  }

  /// Save JWT tokens to storage
  Future<void> _saveJwtToken(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("jwt_access", accessToken);
    await prefs.setString("jwt_refresh", refreshToken);
    _jwtToken = accessToken;
    _refreshToken = refreshToken;

  }

  /// Remove JWT tokens (logout)
  Future<void> _clearJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt_access");
    await prefs.remove("jwt_refresh");
    _jwtToken = null;
    _refreshToken = null;
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
        return true;
      } else {
        await _clearJwtToken();
        return false;
      }
    } catch (error) {
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

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
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

    //print("🌐 [POST REQUEST] ${_fixUrl(endpoint)}");
    //print("🔹 Body: $body");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      //print("⚠️ [401 UNAUTHORIZED] Trying to refresh token...");
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
    //print("🌍 [SET ORGANISM] Changing active organism to: $organismName");
    return await postRequest("analysis/set_active_organism", {"organism": organismName});
  }

  /// Get the active organism
  Future<Map<String, dynamic>> getActiveOrganism() async {
    //print("📌 [GET ACTIVE ORGANISM] Fetching current organism...");
    return await getRequest("analysis/get_active_organism");
  }
  /// Get the active organism
  Future<Map<String, dynamic>> getActiveOrganismSourceGenesInformations() async {
    //print("📌 [GET ACTIVE ORGANISM SOURCE GENES] Fetching current organism...");
    return await getRequest("analysis/get_active_organism_source_gene_informations");
  }


  Future<bool> login(String username, String password) async {
    final response = await postRequest("auth/login", {
      'username': username,
      'password': password,
    });

    if (response.containsKey("access")) {
      await _saveJwtToken(response["access"], response["refresh"]);
      return true;
    }
    return false;
  }

  /// Logout (clear stored tokens)
  Future<void> logout() async {
    //print("🚪 [LOGOUT] Clearing stored credentials...");
    await _clearJwtToken();
  }

  /// Fetch list of past analyse s (history)

  Future<List<AnalysisHistoryEntry>> fetchAnalyses() async {
    final response = await getRequest("analysis/history/");
    if (!response.containsKey("history")) {
      throw Exception("❌ API response missing 'history' key");
    }

    final List<dynamic> historyData = response["history"];
    return historyData.map((entry) => AnalysisHistoryEntry.fromJson(entry)).toList();
  }


  /// **Fetch Analysis Details**

  Future<AnalysisSeries> fetchAnalysisDetails(int analysisId) async {
    final data = await getRequest("analysis/history/$analysisId/");
    if (!data.containsKey("id") || !data.containsKey("name")) {
      throw Exception("❌ Unexpected API response format: Missing 'id' or 'name'");
    }

    return AnalysisSeries.fromJson(data);
  }



  /// Fetch the latest analysis ID from the user's analysis history
  Future<int?> fetchLatestAnalysisId() async {
    try {
      final data = await getRequest("analysis/history");

      if (data["history"].isEmpty) {
        //print("📌 [FETCH LATEST ANALYSIS] No past analyses found.");
        return null;
      }

      final latestEntry = data["history"].first;
      final latestId = latestEntry["id"];

      //print("✅ [LATEST ANALYSIS] ID: $latestId");
      return latestId;
    } catch (error) {
      //print("❌ [ERROR FETCHING LATEST ANALYSIS] $error");
      return null;
    }
  }

}
