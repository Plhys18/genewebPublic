import 'package:flutter/material.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/screens/analysis_screen.dart';
import 'package:geneweb/widgets/motif_panel.dart';
import 'package:geneweb/widgets/stage_panel.dart';
import 'package:geneweb/widgets/source_panel.dart';
import 'package:provider/provider.dart';

class HomePanel extends StatefulWidget {
  const HomePanel({Key? key}) : super(key: key);

  @override
  State<HomePanel> createState() => _HomePanelState();
}

class _HomePanelState extends State<HomePanel> {
  late int _index = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        // child: _buildExpansionPanelList(context),
        child: _buildStepper(context),
      ),
    );
  }

  Widget _buildStepper(BuildContext context) {
    final analysesCount = context.select<GeneModel, int>((model) => model.analyses.length);
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final motif = context.select<GeneModel, Motif?>((model) => model.motif);
    final filter = context.select<GeneModel, StageSelection?>((model) => model.filter);

    return Stepper(
      currentStep: _index,
      onStepCancel: _index > 0 ? _handleStepCancel : null,
      onStepContinue: _isStepAllowed(_index + 1) ? _handleStepContinue : null,
      onStepTapped: _handleStepTapped,
      steps: <Step>[
        Step(
          title: const Text('Source data'),
          subtitle: const SourceSubtitle(),
          content: SourcePanel(onShouldClose: () => _handleStepTapped(1)),
          state: sourceGenes == null ? StepState.indexed : StepState.complete,
        ),
        Step(
          title: const Text('Analyzed motifs'),
          subtitle: const MotifSubtitle(),
          content: MotifPanel(onChanged: _handleMotifChanged),
          state: motif == null ? StepState.indexed : StepState.complete,
        ),
        Step(
          title: const Text('Development stages'),
          subtitle: const StageSubtitle(),
          content: StagePanel(onChanged: _handleFilterChanged),
          state: filter == null
              ? StepState.indexed
              : filter.stages.isNotEmpty
                  ? StepState.complete
                  : filter.stages.isEmpty
                      ? StepState.error
                      : StepState.complete,
        ),
      ],
    );
  }

  bool _isStepAllowed(int nextStep) {
    final model = GeneModel.of(context);
    switch (nextStep) {
      case 0: // source data
        return true;
      case 1: // motif
        return model.sourceGenes != null;
      case 2: // stage
        return model.sourceGenes != null && model.motif != null;
      case 3: // analysis
        return model.sourceGenes != null &&
            model.motif != null &&
            (model.filter == null || model.filter!.stages.isNotEmpty);
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
    if (nextStep == 3) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AnalysisScreen()));
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

  void _handleMotifChanged(Motif? motif) {
    GeneModel.of(context).setMotif(motif);
  }
}
