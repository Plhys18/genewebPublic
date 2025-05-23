import 'package:flutter/material.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/widgets/analysis_results_panel.dart';
import 'package:provider/provider.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select<GeneModel, String?>((model) => model.name) ?? 'Unknown';
    final motifs = context.select<GeneModel, List<String>>((model) => model.getSelectedMotifsNames);
    final stages = context.select<GeneModel, List<String>>(
            (model) => model.getStageSelectionClass.selectedStages);
    final stageName = stages.length == 1 ? stages.first : '${stages.length} stages';
    final motifName = motifs.length == 1 ? motifs.first : '${motifs.length} motifs';

    return Scaffold(
      appBar: AppBar(
          title: Wrap(
            spacing: 8,
            children: [
              Text(name, style: const TextStyle(fontStyle: FontStyle.italic)),
              Text('($motifName, $stageName)'),
            ],
          )),
      body: const AnalysisResultsPanel(),
    );
  }
}