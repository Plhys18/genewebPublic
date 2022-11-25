import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/output/distributions_output.dart';
import 'package:geneweb/output/genes_output.dart';
import 'package:geneweb/widgets/distribution_view.dart';
import 'package:geneweb/widgets/drill_down_view.dart';
import 'package:geneweb/widgets/results_list.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:sanitize_filename/sanitize_filename.dart';

class ResultsSubtitle extends StatelessWidget {
  const ResultsSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final analysesCount = context.select<GeneModel, int>((model) => model.analyses.length);
    return Text('$analysesCount result${analysesCount == 1 ? '' : 's'}');
  }
}

class ResultsPanel extends StatefulWidget {
  const ResultsPanel({Key? key}) : super(key: key);

  @override
  State<ResultsPanel> createState() => _ResultsPanelState();
}

class _ResultsPanelState extends State<ResultsPanel> {
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

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final motifs = context.select<GeneModel, List<Motif>>((model) => model.motifs);
    final filter = context.select<GeneModel, StageSelection?>((model) => model.filter);
    final analyses = context.select<GeneModel, List<Analysis>>((model) => model.analyses);
    final visibleAnalyses =
        context.select<GeneModel, List<Analysis>>((model) => model.analyses.where((a) => a.visible).toList());
    final analysisProgress = context.select<GeneModel, double?>((model) => model.analysisProgress);
    final analysisCancelled = context.select<GeneModel, bool>((model) => model.analysisCancelled);
    final expectedResults = context.select<GeneModel, int>((model) => model.expectedResults);
    final analysis = context.select<GeneModel, Analysis?>(
        (model) => model.analyses.firstWhereOrNull((a) => a.name == _selectedAnalysisName));
    final canAnalyzeErrors = [
      if (sourceGenes == null) 'no source genes selected',
      if (motifs.isEmpty) 'no motifs selected',
      if (filter?.stages.isEmpty == true) 'no stages selected',
      if (expectedResults > 60) 'too many results (max 60)',
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canAnalyzeErrors.isNotEmpty) ...[
            Text('Analysis cannot be run: ${canAnalyzeErrors.join(', ')}',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
          ],
          if (analysisProgress != null) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: LinearProgressIndicator(value: analysisProgress)),
                IconButton(
                  onPressed: analysisCancelled ? null : _handleStopAnalysis,
                  tooltip: 'Stop analysis',
                  icon: Icon(Icons.cancel, color: Theme.of(context).colorScheme.primary),
                )
              ],
            ),
            const SizedBox(height: 32),
          ],
          if (analyses.isEmpty && analysisProgress == null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _handleAnalyze, child: const Text('Run Analysis')),
            const SizedBox(height: 16),
            if (expectedResults > 20) ...[
              Text(
                  'Warning: This analysis will produce $expectedResults series. Analysis may take a long time and consume a lot of system memory. Consider reducing the amount of motifs and/or stages.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
            ],
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    if (visibleAnalyses.isNotEmpty)
                      TextButton(
                          onPressed: analysisProgress == null ? () => _handleExportDistributions(context) : null,
                          child: Text('Export ${visibleAnalyses.length} series')),
                    if (analysis != null)
                      TextButton(
                          onPressed: () => _handleExportAnalysis(analysis), child: Text('Export "${analysis.name}"')),
                  ],
                ),
                TextButton(onPressed: _handleResetAnalyses, child: const Text('Close')),
              ],
            ),
          if (analyses.isNotEmpty) ...[
            const Divider(height: 16),
            Expanded(child: _buildResults(context)),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final analyses = context.select<GeneModel, List<Analysis>>((model) => model.analyses);
    assert(analyses.isNotEmpty);
    final analysis = context.select<GeneModel, Analysis?>(
        (model) => model.analyses.firstWhereOrNull((a) => a.name == _selectedAnalysisName));
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 400, child: ResultsList(onSelected: _handleAnalysisSelected)),
        const VerticalDivider(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGraphSettings(),
              _buildCustomGraphAxisSettings(),
              const SizedBox(height: 16),
              Expanded(flex: 2, child: _buildGraph()),
              const SizedBox(height: 16),
              if (analysis != null) ...[
                Text(analysis.name, style: textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildAnalysisRowSettings(analysis)),
                      Expanded(child: DrillDownView(name: _selectedAnalysisName)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  SizedBox _buildGraph() {
    return SizedBox(
        height: 400,
        child: DistributionView(
          focus: _selectedAnalysisName,
          usePercentages: _usePercentages,
          groupByGenes: _groupByGenes,
          verticalAxisMin: _customAxis ? _verticalAxisMin : null,
          verticalAxisMax: _customAxis ? _verticalAxisMax : null,
          horizontalAxisMin: _customAxis ? _horizontalAxisMin : null,
          horizontalAxisMax: _customAxis ? _horizontalAxisMax : null,
        ));
  }

  AnimatedSize _buildCustomGraphAxisSettings() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _customAxis
          ? Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Vertical axis min'),
                      controller: _verticalAxisMinController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Vertical axis max'),
                      controller: _verticalAxisMaxController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Horizontal axis min'),
                      controller: _horizontalAxisMinController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Horizontal axis max'),
                      controller: _horizontalAxisMaxController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Row _buildGraphSettings() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Show '),
        CupertinoSlidingSegmentedControl<bool>(
          children: const {
            false: Text('Motifs'),
            true: Text('Genes'),
          },
          onValueChanged: (value) => setState(() => _groupByGenes = value!),
          groupValue: _groupByGenes,
        ),
        const SizedBox(width: 16),
        const Text('as '),
        CupertinoSlidingSegmentedControl<bool>(
          children: const {
            false: Text('Counts'),
            true: Text('Percentages'),
          },
          onValueChanged: (value) => setState(() => _usePercentages = value!),
          groupValue: _usePercentages,
        ),
        const SizedBox(width: 16),
        const Text('Axis: '),
        CupertinoSlidingSegmentedControl<bool>(
          children: const {
            false: Text('Auto'),
            true: Text('Custom'),
          },
          onValueChanged: _setAxis,
          groupValue: _customAxis,
        ),
      ],
    );
  }

  void _handleAnalyze() async {
    final result = await _model.analyze();
    if (result) {
      _scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Analysis complete')));
    } else {
      _scaffoldMessenger.showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text('Analysis cancelled')));
    }
  }

  Future<void> _handleExportDistributions(BuildContext context) async {
    final output = DistributionsOutput(_model.analyses.where((a) => a.visible).map((e) => e.distribution!).toList());
    final stageName =
        _model.filter!.stages.length == 1 ? _model.filter!.stages.first : '${_model.filter!.stages.length} stages';
    final motifName = _model.motifs.length == 1 ? _model.motifs.first : '${_model.motifs.length} motifs';
    final fileName = 'distributions_${_model.name}_${motifName}_$stageName.xlsx';
    final data = output.toExcel(fileName);
  }

  void _setAxis(bool? value) {
    setState(() => _customAxis = value!);
  }

  void _axisListener() {
    setState(() {
      _verticalAxisMin =
          _verticalAxisMinController.text.isEmpty ? null : double.tryParse(_verticalAxisMinController.text);
      _verticalAxisMax =
          _verticalAxisMaxController.text.isEmpty ? null : double.tryParse(_verticalAxisMaxController.text);
      _horizontalAxisMin =
          _horizontalAxisMinController.text.isEmpty ? null : double.tryParse(_horizontalAxisMinController.text);
      _horizontalAxisMax =
          _horizontalAxisMaxController.text.isEmpty ? null : double.tryParse(_horizontalAxisMaxController.text);
    });
  }

  void _handleResetAnalyses() {
    Navigator.of(context).pop();
  }

  void _handleAnalysisSelected(String? selected) {
    setState(() => _selectedAnalysisName = selected);
  }

  Widget _buildAnalysisRowSettings(Analysis analysis) {
    return ListView(
      children: [
        CheckboxListTile(
            title: const Text('Enabled'),
            value: analysis.visible,
            onChanged: (value) => _handleSetVisibility(analysis, value)),
        ListTile(
            title: const Text('Color'),
            trailing: ColorIndicator(color: analysis.color),
            onTap: () => _handleSetColor(analysis)),
        ListTile(
            title: const Text('Stroke'),
            trailing: CupertinoSlidingSegmentedControl<int>(
              children: const {
                1: Text('Thin'),
                2: Text('Normal'),
                4: Text('Thick'),
              },
              onValueChanged: (value) => _handleSetStroke(analysis, value),
              groupValue: analysis.stroke,
            )),
      ],
    );
  }

  void _updateAnalysis(GeneModel model, Analysis analysis) {
    model.setAnalyses([
      for (final a in model.analyses)
        if (a.name == analysis.name) analysis else a
    ]);
  }

  Future<void> _handleSetColor(Analysis analysis) async {
    final model = GeneModel.of(context);
    final color = await showColorPickerDialog(context, analysis.color);
    _updateAnalysis(model, analysis.copyWith(color: color));
  }

  void _handleSetStroke(Analysis analysis, int? value) {
    final model = GeneModel.of(context);
    _updateAnalysis(model, analysis.copyWith(stroke: value ?? 2));
  }

  void _handleSetVisibility(Analysis analysis, bool? value) {
    final model = GeneModel.of(context);
    _updateAnalysis(model, analysis.copyWith(visible: value ?? true));
  }

  void _handleExportAnalysis(Analysis analysis) {
    final output = AnalysisOutput(analysis);
    final data = output.toExcel(sanitizeFilename('${analysis.name}.xlsx'));
  }

  void _handleStopAnalysis() {
    _model.cancelAnalysis();
  }
}
