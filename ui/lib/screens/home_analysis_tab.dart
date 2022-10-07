import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/filter_definition.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/widgets/analysis_view.dart';
import 'package:geneweb/widgets/analysis_form.dart';
import 'package:geneweb/widgets/analysis_options_form.dart';
import 'package:geneweb/widgets/drill_down_view.dart';
import 'package:geneweb/widgets/filter_form.dart';
import 'package:provider/provider.dart';

class HomeAnalysisTab extends StatefulWidget {
  const HomeAnalysisTab({Key? key}) : super(key: key);

  @override
  State<HomeAnalysisTab> createState() => _HomeAnalysisTabState();
}

class _HomeAnalysisTabState extends State<HomeAnalysisTab> with AutomaticKeepAliveClientMixin {
  FilterDefinition? _filter;
  Motif? _motif;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final analysis = context.select<GeneModel, Analysis?>((model) => model.analysis);
    final isAnalysisRunning = context.select<GeneModel, bool>((model) => model.isAnalysisRunning);
    final distributionsCount = context.select<GeneModel, int>((model) => model.distributions.length);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalysisOptionsForm(onChanged: _handleAnalysisOptionsChanged, enabled: distributionsCount == 0),
            const Divider(),
            _Filters(
              onFilterChanged: _handleFilterChanged,
              onMotifChanged: _handleMotifChanged,
            ),
            const SizedBox(height: 16),
            Text('R = AG, Y = CT, W = AT, S = GC, M = AC, K = GT, B = CGT, D = AGT, H = ACT, V = ACG, N = ACGT',
                style: Theme.of(context).textTheme.caption!),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            if (analysis == null)
              Wrap(children: [
                ElevatedButton(onPressed: isAnalysisRunning ? null : _handleAnalyze, child: const Text('Analyze')),
              ])
            else
              const _Analysis(),
          ],
        ),
      ),
    );
  }

  void _handleFilterChanged(FilterDefinition filter) {
    setState(() => _filter = filter);
    GeneModel.of(context).resetAnalysis();
  }

  void _handleMotifChanged(Motif motif) {
    setState(() => _motif = motif);
    GeneModel.of(context).resetAnalysis();
  }

  void _handleAnalyze() {
    if (_motif == null) return;
    final filteredGenes =
        _filter == null ? GeneModel.of(context).sourceGenes : GeneModel.of(context).sourceGenes!.filter(_filter!);
    GeneModel.of(context).analyze(filteredGenes!, _motif!, '${_filter ?? 'all'} - ${_motif!.name}');
  }

  @override
  bool get wantKeepAlive => true;

  void _handleAnalysisOptionsChanged(AnalysisOptions options) {
    GeneModel.of(context).setOptions(options);
  }
}

class _Filters extends StatelessWidget {
  final Function(FilterDefinition filter) onFilterChanged;
  final Function(Motif motif) onMotifChanged;
  const _Filters({Key? key, required this.onFilterChanged, required this.onMotifChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    if (sourceGenes == null) return const Center(child: Text('Load source data first'));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: FilterForm(onChanged: onFilterChanged)),
        const VerticalDivider(),
        Expanded(child: AnalysisForm(onChanged: onMotifChanged)),
      ],
    );
  }
}

class _Analysis extends StatelessWidget {
  final Function()? onAdd;
  const _Analysis({Key? key, this.onAdd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final analysis = context.select<GeneModel, Analysis?>((model) => model.analysis);
    final isAnalysisRunning = context.select<GeneModel, bool>((model) => model.isAnalysisRunning);
    if (isAnalysisRunning) {
      return const Center(child: Text('Loading...'));
    }
    if (analysis == null) {
      return const Text('Analysis not available');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis of ${analysis.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 300, child: AnalysisView(analysis: analysis)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      ElevatedButton(onPressed: () => _handleAdd(context), child: const Text('Add to results')),
                      ElevatedButton(onPressed: () => _handleClear(context), child: const Text('Clear')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 400, height: 300, child: DrillDownView()),
          ],
        ),
      ],
    );
  }

  void _handleClear(BuildContext context) {
    GeneModel.of(context).clearAnalysis();
  }

  void _handleAdd(BuildContext context) {
    GeneModel.of(context).analysisToDistribution();
    GeneModel.of(context).clearAnalysis();
    onAdd?.call();
  }
}
