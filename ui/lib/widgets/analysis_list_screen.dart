import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utilities/api_service.dart';

class AnalysisListScreen extends StatefulWidget {
  const AnalysisListScreen({super.key});

  @override
  State<AnalysisListScreen> createState() => _AnalysisListScreenState();
}

class _AnalysisListScreenState extends State<AnalysisListScreen> {
  List<Map<String, dynamic>> _analyses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalyses();
  }

  Future<void> _fetchAnalyses() async {
    print("Fetching analyses in analysis_list_screen.dart");
    try {
      final analyses = await ApiService().fetchAnalyses();
      setState(() {
        _analyses = analyses;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = "Error loading analyses: $error";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis List')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _analyses.isEmpty
          ? const Center(child: Text('No analyses performed yet.'))
          : ListView.builder(
        itemCount: _analyses.length,
        itemBuilder: (context, index) {
          final analysis = _analyses[index];
          return ListTile(
            title: Text(analysis["name"]),
            subtitle: Text("Created: ${analysis["created_at"]}"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => _navigateToDetails(analysis["id"]),
          );
        },
      ),
    );
  }
  void _navigateToDetails(int analysisId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisDetailsScreen(analysisId: analysisId),
      ),
    );
  }
}


class AnalysisDetailsScreen extends StatefulWidget {
  final int analysisId;

  const AnalysisDetailsScreen({super.key, required this.analysisId});

  @override
  State<AnalysisDetailsScreen> createState() => _AnalysisDetailsScreenState();
}

class _AnalysisDetailsScreenState extends State<AnalysisDetailsScreen> {
  Map<String, dynamic>? _analysisDetails;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalysisDetails();
  }

  Future<void> _fetchAnalysisDetails() async {
    try {
      final details = await ApiService().fetchAnalysisDetails(widget.analysisId);
      setState(() {
        _analysisDetails = details;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = "Error loading analysis: $error";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_analysisDetails?["name"] ?? "Analysis Details")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _buildAnalysisDetails(),
    );
  }

  Widget _buildAnalysisDetails() {
    final results = _analysisDetails?["results"];
    if (results == null || results.isEmpty) {
      return const Center(child: Text("No results available."));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text("Gene ID: ${result["key"]}"),
            subtitle: Text(result["value"].toString()),
          ),
        );
      },
    );
  }
}
