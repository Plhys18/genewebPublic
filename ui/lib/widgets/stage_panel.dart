import 'package:flutter/material.dart';
import '../genes/gene_model.dart';
import '../analysis/stage_and_color.dart';
import '../genes/stage_selection.dart';

class StagePanel extends StatefulWidget {
  final Function(List<String>) onChanged;

  const StagePanel({ super.key, required this.onChanged });

  @override
  State<StagePanel> createState() => _StagePanelState();
}

class _StagePanelState extends State<StagePanel> {
  final _formKey = GlobalKey<FormState>();

  late List<String> _selectedStages;
  late FilterStrategy? _strategy;
  late FilterSelection? _selection;
  late double? _percentile;
  late int? _count;

  final _percentileController = TextEditingController();
  final _countController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _percentileController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _handleStageToggled(String stage, bool isSelected) {
    setState(() {
      GeneModel.of(context).toggleStageSelection(stage, isSelected);
    });
    widget.onChanged(_selectedStages);
  }

  @override
  Widget build(BuildContext context) {
    final model = GeneModel.of(context);
    final allStages = model.getAllStages;
    final selectedStagesNames = model.getSelectedStages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Stages'),
        const SizedBox(height: 16.0),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: allStages.map((stage) {
            final isSelected = selectedStagesNames.contains(stage.stage);
            return _StageCard(
              stage: stage,
              isSelected: isSelected,
              onToggle: (bool value) => _handleStageToggled(stage.stage, value),
            );
          }).toList(),
        ),
      ],
    );
  }


}
class _StageCard extends StatelessWidget {
  final StageAndColor stage;
  final bool isSelected;
  final Function(bool value) onToggle;

  const _StageCard({
    required this.stage,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    print("🔹 Rendering _StageCard: ${stage.stage}, isSelected: $isSelected");

    return SizedBox(
      width: 200,
      child: Card(
        color: stage.color.withOpacity(isSelected ? 0.5 : 1.0),
        child: InkWell(
          onTap: () {
            onToggle(!isSelected);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        onToggle(value!);
                      },
                    ),
                    Expanded(
                      child: Text(stage.stage),
                    ),
                  ],
                ),
                Container(
                  width: 24,
                  height: 24,
                  color: stage.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
