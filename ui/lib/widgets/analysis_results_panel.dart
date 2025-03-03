import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../genes/gene_model.dart';
import '../utilities/api_service.dart';
import 'analysis_list_screen.dart';


class AnalysisResultsPanel extends StatefulWidget {
  const AnalysisResultsPanel({super.key});

  @override
  State<AnalysisResultsPanel> createState() => _AnalysisResultsPanelState();
}

class _AnalysisResultsPanelState extends State<AnalysisResultsPanel> {
  List<Map<String, dynamic>> _analyses = [];

  late final _scaffoldMessenger = ScaffoldMessenger.of(context);
  late final _model = GeneModel.of(context);
  bool _usePercentages = true;
  bool _groupByGenes = true;
  bool _customAxis = false;
  double? _verticalAxisMin;
  double? _verticalAxisMax;
  double? _horizontalAxisMin;
  double? _horizontalAxisMax;
  String? _selectedAnalysisName;

  double? _exportProgress;

  late final _verticalAxisMinController = TextEditingController()..addListener(_axisListener);
  late final _verticalAxisMaxController = TextEditingController()..addListener(_axisListener);
  late final _horizontalAxisMinController = TextEditingController()..addListener(_axisListener);
  late final _horizontalAxisMaxController = TextEditingController()..addListener(_axisListener);

  @override
  void dispose() {
    _verticalAxisMinController.dispose();
    _verticalAxisMaxController.dispose();
    _horizontalAxisMinController.dispose();
    _horizontalAxisMaxController.dispose();
    super.dispose();
  }

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
              subtitle: Text("Created: ${analysis["created_at"]}"),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => _navigateToAnalysisListScreen(context),
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
  void _navigateToAnalysisListScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalysisListScreen()),
    );
  }

}