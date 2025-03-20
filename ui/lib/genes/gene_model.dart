import 'package:flutter/material.dart';
import 'package:geneweb/analysis/Analysis_history_entry.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:provider/provider.dart';

import '../analysis/analysis_series.dart';
import '../analysis/stage_and_color.dart';
import '../utilities/api_service.dart';
class GeneModel extends ChangeNotifier {
  static GeneModel of(BuildContext context) =>
      Provider.of<GeneModel>(context, listen: false);
  static const kAllStages = '__ALL__';

  String? name = "";

  List<Motif> _allMotifs = [];
  List<Motif> _selectedMotifs = [];
  List<StageAndColor> _allStages = [];
  List<AnalysisSeries> _analyses = [];
  List<AnalysisHistoryEntry> _analysesHistory = [];
  List<String> _markers = [];
  List<String> _defaultSelectedStageKeys = [];
  int? _sourceGenesLength;
  int? _sourceGenesKeysLength;
  int? _errorCount;
  String _organismAndStagesFromBe = "";

  StageSelection _stageSelection = StageSelection();
  List<Motif> get getAllMotifs => _allMotifs;
  List<Motif> get getSelectedMotifs => _selectedMotifs;
  List<StageAndColor> get getAllStages => _allStages;
  List<String> get getSelectedStages => getStageSelectionClass.selectedStages;
  List<AnalysisHistoryEntry> get getAnalysesHistory => _analysesHistory;
  StageSelection get getStageSelectionClass => _stageSelection;

  AnalysisOptions analysisOptions = AnalysisOptions();

  int get expectedSeriesCount =>
      getSelectedMotifs.length * (getStageSelectionClass.selectedStages.length);


  get organismAndStagesFromBe => _organismAndStagesFromBe;
  get sourceGenesLength => _sourceGenesLength;
  get sourceGenesKeysLength => _sourceGenesKeysLength;
  get defaultSelectedStageKeys => _defaultSelectedStageKeys;
  get markers => _markers;
  get errorCount => _errorCount;
  List<AnalysisSeries> get getAnalyses => _analyses;

  void setMotifs(List<Motif> newMotifs) {
    _selectedMotifs = newMotifs;
    notifyListeners();
  }
  void addMotif(Motif motif) {
    _allMotifs.add(motif);
    notifyListeners();
  }
  void setAnalyses(List<AnalysisSeries> newAnalyses) {
    _analyses = newAnalyses;
    notifyListeners();
  }

  void toggleMotifSelected(Motif motif, bool value) {
    if ( !value && getSelectedMotifs.contains(motif)) {
      getSelectedMotifs.remove(motif);
    }
    if ( value && !getSelectedMotifs.contains(motif)) {
      getSelectedMotifs.add(motif);
    }
    notifyListeners();
  }

  void cleanMotifsSelected() {
    _selectedMotifs = [];
    notifyListeners();
  }
  void cleanAllMotifs() {
    _allMotifs = [];
    notifyListeners();
  }

  void toggleStageSelection(String stage, bool value) {
    if (value && !getSelectedStages.contains(stage)) {
      _stageSelection.selectedStages.add(stage);
    }
    if (!value && getSelectedStages.contains(stage)) {
      _stageSelection.selectedStages.remove(stage);
    }
    notifyListeners();
  }
  void cleanSelectedStages() {
    getStageSelectionClass.selectedStages.clear();
    notifyListeners();
  }

  void addAnalysisToHistory(AnalysisHistoryEntry analysisHistoryEntry) {
    try {
      _analysesHistory = [..._analysesHistory, analysisHistoryEntry];
      notifyListeners();
    } catch (error) {
      print("❌ ERROR IN ADD ANALYSIS TO HISTORY: $error");
    }
  }

  void removeAnalyses() {
    _analyses.clear();
    notifyListeners();
  }

  void setOptions(AnalysisOptions options) {
    analysisOptions = options;
    notifyListeners();
  }

  Future<void> fetchOrganismDetails(String organismName) async {
    try {
      removeAnalyses();
      name = organismName;
      final data = await ApiService().getOrganismDetails(organismName);

      if (!data.containsKey("genes_length")) {
        throw Exception("Invalid API response: Missing 'genes_length' key.");
      }

      _processMotifsAndStages(data);

      assert(_sourceGenesLength != null, "Source genes not set");

      for (var stageName in defaultSelectedStageKeys) {
        toggleStageSelection(stageName, true);
      }

    } catch (error) {
      throw Exception("Error fetching organism details: $error");
    }
  }



  Future<void> fetchAnalyses() async {
      _analysesHistory= await ApiService().fetchAnalyses();
  }

  Future<void> fetchPastUserAnalyses() async {
    try {
      _analysesHistory = await ApiService().fetchAnalyses();
      if (_analysesHistory.isEmpty) return;

      // Fetch the most recent analysis
      final latestAnalysisEntry = _analysesHistory.first;
      print("✅ [FETCH LATEST ANALYSIS] ID: ${latestAnalysisEntry.id}");

      final fullAnalysis = await ApiService().fetchAnalysisDetails(latestAnalysisEntry.id);
      _analyses.add(fullAnalysis);

      notifyListeners();
    } catch (error) {
      print("❌ Error fetching past analyses: $error");
    }
  }



  /// Fetch the list of analysis history
  Future<void> fetchAnalysisHistory() async {
    try {
      // print("🔍 Fetching analysis history...");
      var HistoryRecords = await ApiService().fetchAnalyses();
      for(var record in HistoryRecords as List<dynamic>){
        // print("🔍 Fetching analysis history... $record");
        _analysesHistory.add(AnalysisHistoryEntry.fromJson(record));
      }
      notifyListeners();
      // print("✅ Analysis history loaded.");
    } catch (error) {
      // print("❌ Error fetching analysis history: $error");
    }
  }

  void _processMotifsAndStages(Map<String, dynamic> data) {
    cleanSelectedStages();
    cleanMotifsSelected();
    final motifsData = data["motifs"] as List<dynamic>;
    final newMotifs = motifsData.map((m) => Motif.fromJson(m)).toList();
    _allMotifs = newMotifs;

    final stagesData = data["stages"] as List<dynamic>;
    final parsedStages = stagesData.map((s) => StageAndColor.fromJson(s)).toList();
    _allStages = parsedStages;

    _sourceGenesLength = data["genes_length"] as int?;
    _sourceGenesKeysLength = data["genes_keys_length"] as int?;
    _organismAndStagesFromBe = data["organism_and_stages"] as String;
    _markers = List<String>.from(data["markers"] ?? []);
    _errorCount = data["error_count"] as int? ?? 0;
    _defaultSelectedStageKeys = List<String>.from(data["default_selected_stage_keys"] ?? []);

    cleanSelectedStages();
    notifyListeners();
  }

  //
  // void _processSourceGenesInformations(Map<String, dynamic> data) {
  //   _sourceGenesLength = data["genes_length"] as int?;
  //   _sourceGenesKeysLength = data["genes_keys_length"] as int?;
  //   _organismAndStagesFromBe = data["organism_and_stages"] as String;
  //   _markers = List<String>.from(data["markers"] ?? []);
  //   _errorCount = data["error_count"] as int? ?? 0;
  //   _defaultSelectedStageKeys = List<String>.from(data["default_selected_stage_keys"] ?? []);
  //   notifyListeners();
  // }


  // Future<void> fetchSourceGenesInformations() async {
  //   try {
  //     final data = await _ApiService().getActiveOrganismSourceGenesInformations();
  //     _processSourceGenesInformations(data);
  //
  //     assert (_sourceGenesLength != null, "Source genes not set");
  //   } catch (error) {
  //     print("❌ Error fetching active organism source genes: $error");
  //   }
  // }

  Future<bool> analyze() async {
    assert(getStageSelectionClass.selectedStages.isNotEmpty, "No stages selected");
    assert(getSelectedMotifs.isNotEmpty, "No motifs selected");

    final params = {
      "color": "#FF0000",
      "minimal": analysisOptions.min,
      "maximal": analysisOptions.max,
      "bucket_size": analysisOptions.bucketSize,
      "align_marker": analysisOptions.alignMarker,
      "stroke": 4,
      "visible": true,
      "no_overlaps": true,
      "strategy": _stageSelection.strategy?.name ?? "top",
      "selection": _stageSelection.selection?.name ?? "percentile",
      "percentile": _stageSelection.percentile ?? 0.9,
      "count": _stageSelection.count ?? 3200,
    };

    final payload = {
      "organism": name,
      "motifs": getSelectedMotifs.map((m) => m.name).toList(),
      "stages": getSelectedStages.toList(),
      "params": params,
    };

    print("🔹 Sending analysis request to backend with payload: $payload");
    final response = await ApiService().postRequest("analysis/analyze/", payload);

    if (response.containsKey("results")) {
      final dynamic results = response["results"];

      if (results is List) {
        _analyses.addAll(results.map((e) => AnalysisSeries.fromJson(e as Map<String, dynamic>)));
      } else if (results is Map<String, dynamic>) {
        _analyses.add(AnalysisSeries.fromJson(results));
      } else {
        throw Exception("Unexpected format for 'results'");
      }

      notifyListeners();
      return true;
    }

    return false;

  }


  void setSelectedStages(List<String> list) {
    print("Updating selected stages in GeneModel: $list");
    _stageSelection.selectedStages.clear();
    _stageSelection.selectedStages.addAll(list);
    notifyListeners();
  }

  loadAnalysis(analysisHistoryEntry) {
    print("🔍 Loading analysis with id: ${analysisHistoryEntry.id}");
    ApiService().fetchAnalysisDetails(analysisHistoryEntry.id).then((analysis) {
      _analyses.add(analysis);
    });
    notifyListeners();
  }

  void setStageSelection(StageSelection selection) {
    _stageSelection = selection;
    notifyListeners();
  }

  void removeEverythingAssociatedWithCurrentSession() {
    name = "";
    _allStages.clear();
    _analyses.clear();
    _allMotifs.clear();
    _selectedMotifs.clear();
    notifyListeners();
  }

}