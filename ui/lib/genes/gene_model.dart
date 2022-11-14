import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:provider/provider.dart';
import 'package:universal_file/universal_file.dart';

class GeneModel extends ChangeNotifier {
  String? name;
  GeneList? sourceGenes;
  List<Analysis> analyses = [];
  double? analysisProgress;
  AnalysisOptions analysisOptions = AnalysisOptions();
  StageSelection? _filter;
  StageSelection? get filter => _filter;
  Motif? _motif;
  Motif? get motif => _motif;

  GeneModel();

  static GeneModel of(BuildContext context) => Provider.of<GeneModel>(context, listen: false);

  void _reset() {
    name = null;
    sourceGenes = null;
    analyses = [];
    analysisProgress = null;
    analysisOptions = AnalysisOptions();
    _filter = null;
    _motif = null;
  }

  void setAnalyses(List<Analysis> analyses) {
    this.analyses = analyses;
    notifyListeners();
  }

  void setMotif(Motif? motif) {
    _motif = motif;
    notifyListeners();
  }

  void setFilter(StageSelection? filter) {
    _filter = filter;
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
      analysisOptions = AnalysisOptions(alignMarker: keys.first, min: -1000, max: 1000, interval: 10);
    } else {
      analysisOptions = AnalysisOptions();
    }
    notifyListeners();
  }

  Future<void> loadFromString(String data, {String? name}) async {
    _reset();
    this.name = name;
    sourceGenes = GeneList.fromFasta(data);
    resetAnalysisOptions();
    notifyListeners();
  }

  Future<void> loadFromFile(String path, {String? filename}) async {
    _reset();
    name = filename;
    final data = await File(path).readAsString();
    sourceGenes = GeneList.fromFasta(data);
    resetAnalysisOptions();
    notifyListeners();
  }

  void reset() {
    _reset();
    notifyListeners();
  }

  Future<void> analyze(
    StageSelection? filter,
    Motif motif,
  ) async {
    const kAll = '__ALL__';
    final stages = filter?.stages ?? [kAll];
    final totalIterations = stages.length;
    assert(totalIterations > 0);
    int iterations = 0;
    analysisProgress = 0.0;
    notifyListeners();
    for (final key in stages) {
      await Future.delayed(const Duration(milliseconds: 50)); // Allow UI to refresh on web
      final filteredGenes = key == kAll ? sourceGenes : sourceGenes!.filter(filter!, key);
      final name = '${key == kAll ? 'all' : key} - ${motif.name}';
      final color = _colorFor(name);
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
    analysisProgress = null;
    notifyListeners();
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
