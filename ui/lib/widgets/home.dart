import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/screens/analysis_screen.dart';
import 'package:geneweb/widgets/analysis_options_panel.dart';
import 'package:geneweb/widgets/motif_panel.dart';
import 'package:geneweb/widgets/stage_panel.dart';
import 'package:geneweb/widgets/source_panel.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final _model = GeneModel.of(context);

  late int _index = 0;

  @override
  Widget build(BuildContext context) {
    final name = context.select<GeneModel, String?>((model) => model.name);
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final motifs = context.select<GeneModel, List<Motif>>((model) => model.motifs);
    final filter = context.select<GeneModel, StageSelection?>((model) => model.filter);
    final expectedResults = context.select<GeneModel, int>((model) => model.expectedResults);

    return Stepper(
      currentStep: _index,
      onStepCancel: _index > 0 ? _handleStepCancel : null,
      onStepContinue: _isStepAllowed(_index + 1) ? _handleStepContinue : null,
      onStepTapped: _handleStepTapped,
      steps: <Step>[
        Step(
          title: const Text('Species'),
          subtitle: const SourceSubtitle(),
          content: SourcePanel(onShouldClose: () => _handleStepTapped(1)),
          state: sourceGenes == null ? StepState.indexed : StepState.complete,
        ),
        Step(
          title: const Text('Genomic interval'),
          subtitle: const AnalysisOptionsSubtitle(),
          content: AnalysisOptionsPanel(key: ValueKey(name), onChanged: _handleAnalysisOptionsChanged),
          state: sourceGenes == null ? StepState.indexed : StepState.complete,
        ),
        Step(
          title: const Text('Analyzed motifs'),
          subtitle: const MotifSubtitle(),
          content: MotifPanel(key: ValueKey(name), onChanged: _handleMotifsChanged),
          state: expectedResults > 60 && motifs.length > 5
              ? StepState.error
              : motifs.isEmpty
                  ? StepState.indexed
                  : StepState.complete,
        ),
        Step(
          title: const Text('Development stages'),
          subtitle: const StageSubtitle(),
          content: StagePanel(key: ValueKey(name), onChanged: _handleFilterChanged),
          state: filter?.stages.isEmpty == true || expectedResults > 60 && (filter?.stages.length ?? 0) > 5
              ? StepState.error
              : StepState.indexed,
        ),
      ],
    );
  }

  bool _isStepAllowed(int nextStep) {
    final model = GeneModel.of(context);
    switch (nextStep) {
      case 0: // source data
        return true;
      case 1: // analysis options
        return model.sourceGenes != null;
      case 2: // motif
        return model.sourceGenes != null;
      case 3: // stage
        return model.sourceGenes != null;
      case 4: // analysis
        return model.sourceGenes != null && model.expectedResults > 0 && model.expectedResults <= 60;
      default:
        return false;
    }
  }

  void _handleStepTapped(int index) {
    if (_isStepAllowed(index)) {
      setState(() {
        _index = index;
      });
    }
  }

  Future<void> _handleStepContinue() async {
    final nextStep = _index + 1;
    if (nextStep == 4) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AnalysisScreen()));
      _model.removeAnalyses();
      return;
    }
    if (_isStepAllowed(nextStep)) {
      setState(() {
        _index = nextStep;
      });
    }
  }

  void _handleStepCancel() {
    if (_index > 0) {
      setState(() {
        _index -= 1;
      });
    }
  }

  void _handleFilterChanged(StageSelection? filter) {
    GeneModel.of(context).setFilter(filter);
  }

  void _handleMotifsChanged(List<Motif> motifs) {
    GeneModel.of(context).setMotifs(motifs);
  }

  void _handleAnalysisOptionsChanged(AnalysisOptions options) {
    GeneModel.of(context).setOptions(options);
  }
}
