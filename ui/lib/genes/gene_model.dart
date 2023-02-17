import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/stages_data.dart';
import 'package:provider/provider.dart';
import 'package:universal_file/universal_file.dart';

class GeneModel extends ChangeNotifier {
  static const kAllStages = '__ALL__';

  bool get publicSite => _publicSite;
  bool _publicSite = true;
  bool get analysisCancelled => _analysisCancelled;
  bool _analysisCancelled = false;
  String? name;
  GeneList? sourceGenes;
  List<Analysis> analyses = [];
  double? analysisProgress;
  AnalysisOptions analysisOptions = AnalysisOptions();
  StageSelection? _stageSelection;
  StageSelection? get stageSelection => _stageSelection;
  List<Motif> _motifs = [];
  List<Motif> get motifs => _motifs;

  int get expectedResults => motifs.length * (stageSelection?.selectedStages.length ?? 0);

  GeneModel();

  static GeneModel of(BuildContext context) => Provider.of<GeneModel>(context, listen: false);

  void _reset({bool preserveSource = false}) {
    if (!preserveSource) name = null;
    if (!preserveSource) sourceGenes = null;
    analyses = [];
    analysisProgress = null;
    analysisOptions = AnalysisOptions();
    _stageSelection = null;
    _motifs = [];
  }

  void cancelAnalysis() {
    _analysisCancelled = true;
    notifyListeners();
  }

  void setPublicSite(bool value) {
    _publicSite = value;
    notifyListeners();
  }

  void setAnalyses(List<Analysis> analyses) {
    this.analyses = analyses;
    notifyListeners();
  }

  void setMotifs(List<Motif> newMotifs) {
    _motifs = newMotifs;
    notifyListeners();
  }

  void setStageSelection(StageSelection? selection) {
    _stageSelection = selection;
    notifyListeners();
  }

  void setOptions(AnalysisOptions options) {
    analyses = [];
    analysisProgress = null;
    analysisOptions = options;
    notifyListeners();
  }

  void removeAnalysis(String name) {
    analyses = analyses.where((a) => a.name != name).toList();
    notifyListeners();
  }

  void removeAnalyses() {
    analyses = [];
    notifyListeners();
  }

  void resetAnalysisOptions() {
    final keys = sourceGenes?.genes.first.markers.keys;
    if (keys != null && keys.isNotEmpty) {
      analysisOptions = AnalysisOptions(alignMarker: keys.first, min: -1000, max: 1000, interval: 30);
    } else {
      analysisOptions = AnalysisOptions();
    }
  }

  void resetFilter() {
    final stages = sourceGenes?.stageKeys ?? [];
    _stageSelection = StageSelection(
      selectedStages: [kAllStages, ...stages],
      strategy: sourceGenes?.stages != null ? null : FilterStrategy.top,
      selection: sourceGenes?.stages != null ? null : FilterSelection.percentile,
      percentile: sourceGenes?.stages != null ? null : 0.9,
      count: sourceGenes?.stages != null ? null : 3200,
    );
  }

  /// Loads genes and transcript rates from .fasta data
  Future<void> loadFastaFromString(String data, {String? name, required bool merge}) async {
    _reset();
    this.name = name;
    sourceGenes = GeneList.fromFasta(data, merge);
    resetAnalysisOptions();
    resetFilter();
    notifyListeners();
  }

  Future<void> loadFastaFromFile(String path, {String? filename, required bool merge}) async {
    final data = await File(path).readAsString();
    return await loadFastaFromString(data, name: filename, merge: merge);
  }

  /// Loads info about stages and colors from CSV file
  ///
  /// See [StagesData]
  Future<void> loadStagesFromString(String data) async {
    _reset(preserveSource: true);
    assert(sourceGenes != null);
    final stages = StagesData.fromCsv(data);
    sourceGenes = sourceGenes?.copyWith(stages: stages.stages, colors: stages.colors);
    resetAnalysisOptions();
    resetFilter();
    notifyListeners();
  }

  Future<void> loadStagesFromFile(String path) async {
    final data = await File(path).readAsString();
    return await loadStagesFromString(data);
  }

  void reset() {
    _reset();
    notifyListeners();
  }

  Future<bool> analyze() async {
    assert(stageSelection != null);
    assert(stageSelection!.selectedStages.isNotEmpty);
    assert(motifs.isNotEmpty);
    final totalIterations = stageSelection!.selectedStages.length * motifs.length;
    assert(totalIterations > 0);
    int iterations = 0;
    analysisProgress = 0.0;
    _analysisCancelled = false;
    notifyListeners();
    for (final motif in motifs) {
      for (final key in stageSelection!.selectedStages) {
        await Future.delayed(const Duration(milliseconds: 50)); // Allow UI to refresh on web
        if (_analysisCancelled) {
          analysisProgress = null;
          notifyListeners();
          return false;
        }
        final filteredGenes =
            key == kAllStages ? sourceGenes : sourceGenes!.filter(stage: key, stageSelection: stageSelection!);
        final name = '${key == kAllStages ? 'all' : key} - ${motif.name}';
        final color =
            sourceGenes?.colors.isNotEmpty == true ? (sourceGenes!.colors[key] ?? Colors.grey) : _randomColorOf(name);
        removeAnalysis(name);

        final analysis = await compute(runAnalysis, {
          'genes': filteredGenes,
          'motif': motif,
          'name': name,
          'min': analysisOptions.min,
          'max': analysisOptions.max,
          'interval': analysisOptions.interval,
          'alignMarker': analysisOptions.alignMarker,
          'color': color.value,
        });
        analyses.add(analysis);
        iterations++;
        analysisProgress = iterations / totalIterations;
        notifyListeners();
      }
    }
    analysisProgress = null;
    notifyListeners();
    return true;
  }

  Color _randomColorOf(String text) {
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

Future<Analysis> runAnalysis(Map<String, dynamic> params) async {
  final list = params['genes'] as GeneList;
  final motif = params['motif'] as Motif;
  final name = params['name'] as String;
  final min = params['min'] as int;
  final max = params['max'] as int;
  final interval = params['interval'] as int;
  final alignMarker = params['alignMarker'] as String?;
  final color = Color(params['color'] as int);
  final analysis = Analysis.run(
      geneList: list,
      noOverlaps: true,
      min: min,
      max: max,
      interval: interval,
      alignMarker: alignMarker,
      motif: motif,
      name: name,
      color: color);
  return analysis;
}
