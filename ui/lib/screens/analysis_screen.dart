import 'package:flutter/material.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/widgets/results_panel.dart';
import 'package:provider/provider.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = context.select<GeneModel, String?>((model) => model.name);
    final motif = context.select<GeneModel, Motif?>((model) => model.motif);
    return Scaffold(
      appBar: AppBar(title: Text('$name / ${motif?.name}')),
      body: const ResultsPanel(),
    );
  }
}
