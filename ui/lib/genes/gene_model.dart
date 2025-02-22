// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:geneweb/analysis/analysis_series.dart';
// import 'package:geneweb/analysis/analysis_options.dart';
// import 'package:geneweb/analysis/motif.dart';
// import 'package:geneweb/analysis/organism.dart';
// import 'package:geneweb/genes/gene.dart';
// import 'package:geneweb/genes/stage_selection.dart';
// import 'package:geneweb/genes/gene_list.dart';
// import 'package:geneweb/genes/stages_data.dart';
// import 'package:geneweb/genes/tpm_data.dart';
// import 'package:geneweb/my_app.dart';
// import 'package:provider/provider.dart';
// import 'package:universal_file/universal_file.dart';
// import 'package:http/http.dart' as http;
//
// class GeneModel extends ChangeNotifier {
//   // ------------------------------
//   // Basic Properties & Authentication
//   // ------------------------------
//   static const kAllStages = '__ALL__';
//
//   final DeploymentFlavor? deploymentFlavor;
//   late bool _publicSite = deploymentFlavor == DeploymentFlavor.prod;
//   bool get publicSite => _publicSite;
//
//   bool _isSignedIn = false;
//   bool get isSignedIn => _isSignedIn;
//   set isSignedIn(bool value) {
//     _isSignedIn = value;
//     notifyListeners();
//   }
//
//   bool _analysisCancelled = false;
//   bool get analysisCancelled => _analysisCancelled;
//
//   // ------------------------------
//   // Data and Analysis State
//   // ------------------------------
//   String? name; // Organism name
//   GeneList? sourceGenes;
//   List<AnalysisSeries> analyses = [];
//   List<AnalysisSeries> analysesHistory = [];
//   double? analysisProgress;
//
//   AnalysisOptions analysisOptions = AnalysisOptions();
//   StageSelection? _stageSelection;
//   StageSelection? get stageSelection => _stageSelection;
//
//   List<Motif> _motifs = [];
//   List<Motif> _allMotifs = [];
//   List<Motif> get motifs => _motifs;
//   List<Motif> get allMotifs => _allMotifs;
//   set setAllMotifs(List<Motif> newMotifs) {
//     _allMotifs = newMotifs;
//   }
//
//   int get expectedSeriesCount =>
//       motifs.length * (stageSelection?.selectedStages.length ?? 0);
//
//   GeneModel(this.deploymentFlavor);
//
//   static GeneModel of(BuildContext context) =>
//       Provider.of<GeneModel>(context, listen: false);
//
//   // ------------------------------
//   // Reset and Configuration Methods
//   // ------------------------------
//   void _reset({bool preserveSource = false}) {
//     if (!preserveSource) {
//       name = null;
//       sourceGenes = null;
//     }
//     analyses = [];
//     analysisProgress = null;
//     analysisOptions = AnalysisOptions();
//     _stageSelection = null;
//     _motifs = [];
//   }
//
//   void resetAnalysisOptions() {
//     if (sourceGenes?.genes.isNotEmpty ?? false) {
//       final alignMarkers = sourceGenes!.genes.first.markers.keys.toList()..sort();
//       if (alignMarkers.isNotEmpty) {
//         analysisOptions = AnalysisOptions(
//           alignMarker: alignMarkers.first,
//           min: -1000,
//           max: 1000,
//           bucketSize: 30,
//         );
//       } else {
//         analysisOptions = AnalysisOptions();
//       }
//     } else {
//       analysisOptions = AnalysisOptions();
//     }
//   }
//
//   void resetFilter() {
//     final selectedStages = sourceGenes?.defaultSelectedStageKeys ?? [];
//     _stageSelection = StageSelection(
//       selectedStages: [kAllStages, ...selectedStages],
//       strategy: sourceGenes?.stages != null ? null : FilterStrategy.top,
//       selection: sourceGenes?.stages != null ? null : FilterSelection.percentile,
//       percentile: sourceGenes?.stages != null ? null : 0.9,
//       count: sourceGenes?.stages != null ? null : 3200,
//     );
//   }
//
//   // ------------------------------
//   // Public Setters (UI Updates)
//   // ------------------------------
//   void cancelAnalysis() {
//     _analysisCancelled = true;
//     notifyListeners();
//   }
//
//   void setPublicSite(bool value) {
//     if (deploymentFlavor != null)
//       throw Exception('Flavor is defined by deployment');
//     _publicSite = value;
//     notifyListeners();
//   }
//
//   void setAnalyses(List<AnalysisSeries> newAnalyses) {
//     analyses = newAnalyses;
//     notifyListeners();
//   }
//
//   void setMotifs(List<Motif> newMotifs) {
//     _motifs = newMotifs;
//     notifyListeners();
//   }
//
//   void setStageSelection(StageSelection? selection) {
//     _stageSelection = selection;
//     notifyListeners();
//   }
//
//   void setOptions(AnalysisOptions options) {
//     analyses = [];
//     analysisProgress = null;
//     analysisOptions = options;
//     notifyListeners();
//   }
//
//   void removeAnalysis(String analysisName) {
//     analyses = analyses.where((a) => a.name != analysisName).toList();
//     notifyListeners();
//   }
//
//   void removeAnalyses() {
//     analyses = [];
//     notifyListeners();
//   }
//
//   Future<void> reAnalyze() async {
//     await analyze();
//   }
//
//   Future<void> analyzeNew() async {
//     _reset(preserveSource: true);
//     await analyze();
//   }
//
//   void addAnalysisToHistory() {
//     analysesHistory.addAll(analyses);
//   }
//
//   // ------------------------------
//   // Data Loading (Local, to be moved later)
//   // ------------------------------
//   Future<void> loadFastaFromString({
//     required String data,
//     Organism? organism,
//     required Function(double progress) progressCallback,
//   }) async {
//     _reset();
//     name = organism?.name;
//     try {
//       final geneList = await _parseFasta(data, organism, progressCallback);
//       sourceGenes = geneList;
//       resetAnalysisOptions();
//       resetFilter();
//       notifyListeners();
//     } catch (e) {
//       throw Exception("Error loading FASTA: $e");
//     }
//   }
//
//   Future<GeneList> _parseFasta(String data, Organism? organism, Function(double) progressCallback) async {
//     // Delegate to GeneList parsing methods.
//     List<Gene> genes;
//     List<dynamic> errors;
//     final takeSingleTranscript = organism == null || organism.takeFirstTranscriptOnly;
//     (genes, errors) = await GeneList.parseFasta(
//       data,
//       takeSingleTranscript ? (value) => progressCallback(value / 2) : progressCallback,
//     );
//     if (takeSingleTranscript) {
//       (genes, errors) = await GeneList.takeSingleTranscript(
//         genes,
//         errors,
//             (value) => progressCallback(0.5 + value / 2),
//       );
//     }
//     return GeneList.fromList(genes: genes, errors: errors, organism: organism);
//   }
//
//   Future<void> loadFastaFromFile({
//     required String path,
//     String? filename,
//     Organism? organism,
//     required Function(double progress) progressCallback,
//   }) async {
//     final data = await File(path).readAsString();
//     await loadFastaFromString(
//       data: data,
//       organism: organism,
//       progressCallback: progressCallback,
//     );
//   }
//
//   bool loadStagesFromString(String data) {
//     _reset(preserveSource: true);
//     assert(sourceGenes != null, "Source genes must be loaded first");
//     final stagesData = StagesData.fromCsv(data);
//     final List<dynamic> errors = [];
//     final genesSet = sourceGenes!.genes.map((g) => g.geneId).toSet();
//     for (final stageKey in stagesData.stages.keys) {
//       final stageGenes = stagesData.stages[stageKey]!.toSet();
//       final diff = stageGenes.difference(genesSet);
//       if (diff.isNotEmpty) {
//         errors.add(
//             'Found ${diff.length} genes in stage $stageKey not in gene list: ${diff.toList().take(3).join(', ')}${diff.length > 3 ? "…" : ""}');
//       }
//     }
//     sourceGenes = sourceGenes?.copyWith(
//       stages: stagesData.stages,
//       colors: stagesData.colors,
//       errors: errors.isEmpty ? null : [...errors, ...sourceGenes!.errors],
//     );
//     resetAnalysisOptions();
//     resetFilter();
//     notifyListeners();
//     return errors.isEmpty;
//   }
//
//   Future<bool> loadStagesFromFile(String path) async {
//     final data = await File(path).readAsString();
//     return loadStagesFromString(data);
//   }
//
//   bool loadTPMFromString(String data) {
//     _reset(preserveSource: true);
//     assert(sourceGenes != null, "Source genes must be loaded first");
//     final tpmData = TPMData.fromCsv(data);
//     final List<dynamic> errors = [];
//     final List<Gene> newGenes = [
//       for (final gene in sourceGenes!.genes)
//         if (tpmData.stages.keys.every((stageKey) => tpmData.stages[stageKey]![gene.geneId] != null))
//           gene.copyWith(transcriptionRates: {
//             for (final stage in tpmData.stages.keys)
//               stage: tpmData.stages[stage]![gene.geneId]!,
//           }),
//     ];
//     if (newGenes.length != sourceGenes!.genes.length) {
//       errors.add(
//           '${sourceGenes!.genes.length - newGenes.length} genes excluded due to missing TPM data');
//     }
//     sourceGenes = sourceGenes?.copyWith(
//       genes: newGenes,
//       errors: errors.isEmpty ? null : [...errors, ...sourceGenes!.errors],
//       colors: tpmData.colors,
//     );
//     resetAnalysisOptions();
//     resetFilter();
//     notifyListeners();
//     return errors.isEmpty;
//   }
//
//   Future<bool> loadTPMFromFile(String path) async {
//     final data = await File(path).readAsString();
//     return loadTPMFromString(data);
//   }
//
//   // ------------------------------
//   // Analysis (Delegates heavy work to backend eventually)
//   // ------------------------------
//   Future<bool> analyze() async {
//     assert(stageSelection != null, "Stage selection must be set");
//     assert(stageSelection!.selectedStages.isNotEmpty, "No stages selected");
//     assert(motifs.isNotEmpty, "No motifs selected");
//     final totalIterations = stageSelection!.selectedStages.length * motifs.length;
//     assert(totalIterations > 0, "Total iterations must be greater than zero");
//     int iterations = 0;
//     analysisProgress = 0.0;
//     _analysisCancelled = false;
//     notifyListeners();
//
//     for (final motif in motifs) {
//       for (final stageKey in stageSelection!.selectedStages) {
//         await Future.delayed(const Duration(milliseconds: 50));
//         if (_analysisCancelled) {
//           analysisProgress = null;
//           notifyListeners();
//           return false;
//         }
//         final analysisName = '${stageKey == kAllStages ? 'all' : stageKey} - ${motif.name}';
//         final color = sourceGenes?.colors.isNotEmpty == true
//             ? (sourceGenes!.colors[stageKey] ?? Colors.grey)
//             : _randomColorOf(analysisName);
//         final stroke = stageKey == kAllStages ? 4 : sourceGenes?.stroke[stageKey];
//         removeAnalysis(analysisName);
//         final params = {
//           'motif': motif.toJson(),
//           'name': analysisName,
//           'min': analysisOptions.min,
//           'max': analysisOptions.max,
//           'interval': analysisOptions.bucketSize,
//           'alignMarker': analysisOptions.alignMarker,
//           'color': color.value,
//           'stroke': stroke,
//           'organism_file': name ?? "default_organism.fasta",
//         };
//
//
//         try {
//           final response = await http.post(
//             Uri.parse("http://localhost:8000/api/analysis/run/"),
//             headers: {"Content-Type": "application/json"},
//             body: jsonEncode(params),
//           );
//           if (response.statusCode == 200) {
//             final json = jsonDecode(response.body);
//             final analysisSeries = AnalysisSeries.fromJson(json);
//             analyses.add(analysisSeries);
//           } else {
//             // Optionally handle error responses here
//           }
//         } catch (e) {
//           // Handle network or JSON errors
//         }
//         iterations++;
//         analysisProgress = iterations / totalIterations;
//         notifyListeners();
//       }
//     }
//
//     analysisProgress = null;
//     notifyListeners();
//     return true;
//   }
//
//   Color _randomColorOf(String text) {
//     var hash = 0;
//     for (var i = 0; i < text.length; i++) {
//       hash = text.codeUnitAt(i) + ((hash << 5) - hash);
//     }
//     final finalHash = hash.abs() % (256 * 256 * 256);
//     final red = ((finalHash & 0xFF0000) >> 16);
//     final blue = ((finalHash & 0xFF00) >> 8);
//     final green = ((finalHash & 0xFF));
//     return Color.fromRGBO(red, green, blue, 1);
//   }
//
// }
//
// Future<AnalysisSeries> runAnalysis(Map<String, dynamic> params) async {
//   final list = params['genes'] as GeneList;
//   final motif = params['motif'] as Motif;
//   final name = params['name'] as String;
//   final min = params['min'] as int;
//   final max = params['max'] as int;
//   final interval = params['interval'] as int;
//   final alignMarker = params['alignMarker'] as String?;
//   final color = Color(params['color'] as int);
//   final stroke = params['stroke'] as int?;
//   final analysis = AnalysisSeries.run(
//     geneList: list,
//     noOverlaps: true,
//     min: min,
//     max: max,
//     bucketSize: interval,
//     alignMarker: alignMarker,
//     motif: motif,
//     name: name,
//     color: color,
//     stroke: stroke,
//   );
//   return analysis;
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class GeneModel extends ChangeNotifier {
  static const kAllStages = '__ALL__';

  String? name;

  AnalysisOptions analysisOptions = AnalysisOptions();
  StageSelection? _stageSelection;
  StageSelection? get stageSelection => _stageSelection;

  List<Motif> _motifs = [];
  List<Motif> get motifs => _motifs;

  int get expectedSeriesCount =>
      motifs.length * (stageSelection?.selectedStages.length ?? 0);

  GeneModel();

  static GeneModel of(BuildContext context) =>
      Provider.of<GeneModel>(context, listen: false);

  void setStageSelection(StageSelection? selection) {
    _stageSelection = selection;
    notifyListeners();
  }

  void setMotifs(List<Motif> newMotifs) {
    _motifs = newMotifs;
    notifyListeners();
  }

  void setOptions(AnalysisOptions options) {
    analysisOptions = options;
    notifyListeners();
  }

  Future<void> setOrganism(String organismName) async {
    name = organismName;
    notifyListeners();
  }

  Future<void> loadOrganismFromBackend(String organismName) async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:8000/api/set_active_organism/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"organism": organismName}),
      );

      if (response.statusCode == 200) {
        name = organismName;
        notifyListeners();
      } else {
        throw Exception("Failed to set active organism");
      }
    } catch (error) {
      throw Exception("Error loading organism: $error");
    }
  }
}
