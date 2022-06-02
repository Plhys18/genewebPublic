import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geneweb/analysis/analysis.dart';
import 'package:geneweb/analysis/distribution.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/filter_definition.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:universal_file/universal_file.dart';

class GeneModel extends ChangeNotifier {
  String? filename;
  GeneList? sourceGenes;
  FilterDefinition filter = FilterDefinition();
  Analysis? analysis;
  List<Distribution> distributions = [];
  bool isAnalysisRunning = false;
  GeneList? filteredGenes;

  GeneModel();

  static GeneModel of(BuildContext context) => Provider.of<GeneModel>(context, listen: false);

  void setFilter(FilterDefinition filter) {
    this.filter = filter;
    filteredGenes = sourceGenes!.filter(filter);
    notifyListeners();
  }

  void _reset() {
    analysis = null;
    distributions = [];
    isAnalysisRunning = false;
    filter = FilterDefinition();
    filteredGenes = sourceGenes;
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

  Future<void> analyze(Motif motif, {int min = 0, int max = 3000, int interval = 100, String? alignMarker}) async {
    analysis = null;
    isAnalysisRunning = true;
    notifyListeners();
    analysis = await compute(runAnalysis, {
      'genes': filteredGenes,
      'motif': motif,
      'filter': filter,
      'min': min,
      'max': max,
      'interval': interval,
      'alignMarker': alignMarker,
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
  final filter = params['filter'] as FilterDefinition;
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
      filter: filter);
  analysis.run(motif);
  return analysis;
}
