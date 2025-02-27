import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../genes/gene_model.dart';
import '../utilities/api_service.dart';


class AnalysisResultsPanel extends StatefulWidget {
  const AnalysisResultsPanel({super.key});

  @override
  State<AnalysisResultsPanel> createState() => _AnalysisResultsPanelState();
}

class _AnalysisResultsPanelState extends State<AnalysisResultsPanel> {
  List<Map<String, dynamic>> _analyses = [];
  bool _loading = true;
  String? _error;
  double? _analysisProgress;

  @override
  void initState() {
    super.initState();
    _fetchAnalyses();
  }

  Future<void> _fetchAnalyses() async {
    print("Fetching analyses in analysis_results_panel.dart");
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
    final model = Provider.of<GeneModel>(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _loading
              ? const CircularProgressIndicator()
              : _error != null
              ? Text(_error!, style: const TextStyle(color: Colors.red))
              : _analyses.isEmpty
              ? const Text('No analyses available')
              : Column(
            children: _analyses
                .map((analysis) => ListTile(
              title: Text(analysis["name"] ?? 'Unknown'),
              subtitle: Text(analysis["status"] ?? 'Unknown'),
            ))
                .toList(),
          ),
          const SizedBox(height: 16),
          _analysisProgress != null
              ? LinearProgressIndicator(value: _analysisProgress)
              : ElevatedButton(
            onPressed: model.analyze,
            child: const Text("Run Analysis"),
          ),
        ],
      ),
    );
  }
}