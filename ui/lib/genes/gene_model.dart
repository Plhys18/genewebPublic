import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:provider/provider.dart';

import '../analysis/stage_and_color.dart';
import '../utilities/api_service.dart';
class GeneModel extends ChangeNotifier {
  static const kAllStages = '__ALL__';
  String? name = "";
  final ApiService _apiService = ApiService();

  List<Motif> _allMotifs = [];
  List<Motif> _selectedMotifs = [];
  List<StageAndColor> _allStages = [];
  List<Map<String, dynamic>> _analysesHistory = [];
  final StageSelection _stageSelection = StageSelection();

  List<Motif> get getAllMotifs => _allMotifs;
  List<Motif> get getSelectedMotifs => _selectedMotifs;
  List<StageAndColor> get getAllStages => _allStages;
  List<String> get getSelectedStages => getStageSelectionClass.selectedStages;

  List<Map<String, dynamic>> get getAnalysesHistory => _analysesHistory;
  StageSelection get getStageSelectionClass => _stageSelection;

  AnalysisOptions? analysisOptions;

  int get expectedSeriesCount =>
      getSelectedMotifs.length * (getStageSelectionClass.selectedStages.length);

  get initialOptions => AnalysisOptions();

  static GeneModel of(BuildContext context) =>
      Provider.of<GeneModel>(context, listen: false);

  void setMotifs(List<Motif> newMotifs) {
    _allMotifs = newMotifs;
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
    print("🔍 DEBUG: Toggling stage $stage with value $value");
    if (value && !getSelectedStages.contains(stage)) {
      print("🔍 DEBUG: Adding stage $stage to selected stages");
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
    _analysesHistory.add(analysis);
    notifyListeners();
  }
  void removeAnalyses() {
    _analysesHistory.clear();
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

  Future<void> analyze() async {

    assert(getStageSelectionClass != null, "Stage selection must be set");
    assert(getStageSelectionClass!.selectedStages.isNotEmpty, "No stages selected");
    assert(getSelectedMotifs.isNotEmpty, "No motifs selected");
    print("🔍 DEBUG: Selected stages before sending: $getSelectedStages");

    final params = {
      "color": "#FF0000",
      "minimal": analysisOptions?.min ?? initialOptions.minilam,
      "maximal": analysisOptions?.max ?? initialOptions.maximal,
      "bucket_size": analysisOptions?.bucketSize ?? initialOptions.bucketSize,
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
      final response = await _apiService.postRequest(
          "analysis/analyze/", payload);

      if (response.containsKey("results")) {
        print("✅ Analysis results received: ${response['results']
            .length} entries");

        addAnalysisToHistory({
          "name": "Analysis for $name",
          "results": response["results"],
          "timestamp": DateTime.now().toIso8601String()
        });

        notifyListeners();
        print("✅ Analysis successfully added to history.");
      } else {
        print("❌ Error: Unexpected response from backend: $response");
      }
    } catch (error) {
      print("❌ Error running analysis: $error");
      throw Exception("Error running analysis: $error");
    }
  }

  void setSelectedStages(List<String> list) {
    _stageSelection.selectedStages.clear();
    _stageSelection.selectedStages.addAll(list);
  }

}