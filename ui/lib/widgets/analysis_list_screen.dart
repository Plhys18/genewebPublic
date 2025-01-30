import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../genes/gene_model.dart';

class AnalysisListScreen extends StatelessWidget {
  const AnalysisListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analyses = context.watch<GeneModel>().analysesHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis List')),
      body: analyses.isEmpty
          ? const Center(child: Text('No analyses performed yet.'))
          : ListView.builder(
        itemCount: analyses.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(analyses[index] as String),
          );
        },
      ),
    );
  }
}
