import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/distribution.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/filter_definition.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:provider/provider.dart';
import 'package:universal_file/universal_file.dart';

class GeneModel extends ChangeNotifier {
  String? name;
  GeneList? sourceGenes;
  Analysis? analysis;
  List<Distribution> distributions = [];
  bool isAnalysisRunning = false;
  AnalysisOptions analysisOptions = AnalysisOptions();
  StageSelection? filter;
  Motif? motif;

  GeneModel();

  static GeneModel of(BuildContext context) => Provider.of<GeneModel>(context, listen: false);

  void _reset() {
    name = null;
    sourceGenes = null;
    analysis = null;
    distributions = [];
    isAnalysisRunning = false;
    analysisOptions = AnalysisOptions();
    filter = null;
    motif = null;
  }

  void resetAnalysis() {
    analysis = null;
    isAnalysisRunning = false;
    notifyListeners();
  }

  void setOptions(AnalysisOptions options) {
    analysis = null;
    distributions = [];
    isAnalysisRunning = false;
    analysisOptions = options;
    notifyListeners();
  }

  void removeDistribution(Distribution distribution) {
    distributions = distributions.where((d) => d != distribution).toList();
    notifyListeners();
  }

  void updateDistributions(List<Distribution> distributions) {
    this.distributions = distributions;
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
    GeneList genes,
    Motif motif,
    String name,
    Color color,
  ) async {
    analysis = null;
    isAnalysisRunning = true;
    notifyListeners();
    analysis = await compute(runAnalysis, {
      'genes': genes,
      'motif': motif,
      'name': name,
      'min': analysisOptions.min,
      'max': analysisOptions.max,
      'interval': analysisOptions.interval,
      'alignMarker': analysisOptions.alignMarker,
      'color': color.value,
    });
    isAnalysisRunning = false;
    notifyListeners();
  }

  void clearAnalysis() {
    analysis = null;
    notifyListeners();
  }

  void analysisToDistribution() {
    distributions = [...distributions, analysis!.distribution!];
    notifyListeners();
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
  final analysis = Analysis(
      geneList: list,
      noOverlaps: true,
      min: min,
      max: max,
      interval: interval,
      alignMarker: alignMarker,
      motif: motif,
      name: name,
      color: color);
  analysis.run(motif);
  return analysis;
}
