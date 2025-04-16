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
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that builds the contents of the Home Screen
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final _model = GeneModel.of(context);

  late int _index = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final organismAndStagesFromBe = context.select<GeneModel, String?>((model) => model.organismAndStagesFromBe);
    // final organismAndStages =
    // context.select<GeneModel, String?>((model) => '${model.name} ${model.sourceGenes?.stageKeys.join('+')}');
    final selectedMotifs = context.select<GeneModel, List<String>>((model) => model.getSelectedMotifsNames);
    final sourceGenesLength = context.select<GeneModel, int?>((model) => model.sourceGenesLength);
    final motifs = context.select<GeneModel, List<Motif>>((model) => model.getAllMotifs);
    final filter = context.select<GeneModel, StageSelection?>((model) => model.getStageSelectionClass);
    final expectedResults = context.select<GeneModel, int>((model) => model.expectedSeriesCount);

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
                subtitle: const SourceSubtitle(),
                content: SourcePanel(onShouldClose: () => _handleStepTapped(1)),
                state: _model.isLoading
                    ? StepState.indexed
                    : sourceGenesLength == null
                    ? StepState.indexed
                    : sourceGenesLength == 0
                    ? StepState.error
                    : StepState.complete,
              ),
              Step(
                title: const Text('Genomic interval'),
                subtitle: const AnalysisOptionsSubtitle(),
                content:
                AnalysisOptionsPanel(key: ValueKey(organismAndStagesFromBe), onChanged: _handleAnalysisOptionsChanged),
                state: sourceGenesLength == null ? StepState.indexed : StepState.complete,
              ),
              Step(
                title: const Text('Analyzed motifs'),
                subtitle: const MotifSubtitle(),
                content: MotifPanel(key: ValueKey(organismAndStagesFromBe), onChanged: _handleMotifsChanged),
                state: (expectedResults > 60 && motifs.length > 5 ) || selectedMotifs.isEmpty
                    ? StepState.error
                    : motifs.isEmpty
                    ? StepState.indexed
                    : StepState.complete,
              ),
              Step(
                title: const Text('Developmental stages'),
                subtitle: const StageSubtitle(),
                content: StagePanel(key: ValueKey(organismAndStagesFromBe), onChanged: _handleStageSelectionChanged),
                state: _model.getSelectedStages.isEmpty ||
                    expectedResults > 60 && (filter?.selectedStages.length ?? 0) > 5
                    ? StepState.error
                    : StepState.indexed,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => launchUrl(Uri.parse('https://elixir-europe.org/')),
            child: Image.asset('assets/logo_elixir.png', height: 64),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  bool _isStepAllowed(int nextStep) {
    final model = GeneModel.of(context);
    switch (nextStep) {
      case 0: // source data
        return !model.isLoading;
      case 1: // analysis options
        return model.getAnalyses.isNotEmpty || model.sourceGenesLength != null;
      case 2: // motif
        return model.getAnalyses.isNotEmpty || model.sourceGenesLength != null;
      case 3: // stage
        return model.getAnalyses.isNotEmpty || model.sourceGenesLength != null;
      case 4: // analysis
        return model.getAnalyses.isNotEmpty || model.sourceGenesLength != null && model.expectedSeriesCount > 0 && model.expectedSeriesCount <= 60 && model.getSelectedMotifsNames.isNotEmpty;
      default:
        return false;
    }
  }

  void _handleStepTapped(int index) {
    if (_isStepAllowed(index)) {
      setState(() => _index = index);
    }
  }

  Future<void> _handleStepContinue() async {
    final nextStep = _index + 1;

    if (!_isStepAllowed(nextStep)) return;

    if (nextStep == 4) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AnalysisScreen()),
      );
    } else {
      setState(() => _index = nextStep);
    }
  }

  void _handleStepCancel() {
    if (_index > 0) {
      setState(() => _index -= 1);
    }
  }

  void _handleStageSelectionChanged(StageSelection? selection) {
    GeneModel.of(context).setSelectedStages(selection!.selectedStages);
  }

  void _handleMotifsChanged(List<String> motifs) {
    GeneModel.of(context).setMotifs(motifs);
  }

  void _handleAnalysisOptionsChanged(AnalysisOptions options) {
    GeneModel.of(context).setOptions(options);
  }
}
