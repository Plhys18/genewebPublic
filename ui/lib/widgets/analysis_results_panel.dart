import 'package:collection/collection.dart';
import 'package:faabul_color_picker/faabul_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/Analysis_history_entry.dart';
import 'package:geneweb/widgets/result_series_list.dart';
import 'package:provider/provider.dart';
import '../analysis/analysis_series.dart';
import '../analysis/motif.dart';
import '../genes/gene_model.dart';
import '../genes/stage_selection.dart';
import '../output/distributions_export.dart';
import '../screens/analysis_list_screen.dart';
import '../utilities/api_service.dart';
import 'distribution_view.dart';


class AnalysisResultsPanel extends StatefulWidget {
  const AnalysisResultsPanel({super.key});

  @override
  State<AnalysisResultsPanel> createState() => _AnalysisResultsPanelState();
}

class _AnalysisResultsPanelState extends State<AnalysisResultsPanel> {
  late final _scaffoldMessenger = ScaffoldMessenger.of(context);
  late final _model = context.select<GeneModel, GeneModel>((model) => model);
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
  void _navigateToAnalysisHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnalysisListScreen(),
      ),
    ).then((_) {
      // Refresh when returning from analysis history
      setState(() {});
    });
  }
  bool _loading = true;
  String? _error;
  double? _analysisProgress;

  @override
  void initState() {
    super.initState();
    _loading = false;
  }

  // Future<void> _fetchAnalyses() async {
  //   print("Fetching analyses in AnalysisResultsPanel...");
  //   try {
  //
  //     List<dynamic> analysisList = await _model.fetchUserAnalysesHistory() as List;
  //     setState(() {
  //       _loading = false;
  //     });
  //     var AnalysisHistoryEntry = analysisList.lastOrNull;
  //     if (AnalysisHistoryEntry) {
  //       _selectedAnalysisName = AnalysisHistoryEntry.name;
  //       await _model.loadAnalysis(AnalysisHistoryEntry);
  //     }
  //   } catch (error) {
  //     setState(() {
  //       _error = "Error loading analyses: $error";
  //       _loading = false;
  //     });
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    final motifs = _model.getSelectedMotifsNames;
    final filter = _model.getStageSelectionClass;
    final analyses = _model.getAnalyses;
    final visibleAnalyses = _model.getAnalyses.where((a) => a.visible).toList();
    final expectedResults = _model.expectedSeriesCount;
    final analysis = _model.getAnalyses.firstWhereOrNull((a) => a.analysisName == _selectedAnalysisName);
    final canAnalyzeErrors = [
      if (motifs.isEmpty) 'no motifs selected',
      if (filter?.selectedStages.isEmpty == true) 'no stages selected',
      if (expectedResults > 60) 'too many results (max 60)',
    ];
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canAnalyzeErrors.isNotEmpty) ...[
            Text('Analysis cannot be run: ${canAnalyzeErrors.join(', ')}', style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _loading ? null : _handleAnalyze,
                    child: const Text('Run Analysis'),
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text('Analysis is running, please wait...', style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _navigateToAnalysisHistory,
                    icon: const Icon(Icons.history),
                    label: const Text('View History'),
                  ),
                  const SizedBox(width: 8),
                  if (analyses.isNotEmpty)
                    ElevatedButton(
                        onPressed: _handleResetAnalyses,
                        child: const Text('Close Analysis')
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (expectedResults > 50) ...[
            Text(
                'Warning: This analysis will produce $expectedResults series. Analysis may take a long time and consume a lot of system memory. Consider reducing the amount of motifs and/or stages.',
                style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 16),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (analysis != null)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Icon(Icons.check_box, color: colorScheme.outline),
                    Text(analysis.analysisName, style: textTheme.titleMedium),
                    if (_exportProgress != null)
                      _ExportIndicator(exportProgress: _exportProgress)
                    else
                      TextButton(
                          onPressed: () => _handleExportSingleSeries(analysis),
                          child: const Text('Export this series')),
                    TextButton(onPressed: () => _handleAnalysisSelected(null), child: const Text('Deselect')),
                  ],
                )
              else
                Wrap(
                  spacing: 8,
                  children: [
                    if (visibleAnalyses.isNotEmpty)
                      if (_exportProgress != null)
                        _ExportIndicator(exportProgress: _exportProgress)
                      else
                        TextButton(
                            onPressed: () => _handleExportAllSeries(context),
                            child: Text('Export ${visibleAnalyses.length} series')),
                  ],
                ),
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
    final analyses = context.select<GeneModel, List<AnalysisSeries>>((model) => model.getAnalyses);
    assert(analyses.isNotEmpty);
    final analysis = context.select<GeneModel, AnalysisSeries?>(
            (model) => model.getAnalyses.firstWhereOrNull((a) => a.analysisName == _selectedAnalysisName));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 400,
          child: Consumer<GeneModel>(
            builder: (context, model, child) {
              return ResultSeriesList(
                onSelected: _handleAnalysisSelected,
                onToggleVisibility: _handleSetVisibility,
                analyses: model.getAnalyses,
              );
            },
          ),
        ),

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
                const Divider(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildAnalysisRowSettings(analysis)),
                      // Expanded(child: DrillDownView(name: _selectedAnalysisName)),
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
      ),
    );
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
    try {
      setState(() {
        _loading = true;
      });

      if (_model.getAnalyses.isNotEmpty) {
        bool? userConfirmed = await _showConfirmationDialog();
        if (userConfirmed == false) {
          setState(() {
            _loading = false;
          });
          return;
        }
        _model.removeAnalyses();
      }

      final result = await _model.analyze();

      if (result) {
        _scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Analysis complete')));
      } else {
        _scaffoldMessenger.showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Analysis cancelled/failed')));
      }
    } catch (error) {
      _scaffoldMessenger.showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error running analysis: $error')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("You already have ongoing analyses. Do you want to remove them and run a new analysis?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);  // User cancelled
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);  // User confirmed
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleExportAllSeries(BuildContext context) async {
    setState(() => _exportProgress = 0);
    final output = DistributionsExport(_model.getAnalyses.where((a) => a.visible).map((e) => e.distribution!).toList());
    final stageName = _model.getSelectedStages.length == 1
        ? _model.getSelectedStages[0]
        : '${_model.getSelectedStages.length} stages';
    final motifName = _model.getSelectedMotifsNames.length == 1 ? _model.getSelectedMotifsNames[0] : '${_model.getSelectedMotifsNames.length} motifs';
    final filename = 'distributions_${_model.name}_${motifName}_$stageName.xlsx';
    final data = await output.toExcel(filename, (progress) => setState(() => _exportProgress = progress));
    if (data == null) return;
    debugPrint('Saving $filename (${data.length} bytes)');
    setState(() => _exportProgress = null);
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
    // _model.removeAnalyses();
  }

  void _handleAnalysisSelected(String? selected) {
    setState(() => _selectedAnalysisName = selected);
  }

  Widget _buildAnalysisRowSettings(AnalysisSeries analysis) {
    return ListView(
      children: [
        CheckboxListTile(
            title: const Text('Enabled'),
            value: analysis.visible,
            onChanged: (value) => _handleSetVisibility(analysis, value)),
        ListTile(
            title: const Text('Color'),
            trailing: FaabulColorSample(color: analysis.color),
            onTap: () => _handleSetColor(analysis)),
        ListTile(
            title: const Text('Stroke'),
            trailing: CupertinoSlidingSegmentedControl<int>(
              children: const {
                2: Text('Thin'),
                4: Text('Normal'),
                8: Text('Thick'),
              },
              onValueChanged: (value) => _handleSetStroke(analysis, value),
              groupValue: analysis.stroke,
            )),
      ],
    );
  }

  void _updateAnalysis(GeneModel model, AnalysisSeries analysis) {
    List<AnalysisSeries> newList = ([
      for (final a in model.getAnalyses)
        if (a.analysisName == analysis.analysisName) analysis else a
    ]);
    model.setAnalyses(newList);
  }

  Future<void> _handleSetColor(AnalysisSeries analysis) async {
    final color = await showColorPickerDialog(context: context, selected: analysis.color);
    _updateAnalysis(_model, analysis.copyWith(color: color));

  }

  void _handleSetStroke(AnalysisSeries analysis, int? value) {
    _updateAnalysis(_model, analysis.copyWith(stroke: value ?? 4));
  }

  void _handleSetVisibility(AnalysisSeries analysis, bool? value) {
    _updateAnalysis(_model, analysis.copyWith(visible: value ?? true));
  }

  Future<void> _handleExportSingleSeries(AnalysisSeries analysis) async {
    // setState(() => _exportProgress = 0);
    // final output = AnalysisSeriesExport(analysis);
    // final filename = sanitizeFilename('${analysis.name}.xlsx');
    // TODO uncomment this and class.... when figure out how and we ofc need to do it via the backend call into api
    // final data = await output.toExcel(filename, (progress) => setState(() => _exportProgress = progress));
    // if (data == null) return;
    // debugPrint('Saving $filename (${data.length} bytes)');
    // setState(() => _exportProgress = null);
  }
}

class _ExportIndicator extends StatelessWidget {
  const _ExportIndicator({
    required double? exportProgress,
  }) : _exportProgress = exportProgress;

  final double? _exportProgress;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircularProgressIndicator(value: _exportProgress!),
      label: const Text('Preparing export…'),
    );
  }
}
