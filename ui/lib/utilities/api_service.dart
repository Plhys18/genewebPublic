import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analysis/Analysis_history_entry.dart';
import '../analysis/analysis_series.dart';
import '../analysis/organism.dart';
import '../auth_provider.dart';
import '../genes/gene_model.dart';
import '../screens/lock_screen.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  static SharedPreferences? _prefs;
  static const String _baseUrl = "https://golembackend.duckdns.org";

  String? _jwtToken;
  String? _refreshToken;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _loadJwtToken() async {
    _jwtToken = _prefs?.getString("jwt_access");
    _refreshToken = _prefs?.getString("jwt_refresh");
  }


  Future<void> _saveJwtToken(String accessToken, String refreshToken) async {
    
    await _prefs?.setString("jwt_access", accessToken);
    await _prefs?.setString("jwt_refresh", refreshToken);
    _jwtToken = accessToken;
    _refreshToken = refreshToken;

  }

  Future<void> _clearJwtToken() async {
    if (_prefs != null) {
      await _prefs!.remove("jwt_access");
      await _prefs!.remove("jwt_refresh");
    }
    _jwtToken = null;
    _refreshToken = null;
  }

  Future<void> logoutAndNotify(BuildContext context) async {
    await _clearJwtToken();
    if (context.mounted) {
      final authProvider = context.read<UserAuthProvider>();
      final geneModel = context.read<GeneModel>();

      authProvider.logOut();
      geneModel.removeEverythingAssociatedWithCurrentSession();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LockScreen()),
            (route) => false,
      );
    }
  }


  String _fixUrl(String endpoint) {
    if (!endpoint.endsWith('/')) {
      endpoint += '/';
    }
    return "$_baseUrl/$endpoint";
  }


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

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
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

  Future<List<Organism>> getOrganisms() async {
    final data = await getRequest("analysis/organisms");
    if (data.containsKey("organisms")) {
      return List<Organism>.from(data["organisms"].map((e) => Organism.fromJson(e)));
    } else {
      throw Exception("❌ API response does not contain 'organisms' key.");
    }
  }


  Future<Map<String, dynamic>> getOrganismDetails(String organismName) async {
    return await postRequest("analysis/organism_details", {"organism": organismName});
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


  Future<void> logout() async {
    await _clearJwtToken();
  }


  Future<List<AnalysisHistoryEntry>> fetchAnalyses() async {
    final response = await getRequest("analysis/history/");
    if (!response.containsKey("history")) {
      throw Exception("❌ API response missing 'history' key");
    }

    final List<dynamic> historyData = response["history"];
    return historyData.map((entry) => AnalysisHistoryEntry.fromJson(entry)).toList();
  }


  Future<AnalysisSeries> fetchAnalysisDetails(int analysisId) async {
    final data = await getRequest("analysis/history/$analysisId/");
    if (!data.containsKey("id") || !data.containsKey("name")) {
      throw Exception("❌ Unexpected API response format: Missing 'id' or 'name'");
    }
    return AnalysisSeries.fromJson(data);
  }



  Future<int?> fetchLatestAnalysisId() async {
    try {
      final data = await getRequest("analysis/history");

      if (data["history"].isEmpty) {
        return null;
      }

      final latestEntry = data["history"].first;
      final latestId = latestEntry["id"];

      return latestId;
    } catch (error) {
      return null;
    }
  }

}
