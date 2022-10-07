import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geneweb/analysis/analysis.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/distribution.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:universal_file/universal_file.dart';

class GeneModel extends ChangeNotifier {
  String? filename;
  GeneList? sourceGenes;
  Analysis? analysis;
  List<Distribution> distributions = [];
  bool isAnalysisRunning = false;
  AnalysisOptions analysisOptions = AnalysisOptions();

  GeneModel();

  static GeneModel of(BuildContext context) => Provider.of<GeneModel>(context, listen: false);

  void _reset() {
    distributions = [];
    analysis = null;
    isAnalysisRunning = false;
    final keys = sourceGenes?.genes.first.markers.keys;
    if (keys != null && keys.isNotEmpty) {
      analysisOptions = AnalysisOptions(alignMarker: keys.first, min: -1000, max: 1000, interval: 10);
    } else {
      analysisOptions = AnalysisOptions();
    }
  }

  void resetAnalysis() {
    analysis = null;
    isAnalysisRunning = false;
    notifyListeners();
  }

  void setOptions(AnalysisOptions options) {
    _reset();
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

  Future<void> loadFromString(String data, {String? filename}) async {
    filename = filename;
    sourceGenes = GeneList.fromFasta(data);
    _reset();
    notifyListeners();
  }

  Future<void> loadFromFile(String path, {String? filename}) async {
    filename = filename;
    final data = await File(path).readAsString();
    sourceGenes = GeneList.fromFasta(data);
    _reset();
    notifyListeners();
  }

  Future<void> loadFromAssets(String filename) async {
    filename = filename;
    final data = await rootBundle.loadString('assets/$filename');
    sourceGenes = GeneList.fromFasta(data);
    _reset();
    notifyListeners();
  }

  Future<void> loadFromUrl(String url) async {
    filename = url;
    var uri = Uri.parse(url);
    var response = await http.get(uri);
    sourceGenes = GeneList.fromFasta(response.body);
    _reset();
    notifyListeners();
  }

  Future<void> analyze(
    GeneList genes,
    Motif motif,
    String name,
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
  final analysis = Analysis(
      geneList: list,
      noOverlaps: true,
      min: min,
      max: max,
      interval: interval,
      alignMarker: alignMarker,
      motif: motif,
      name: name);
  analysis.run(motif);
  return analysis;
}
