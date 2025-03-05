import 'package:flutter/material.dart';
import 'package:geneweb/analysis/Analysis_history_entry.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:provider/provider.dart';

import '../analysis/analysis_series.dart';
import '../analysis/distribution.dart';
import '../analysis/stage_and_color.dart';
import '../utilities/api_service.dart';
class GeneModel extends ChangeNotifier {
  static GeneModel of(BuildContext context) =>
      Provider.of<GeneModel>(context, listen: false);
  static const kAllStages = '__ALL__';
  String? name = "";
  final ApiService _apiService = ApiService();

  List<Motif> _allMotifs = [];
  List<Motif> _selectedMotifs = [];
  List<StageAndColor> _allStages = [];
  List<AnalysisSeries> analyses = [];
  List<AnalysisHistoryEntry> analysesHistory = [];

  StageSelection _stageSelection = StageSelection();

  List<Motif> get getAllMotifs => _allMotifs;
  List<Motif> get getSelectedMotifs => _selectedMotifs;
  List<StageAndColor> get getAllStages => _allStages;
  List<String> get getSelectedStages => getStageSelectionClass.selectedStages;

  StageSelection get getStageSelectionClass => _stageSelection;

  AnalysisOptions analysisOptions = AnalysisOptions();

  int get expectedSeriesCount =>
      getSelectedMotifs.length * (getStageSelectionClass.selectedStages.length);

  List<String> _markers = [];
  int? _sourceGenesLength;
  int? _sourceGenesKeysLength;
  int? _errorCount;
  String _organismAndStagesFromBe = "";
  get organismAndStagesFromBe => _organismAndStagesFromBe;
  get sourceGenesLength => _sourceGenesLength;
  get sourceGenesKeysLength => _sourceGenesKeysLength;
  get markers => _markers;
  get errorCount => _errorCount;

  void setMotifs(List<Motif> newMotifs) {
    _selectedMotifs = newMotifs;
    notifyListeners();
  }
  void addMotif(Motif motif) {
    _allMotifs.add(motif);
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

  void addAnalysisToHistory(Map<String, dynamic> analysis) {
    try {
      print("🔍 DEBUG: Adding analysis to history: $analysis");

      if (!analysis.containsKey("name")) throw Exception("Missing 'name' field!");
      // if (!analysis.containsKey("distribution")) throw Exception("Missing 'distribution' field!");

      var parsedAnalysis = AnalysisHistoryEntry.fromJson(analysis);
      analysesHistory = [...analysesHistory, parsedAnalysis];

      print("✅ Analysis added successfully: ${parsedAnalysis.id}");
      notifyListeners();
    } catch (error) {
      print("❌ ERROR IN ADD ANALYSIS TO HISTORY: $error");
    }
  }

  void removeAnalyses() {
    analyses.clear();
    notifyListeners();
  }

  void setOptions(AnalysisOptions options) {
    analysisOptions = options;
    notifyListeners();
  }

  Future<void> setOrganism(String organismName) async {
    try {
      await _apiService.setActiveOrganism(organismName);
      name = organismName;
      await fetchActiveOrganism();
      await fetchSourceGenesInformations();
      assert(_sourceGenesLength != null, "Source genes not set");
      // for (var stageName in sourceGenes.defaultSelectedStageKeys)
      //   {
      //     toggleStageSelection(stageName, true);
      //   }
    } catch (error) {
      throw Exception("Error setting active organism: $error");
    }
  }

  Future<void> fetchActiveOrganism() async {
    try {
      final data = await _apiService.getActiveOrganism();
      name = data["organism"];
      _processMotifsAndStages(data);
    } catch (error) {
      print("❌ Error fetching active organism: $error");
    }
  }


  void _processMotifsAndStages(Map<String, dynamic> data) {
    final motifsData = data["motifs"] as List<dynamic>;
    final newMotifs = motifsData.map((m) => Motif.fromJson(m)).toList();
    _allMotifs = newMotifs;

    final stagesData = data["stages"] as List<dynamic>;
    final parsedStages = stagesData.map((s) => StageAndColor.fromJson(s)).toList();
    _allStages = parsedStages;
    cleanSelectedStages();
    notifyListeners();
  }

  void _processSourceGenesInformations(Map<String, dynamic> data) {
    _sourceGenesLength = data["genes_length"] as int?;
    _sourceGenesKeysLength = data["genes_keys_length"] as int?;
    _organismAndStagesFromBe = data["organism_and_stages"] as String;
    _markers = List<String>.from(data["markers"] ?? []);
    _errorCount = data["error_count"] as int? ?? 0;
    notifyListeners();
  }


  Future<void> fetchSourceGenesInformations() async {
    try {
      final data = await _apiService.getActiveOrganismSourceGenesInformations();
      _processSourceGenesInformations(data);

      assert (_sourceGenesLength != null, "Source genes not set");
    } catch (error) {
      print("❌ Error fetching active organism source genes: $error");
    }
  }

  Future<bool> analyze() async {
    assert(getStageSelectionClass.selectedStages.isNotEmpty, "No stages selected");
    assert(getSelectedMotifs.isNotEmpty, "No motifs selected");

    // Prepare request payload
    final params = {
      "color": "#FF0000",
      "minimal": analysisOptions.min,
      "maximal": analysisOptions.max,
      "bucket_size": analysisOptions.bucketSize,
      "stroke": 4,
      "visible": true,
      "no_overlaps": true,
    };

    final payload = {
      "organism": name,
      "motifs": getSelectedMotifs.map((m) => m.name).toList(),
      "stages": getSelectedStages.toList(),
      "params": params,
    };

    try {
      print("🔹 Sending analysis request to backend with payload: $payload");
      final response = await _apiService.postRequest("analysis/analyze/", payload);

      if (response.containsKey("results")) {
        print("✅ Analysis results received");

        addAnalysisToHistory({
          "name": response["results"]["name"],
          "color": response["results"]["color"] != null
              ? Color(response["results"]["color"])
              : Colors.blue,
          "distribution": response["results"]["distribution"],
          "timestamp": DateTime.now().toIso8601String(),
        });

        notifyListeners();
        print("✅ Analysis successfully added to history.");
        return true;
      } else {
        print("❌ Error: Unexpected response from backend: $response");
        return false;
      }
    } catch (error) {
      print("❌ Error running analysis: $error");
      throw Exception("Error running analysis: $error");
    }
  }


  void setSelectedStages(List<String> list) {
    print("Updating selected stages in GeneModel: $list");
    _stageSelection.selectedStages.clear();
    _stageSelection.selectedStages.addAll(list);
    notifyListeners(); // 🚨 This MUST be called
  }


}