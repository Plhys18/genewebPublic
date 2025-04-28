import 'package:flutter/material.dart';
import 'package:geneweb/analysis/Analysis_history_entry.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:provider/provider.dart';

import '../analysis/analysis_series.dart';
import '../analysis/stage_and_color.dart';
import '../utilities/api_service.dart';

class GeneModelRegistry {
  static final List<BuildContext?> instances = [];

  static void register(BuildContext context) {
    instances.add(context);
  }

  static void unregister(BuildContext context) {
    instances.remove(context);
  }
}

class GeneModel extends ChangeNotifier {
  static GeneModel of(BuildContext context) {
    final model = Provider.of<GeneModel>(context, listen: false);
    GeneModelRegistry.register(context);
    return model;
  }
  
  static const kAllStages = '__ALL__';

  String? name = "";
  String? filename = "";
  bool _isLoading = false;

  List<Motif> _allMotifs = [];
  List<String> _selectedMotifsNames = [];
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
  List<String> get getSelectedMotifsNames => _selectedMotifsNames;
  List<StageAndColor> get getAllStages => _allStages;
  List<String> get getSelectedStages => getStageSelectionClass.selectedStages;
  List<AnalysisHistoryEntry> get getAnalysesHistory => _analysesHistory;
  StageSelection get getStageSelectionClass => _stageSelection;
  bool get isLoading => _isLoading;
  String? get getFilename => filename;

  AnalysisOptions analysisOptions = AnalysisOptions();

  int get expectedSeriesCount =>
      getSelectedMotifsNames.length * (getStageSelectionClass.selectedStages.length);


  get organismAndStagesFromBe => _organismAndStagesFromBe;
  get sourceGenesLength => _sourceGenesLength;
  get sourceGenesKeysLength => _sourceGenesKeysLength;
  get defaultSelectedStageKeys => _defaultSelectedStageKeys;
  get markers => _markers;
  get errorCount => _errorCount;
  List<AnalysisSeries> get getAnalyses => _analyses;

  void setMotifs(List<String> newMotifs) {
    _selectedMotifsNames = newMotifs;
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
  void setStages(List<StageAndColor> stages) {
    _allStages = stages;
    notifyListeners();
  }
  void toggleMotifSelected(String motifName, bool value) {
    if ( !value && getSelectedMotifsNames.contains(motifName)) {
      getSelectedMotifsNames.remove(motifName);
    }
    if ( value && !getSelectedMotifsNames.contains(motifName)) {
      getSelectedMotifsNames.add(motifName);
    }
    notifyListeners();
  }

  void cleanMotifsSelected() {
    _selectedMotifsNames = [];
    notifyListeners();
  }
  void cleanAllMotifs() {
    _allMotifs = [];
    notifyListeners();
  }

  void setSelectedStages(List<String> list) {
    print("Updating selected stages in GeneModel: $list");
    _stageSelection.selectedStages.clear();
    _stageSelection.selectedStages.addAll(list);
    notifyListeners();
  }

  void setStageSelection(StageSelection selection) {
    _stageSelection = selection;
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

  void removeAnalyses() {
    _analyses.clear();
    notifyListeners();
  }

  void setOptions(AnalysisOptions options) {
    analysisOptions = options;
    notifyListeners();
  }

  Future<void> fetchOrganismDetails(String organismFile) async {
    _isLoading = true;
    notifyListeners();
    _sourceGenesLength = null;
    notifyListeners();
    try {
      removeAnalyses();
      final data = await ApiService().getOrganismDetails(organismFile);

      if (!data.containsKey("genes_length")) {
        throw Exception("Invalid API response: Missing 'genes_length' key.");
      }

      _processMotifsAndStages(data);

      filename = organismFile;
      name = data["organism"] ?? "Undefined";
      assert(_sourceGenesLength != null, "Source genes not set");

      for (var stageName in defaultSelectedStageKeys) {
        toggleStageSelection(stageName, true);
      }

    } catch (error) {
      throw Exception("Error fetching organism details: $error $organismFile");
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<bool> analyze() async {
    assert(getStageSelectionClass.selectedStages.isNotEmpty, "No stages selected");
    assert(getSelectedMotifsNames.isNotEmpty, "No motifs selected");

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
      "filename": filename,
      "motifs": getSelectedMotifsNames,
      "stages": getSelectedStages.toList(),
      "params": params,
    };

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

  Future<bool> loadAnalysisSettings(int analysisId) async {
    try {
      final response = await ApiService().fetchAnalysisSettings(analysisId);
      if (response['motifs'] != null) {
        var motifs = response['motifs'] as List;
        List<String> mappedMotifs = motifs.map((m) => m.toString()).toList();
        setMotifs(mappedMotifs);
      }

      if (response['stages'] != null) {
        var stages = response['stages'] as List;
        List<String> mappedStages = stages.map((s) => s.toString()).toList();
        setSelectedStages(mappedStages);
      }

      if (response['options'] != null) {
        final options = AnalysisOptions.fromJson(response['options']);
        setOptions(options!);
      }
      return true;
    } catch (e) {
      debugPrint('Error loading analysis settings: $e');
      return false;
    }
  }

  Future<bool> loadAnalysis(AnalysisHistoryEntry analysis) async {
    try {
      await loadAnalysisSettings(analysis.id);

      final response = await ApiService().getRequest('analysis/history/${analysis.id}');
      
      if (response != null && response['filtered_results'] != null) {
        final resultsList = response['filtered_results'] as List;
        final analysisSeries = resultsList.map((result) =>
            AnalysisSeries.fromJson(result as Map<String, dynamic>)
        ).toList();

        setAnalyses(analysisSeries);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error loading analysis: $e');
      return false;
    }
  }

  Future<List<AnalysisHistoryEntry>> fetchUserAnalysesHistory() async {
    try {
      _analysesHistory = await ApiService().fetchAnalysesHistory();
      notifyListeners();
      return _analysesHistory;
    } catch (e) {
      debugPrint('Error fetching analysis history: $e');
      rethrow;
    }
  }

  Future<void> fetchPublicOrganisms() async {
  try {
    _isLoading = true;
    notifyListeners();
    
    // Clear existing data
    name = "";
    filename = "";
    _allStages.clear();
    _analyses.clear();
    _allMotifs.clear();
    _selectedMotifsNames.clear();
    
    final organisms = await ApiService().getOrganisms();
    final isAuthenticated = ApiService().isAuthenticated;

    debugPrint('Fetched ${organisms.length} organisms. Authenticated: $isAuthenticated');
    
    _isLoading = false;
    notifyListeners();
  } catch (error) {
    _isLoading = false;
    notifyListeners();
    debugPrint("Error fetching public organisms: $error");
  }
	}

  Future<void> initializeData() async {
    try {
      removeEverythingAssociatedWithCurrentSession();
      await fetchPublicOrganisms();
    } catch (error) {
      debugPrint("Error initializing data: $error");
    }
  }

  void removeEverythingAssociatedWithCurrentSession() {
    name = "";
    filename = "";
    _allStages.clear();
    _analyses.clear();
    _allMotifs.clear();
    _selectedMotifsNames.clear();
    _analysesHistory.clear();
    _markers.clear();
    _defaultSelectedStageKeys.clear();
    _sourceGenesLength = null;
    _sourceGenesKeysLength = null;
    _errorCount = null;
    _organismAndStagesFromBe = "";
    _stageSelection = StageSelection();
    analysisOptions = AnalysisOptions();

    notifyListeners();
  }

  @override
  void dispose() {
    for (final context in List.from(GeneModelRegistry.instances)) {
      if (context != null) {
        try {
          final currentModel = Provider.of<GeneModel>(context, listen: false);
          if (currentModel == this) {
            GeneModelRegistry.unregister(context);
          }
        } catch (e) {
          GeneModelRegistry.unregister(context);
        }
      }
    }
    super.dispose();
  }
}
