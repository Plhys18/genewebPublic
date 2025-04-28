import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_model.dart';
import '../analysis/Analysis_history_entry.dart';
import 'analysis_screen.dart';

class AnalysisListScreen extends StatefulWidget {
  const AnalysisListScreen({super.key});

  @override
  State<AnalysisListScreen> createState() => _AnalysisListScreenState();
}

class _AnalysisListScreenState extends State<AnalysisListScreen> {
  List<AnalysisHistoryEntry> _analysesHistory = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalysesHistory();
  }

  Future<void> _fetchAnalysesHistory() async {
    try {
      final geneModel = GeneModel.of(context);
      final analysisHistory = await geneModel.fetchUserAnalysesHistory();
      setState(() {
        _analysesHistory = analysisHistory;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = "Error loading analyses: $error";
        _loading = false;
      });
    }
  }

  Future<void> _loadAnalysisSettings(AnalysisHistoryEntry analysis) async {
    setState(() {
      _loading = true;
    });

    try {
      final geneModel = GeneModel.of(context);
      await geneModel.fetchOrganismDetails(analysis.fileName);
      await geneModel.loadAnalysisSettings(analysis.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded settings from "${analysis.name}"'))
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error loading analysis settings: $error')
          )
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _viewAnalysisResults(AnalysisHistoryEntry analysis) async {
    setState(() {
      _loading = true;
    });

    try {
      final geneModel = GeneModel.of(context);
      await geneModel.fetchOrganismDetails(analysis.fileName);
      final success = await geneModel.loadAnalysis(analysis);
      
      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AnalysisScreen(),
            settings: RouteSettings(arguments: analysis),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to load analysis results')
          )
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error loading analysis results: $error')
          )
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis History')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text(_error!))
          : _analysesHistory.isEmpty
            ? const Center(child: Text('No analyses performed yet.'))
            : ListView.builder(
                itemCount: _analysesHistory.length,
                itemBuilder: (context, index) {
                  final analysis = _analysesHistory[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(analysis.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Created: ${analysis.createdAt}"),
                          Text("Motifs: ${analysis.motifs.join(', ')}"),
                          Text("Stages: ${analysis.stages.join(', ')}"),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.settings_backup_restore),
                            tooltip: 'Load settings',
                            onPressed: () => _loadAnalysisSettings(analysis),
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View results',
                            onPressed: () => _viewAnalysisResults(analysis),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
