
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/screens/analysis_screen.dart';
import 'package:geneweb/widgets/analysis_options_panel.dart';
import 'package:geneweb/widgets/motif_panel.dart';
import 'package:geneweb/widgets/stage_panel.dart';
import 'package:geneweb/widgets/source_panel.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final GeneModel _model = GeneModel.of(context);
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stepper(
            currentStep: _index,
            onStepCancel: _index > 0 ? _handleStepCancel : null,
            onStepContinue: _isStepAllowed(_index + 1) ? _handleStepContinue : null,
            onStepTapped: _handleStepTapped,
            physics: const NeverScrollableScrollPhysics(),
            steps: <Step>[
              Step(
                title: const Text('Species'),
                subtitle: Text(_model.name ?? 'Select an organism'),
                content: SourcePanel(
                  onShouldClose: () => _handleStepTapped(1),
                ),
                state: _model.name == "" ? StepState.indexed : StepState.complete,
              ),
              Step(
                title: const Text('Genomic Interval'),
                content: AnalysisOptionsPanel(
                  initialOptions: _model.initialOptions,
                  onChanged: _handleAnalysisOptionsChanged,
                ),
                state: _model.analysisOptions == null ? StepState.indexed : StepState.complete,
              ),
              Step(
                title: const Text('Motif Selection'),
                content: MotifPanel(
                  onChanged: _handleMotifsChanged,
                ),
                state: _model.getSelectedMotifs.isEmpty ? StepState.indexed : StepState.complete,
              ),
              Step(
                title: const Text('Developmental Stages'),
                content: StagePanel(
                  onChanged: _handleStageSelectionChanged,
                ),
                state: _model.getStageSelectionClass == null ? StepState.indexed : StepState.complete,
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              await _model.analyze();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalysisScreen()));
            },
            child: const Text('Run Analysis'),
          ),
        ],
      ),
    );
  }

  void _handleStepTapped(int index) {
    if (_isStepAllowed(index)) {
      setState(() => _index = index);
    }
  }

  void _handleStepCancel() {
    if (_index > 0) setState(() => _index -= 1);
  }

  Future<void> _handleStepContinue() async {
    final nextStep = _index + 1;

    if (nextStep == 4) {
      // _model.addAnalysisToHistory({
      //   "organism": _model.name,
      //   "motifs": _model.motifs.map((m) => m.toJson()).toList(),
      //   "stages": _model.stageSelection?.selectedStages ?? [],
      //   "options": {
      //     "min": _model.analysisOptions.min,
      //     "max": _model.analysisOptions.max,
      //     "bucketSize": _model.analysisOptions.bucketSize,
      //     "alignMarker": _model.analysisOptions.alignMarker,
      //   },
      // });

      _model.removeAnalyses();

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AnalysisScreen()),
      );
      return;
    }

    if (_isStepAllowed(nextStep)) {
      setState(() => _index = nextStep);
    }
  }


  bool _isStepAllowed(int nextStep) {
    final model = GeneModel.of(context);
    switch (nextStep) {
      case 0:
      case 1:
      case 2:
      case 3:
        return model.name != null;
      case 4:
        return model.name != null && model.expectedSeriesCount > 0;
      default:
        return false;
    }
  }

  void _handleStageSelectionChanged(List<String> selectedStages) {
    _model.setSelectedStages(selectedStages);
  }

  void _handleMotifsChanged(List<Motif> motifs) {
    _model.setMotifs(motifs);
  }

  void _handleAnalysisOptionsChanged(AnalysisOptions options) {
    _model.setOptions(options);
  }

}
