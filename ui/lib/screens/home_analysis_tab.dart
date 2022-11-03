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
import 'package:truncate/truncate.dart';

class HomeAnalysisTab extends StatefulWidget {
  const HomeAnalysisTab({Key? key}) : super(key: key);

  @override
  State<HomeAnalysisTab> createState() => _HomeAnalysisTabState();
}

class _HomeAnalysisTabState extends State<HomeAnalysisTab> with AutomaticKeepAliveClientMixin {
  final Map<_ExpansionPanelItems, bool> _expansionPanelItems = {
    _ExpansionPanelItems.options: false,
    _ExpansionPanelItems.stage: false,
    _ExpansionPanelItems.motif: true,
  };

  @override
  void didUpdateWidget(covariant HomeAnalysisTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _expansionPanelItems[_ExpansionPanelItems.options] = false;
    _expansionPanelItems[_ExpansionPanelItems.stage] = false;
    _expansionPanelItems[_ExpansionPanelItems.motif] = true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final analysis = context.select<GeneModel, Analysis?>((model) => model.analysis);
    final isAnalysisRunning = context.select<GeneModel, bool>((model) => model.isAnalysisRunning);
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final motif = context.select<GeneModel, Motif?>((model) => model.motif);

    final canAnalyze = sourceGenes != null && motif != null;
    if (sourceGenes == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('You need to load the source data first.',
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPanel(context),
            const SizedBox(height: 16),
            analysis == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!canAnalyze) ...[
                        Text('To run an analysis, you must select a motif to analyze',
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton(
                          onPressed: canAnalyze && !isAnalysisRunning ? _handleAnalyze : null,
                          child: Text(isAnalysisRunning ? 'Analyzing…' : 'Analyze')),
                    ],
                  )
                : const _Analysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final distributionsCount = context.select<GeneModel, int>((model) => model.distributions.length);
    final analysisOptions = context.select<GeneModel, AnalysisOptions>((model) => model.analysisOptions);
    final filter = context.select<GeneModel, StageSelection?>((model) => model.filter);
    final motif = context.select<GeneModel, Motif?>((model) => model.motif);
    return ExpansionPanelList(
        expansionCallback: (panelIndex, isExpanded) {
          setState(() {
            _expansionPanelItems[_ExpansionPanelItems.values[panelIndex]] = !isExpanded;
          });
        },
        children: [
          ExpansionPanel(
            isExpanded: _expansionPanelItems[_ExpansionPanelItems.options]!,
            headerBuilder: (context, isOpened) => ListTile(
              title: const Text('Analysis Options'),
              subtitle: Text(
                  'Interval <${analysisOptions.min}; ${analysisOptions.max}> bp of ${(analysisOptions.alignMarker ?? 'sequence start').toUpperCase()}, chunk size ${analysisOptions.interval} bp'),
            ),
            canTapOnHeader: true,
            body: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnalysisOptionsForm(onChanged: _handleAnalysisOptionsChanged, enabled: distributionsCount == 0),
              ),
            ),
          ),
          ExpansionPanel(
            isExpanded: _expansionPanelItems[_ExpansionPanelItems.stage]!,
            headerBuilder: (context, isOpened) => ListTile(
              title: const Text('Filter by TPM'),
              subtitle: filter == null
                  ? const Text('All stages')
                  : Text(
                      '${filter.key} ${filter.strategy.name} ${filter.selection == FilterSelection.fixed ? filter.count : '${(filter.percentile! * 100).round()}th percentile'}'),
            ),
            canTapOnHeader: true,
            body: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _Stage(onChanged: _handleFilterChanged),
              ),
            ),
          ),
          ExpansionPanel(
            isExpanded: _expansionPanelItems[_ExpansionPanelItems.motif]!,
            headerBuilder: (context, isOpened) => ListTile(
              title: const Text('Motif'),
              subtitle: motif == null
                  ? const Text('Choose a motif to analyze')
                  : Text(truncate('${motif.name} (${motif.definitions.join(', ')})', 100)),
            ),
            canTapOnHeader: true,
            body: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _Motif(onChanged: _handleMotifChanged),
              ),
            ),
          ),
        ]);
  }

  void _handleFilterChanged(StageSelection? filter) {
    GeneModel.of(context).filter = filter;
    GeneModel.of(context).resetAnalysis();
  }

  void _handleMotifChanged(Motif motif) {
    GeneModel.of(context).motif = motif;
    GeneModel.of(context).resetAnalysis();
  }

  void _handleAnalyze() {
    final motif = GeneModel.of(context).motif;
    final filter = GeneModel.of(context).filter;
    if (motif == null) return;
    setState(() {
      _expansionPanelItems[_ExpansionPanelItems.options] = false;
      _expansionPanelItems[_ExpansionPanelItems.stage] = false;
      _expansionPanelItems[_ExpansionPanelItems.motif] = false;
    });
    final filteredGenes =
        filter == null ? GeneModel.of(context).sourceGenes : GeneModel.of(context).sourceGenes!.filter(filter);
    final name = '${filter ?? 'all'} - ${motif.name}';
    final color = _colorFor('${filter?.key}-${motif.name}');
    GeneModel.of(context).analyze(filteredGenes!, motif, name, color);
  }

  @override
  bool get wantKeepAlive => true;

  void _handleAnalysisOptionsChanged(AnalysisOptions options) {
    GeneModel.of(context).setOptions(options);
  }

  Color _colorFor(String text) {
    var hash = 0;
    for (var i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final finalHash = hash.abs() % (256 * 256 * 256);
    final red = ((finalHash & 0xFF0000) >> 16);
    final blue = ((finalHash & 0xFF00) >> 8);
    final green = ((finalHash & 0xFF));
    final color = Color.fromRGBO(red, green, blue, 1);
    return color;
  }
}

enum _ExpansionPanelItems { options, stage, motif }

class _Stage extends StatelessWidget {
  final Function(StageSelection? filter) onChanged;
  const _Stage({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    if (sourceGenes == null) return const Center(child: Text('Load source data first'));
    return FilterForm(onChanged: onChanged);
  }
}

class _Motif extends StatelessWidget {
  final Function(Motif motif) onChanged;
  const _Motif({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    if (sourceGenes == null) return const Center(child: Text('Load source data first'));
    return AnalysisForm(onChanged: onChanged);
  }
}

class _Analysis extends StatelessWidget {
  const _Analysis({Key? key}) : super(key: key);

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
    final canAdd = _canAdd(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis of ${analysis.name}',
          style: Theme.of(context).textTheme.headlineSmall,
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
                      ElevatedButton(
                          onPressed: canAdd ? () => _handleAdd(context) : null, child: const Text('Save to results')),
                      TextButton(onPressed: () => _handleClear(context), child: const Text('Clear')),
                    ],
                  ),
                  if (!canAdd) const Text('This analysis is already among the results'),
                ],
              ),
            ),
            const SizedBox(width: 400, height: 300, child: DrillDownView()),
          ],
        ),
      ],
    );
  }

  bool _canAdd(BuildContext context) {
    final model = GeneModel.of(context);
    final distribution = model.analysis!.distribution!;
    return (GeneModel.of(context).distributions.where((d) => d.name == distribution.name).isEmpty);
  }

  void _handleClear(BuildContext context) {
    GeneModel.of(context).clearAnalysis();
  }

  void _handleAdd(BuildContext context) {
    GeneModel.of(context).analysisToDistribution();
    GeneModel.of(context).clearAnalysis();
  }
}
