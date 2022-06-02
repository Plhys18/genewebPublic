import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis.dart';
import 'package:geneweb/analysis/distribution.dart';
import 'package:geneweb/genes/filter_definition.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/output/distributions_output.dart';
import 'package:geneweb/widgets/analysis_distribution.dart';
import 'package:geneweb/widgets/analysis_form.dart';
import 'package:geneweb/widgets/distribution_view.dart';
import 'package:geneweb/widgets/drill_down_view.dart';
import 'package:geneweb/widgets/filter_form.dart';
import 'package:geneweb/widgets/transcription_rate_table.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _model = GeneModel.of(context);

  final List<bool> _panels = [
    true,
    false,
    false,
    false,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gene web'),
      ),
      body: SingleChildScrollView(
        child: ExpansionPanelList(
          children: [
            ExpansionPanel(
                headerBuilder: (context, isOpen) => const _Header('Source data'),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _Source(
                        onLoad: () => setState(() {
                              _panels[1] = true;
                              _panels[2] = true;
                            })),
                  ),
                ),
                canTapOnHeader: true,
                isExpanded: _panels[0]),
            ExpansionPanel(
                headerBuilder: (context, isOpen) => const _Header('Filters'),
                body: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Align(alignment: Alignment.topLeft, child: _FilteredGenes()),
                ),
                canTapOnHeader: true,
                isExpanded: _panels[1]),
            ExpansionPanel(
                headerBuilder: (context, isOpen) => const _Header('Analysis'),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _Analysis(
                      onAdd: () => setState(() {
                        _panels[3] = true;
                      }),
                    ),
                  ),
                ),
                canTapOnHeader: true,
                isExpanded: _panels[2]),
            ExpansionPanel(
                headerBuilder: (context, isOpen) => const _Header('Results'),
                body: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Align(alignment: Alignment.topLeft, child: _Distribution()),
                ),
                canTapOnHeader: true,
                isExpanded: _panels[3]),
          ],
          expansionCallback: (index, isOpen) => setState(() => _panels[index] = !isOpen),
        ),
      ),
    );
  }
}

class _Source extends StatefulWidget {
  final Function() onLoad;
  const _Source({Key? key, required this.onLoad}) : super(key: key);

  @override
  State<_Source> createState() => _SourceState();
}

class _SourceState extends State<_Source> {
  late final _model = GeneModel.of(context);
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final list = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final filename = context.select<GeneModel, String?>((model) => model.filename);
    if (_isLoading) return const Center(child: Text('Import in progress…'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (list != null) Text('Loaded ${list.genes.length} genes'),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _handlePickFile, child: const Text('Load source data')),
      ],
    );
  }

  Future<void> _load() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        if (kIsWeb) {
          final data = String.fromCharCodes(result.files.single.bytes!);
          debugPrint('Loaded ${data.length} bytes');
          await _model.loadFromString(data, filename: result.files.single.name);
        } else {
          final path = result.files.single.path!;
          await _model.loadFromFile(path, filename: result.files.single.name);
        }
      } else {
        debugPrint('Cancelled');
      }
      debugPrint('Import done ${_model.sourceGenes?.genes.length} genes imported');
      widget.onLoad();
    } catch (error) {
      debugPrint('Error: $error');
    }
  }

  Future<void> _handlePickFile() async {
    setState(() => _isLoading = true);
    await _load();
    setState(() => _isLoading = false);
  }
}

class _FilteredGenes extends StatelessWidget {
  const _FilteredGenes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    if (sourceGenes == null) return const Center(child: Text('Load source data first'));
    final filteredGenes = context.select<GeneModel, GeneList?>((model) => model.filteredGenes);
    if (filteredGenes == null) {
      return const Center(child: Text('Loading...'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 400, child: FilterForm(onSubmit: (filter) => _handleFilter(context, filter))),
        const SizedBox(height: 16),
        const _Header('Transcription rates of filtered data'),
        TranscriptionRateTable(list: filteredGenes),
      ],
    );
  }

  void _handleFilter(BuildContext context, FilterDefinition filter) {
    GeneModel.of(context).setFilter(filter);
  }
}

class _Analysis extends StatelessWidget {
  final Function() onAdd;
  const _Analysis({Key? key, required this.onAdd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredGenes = context.select<GeneModel, GeneList?>((model) => model.filteredGenes);
    if (filteredGenes == null) return const Center(child: Text('Load source data first'));
    final analysis = context.select<GeneModel, Analysis?>((model) => model.analysis);
    final isAnalysisRunning = context.select<GeneModel, bool>((model) => model.isAnalysisRunning);
    if (isAnalysisRunning) {
      return const Center(child: Text('Loading...'));
    }
    if (analysis == null) {
      return SizedBox(width: 600, child: AnalysisForm(onSubmit: (motif) => _handleAnalyze(context, motif)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis of ${analysis.motif.name} of ${filteredGenes.genes.length} genes. Filter: ${analysis.filter.label}',
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
                  SizedBox(height: 300, child: AnalysisDistribution(analysis: analysis)),
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
        const SizedBox(height: 16),
        Text('R = AG, Y = CT, W = AT, S = GC, M = AC, K = GT, B = CGT, D = AGT, H = ACT, V = ACG, N = ACGT',
            style: Theme.of(context).textTheme.caption!),
      ],
    );
  }

  void _handleAnalyze(BuildContext context, motif) {
    final alignMarker = GeneModel.of(context).filteredGenes!.genes.first.markers.containsKey('tss') ? 'tss' : null;
    GeneModel.of(context).analyze(motif, min: -1000, max: 1000, interval: 10, alignMarker: alignMarker);
  }

  void _handleClear(BuildContext context) {
    GeneModel.of(context).clearAnalysis();
  }

  void _handleAdd(BuildContext context) {
    GeneModel.of(context).analysisToDistribution();
    GeneModel.of(context).clearAnalysis();
    onAdd();
  }
}

class _Distribution extends StatelessWidget {
  const _Distribution({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final distributions = context.select<GeneModel, List<Distribution>>((model) => model.distributions);
    if (distributions.isEmpty) {
      return const Center(child: Text('There are no distributions'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 300, child: DistributionView()),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          children: [
            ElevatedButton(onPressed: () => _handleExport(context), child: const Text('Save XLSX')),
          ],
        )
      ],
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    final output = DistributionsOutput(GeneModel.of(context).distributions);
    final data = output.toExcel();
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0), child: Text(title, style: Theme.of(context).textTheme.headline6));
  }
}
