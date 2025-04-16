import 'package:faabul_color_picker/faabul_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';

import '../utilities/api_service.dart';

/// Widget that is shown just below the panel headline
class StageSubtitle extends StatelessWidget {
  const StageSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedStages =
    context.select<GeneModel, List<String>>((model) => model.getStageSelectionClass.selectedStages);
    final expectedResults = context.select<GeneModel, int>((model) => model.expectedSeriesCount);
    if (expectedResults > 60 && selectedStages.length > 5) {
      return Text('Analysis would result in $expectedResults series, reduce the number of selected stages');
    }
    if (selectedStages.isEmpty) {
      return const Text('No stages selected');
    }
    final isMain = selectedStages.contains(GeneModel.kAllStages);
    final realStages = selectedStages.where((s) => s != GeneModel.kAllStages).toList();
    List<String> texts = [];
    if (isMain) texts.add('Genome');
    if (realStages.isNotEmpty) {
      texts.add(realStages.length == 1 ? realStages.first : '${realStages.length} other stages');
    }
    return Text(texts.join(' and '));
  }
}

/// Widgewt that builds the panel with stage selection
class StagePanel extends StatefulWidget {
  final Function(StageSelection? selection) onChanged;

  const StagePanel({super.key, required this.onChanged});

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
    _updateStateFromModel();
  }

  @override
  void dispose() {
    _percentileController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StagePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.key != widget.key) {
      _updateStateFromModel();
    }
  }
  Future<void> _handleStageColorChange(String stageName, Color color) async {
    try {
      final colorHex = '#${color.value.toRadixString(16).substring(2)}';

      await ApiService().postRequest('preferences/set/', {
        'type': 'stage',
        'name': stageName,
        'color': colorHex,
        'stroke_width': 4,
      });

      final model = GeneModel.of(context);
      final allStages = List.of(model.getAllStages);

      for (int i = 0; i < allStages.length; i++) {
        if (allStages[i].stage == stageName) {

          final updatedStage = allStages[i].copyWith(color: color);
          allStages[i] = updatedStage;
          break;
        }
      }

      model.setStages(allStages);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Color preference for $stageName saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving color preference: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _updateStateFromModel() {
    final filter = GeneModel.of(context).getStageSelectionClass;
    _selectedStages = filter.selectedStages;
    _strategy = filter.strategy;
    _selection = filter.selection;
    _percentile = filter.percentile;
    _count = filter.count;
    _percentileController.text = '${((_percentile ?? 0) * 100).round()}';
    _countController.text = '$_count';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final allStagesKeys = context.select<GeneModel, List<String>>(
          (model) => model.getAllStages.map((stageObj) => stageObj.stage).toList(),
    );
    const allowFilter = true;
    final stageColors = context.select<GeneModel, Map<String, Color>>(
          (model) => model.getAllStages.asMap().map(
            (index, stageObj) => MapEntry(stageObj.stage, stageObj.color),
      ),
    );
    final sourceGenesLength = context.select<GeneModel, int?>((model) => model.sourceGenesLength);
    if (sourceGenesLength == null) return const Center(child: Text('Load source data first'));
    return Align(
      alignment: Alignment.topLeft,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GENOME', style: textTheme.titleSmall),
            Text('Distribution of the motif across the genome.', style: textTheme.bodySmall),
            const SizedBox(height: 16),
            _StageCard(
              name: 'GENOME',
              color: null,
              isSelected: _selectedStages.contains(GeneModel.kAllStages) == true,
              onToggle: (value) => _handleToggle(GeneModel.kAllStages, value),
            ),
            const SizedBox(height: 16),
            Text('DEVELOPMENTAL STAGES', style: textTheme.titleSmall),
            Text('Distribution of the motif in genes with elevated transcript levels in certain developmental stage.',
                style: textTheme.bodySmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in allStagesKeys)
                  _StageCard(
                    name: key,
                    color: stageColors[key],
                    isSelected: _selectedStages.contains(key) == true,
                    onToggle: (value) => _handleToggle(key, value),
                    onColorChange: (color) => _handleStageColorChange(key, color),
                  ),
              ],
            ),
            if (allowFilter) ...[
              const SizedBox(height: 16),
              Text('Choose the transcript level based on TPM:', style: textTheme.titleSmall),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  CupertinoSlidingSegmentedControl<FilterStrategy>(
                    children: const {
                      FilterStrategy.top: Text('Most transcribed'),
                      FilterStrategy.bottom: Text('Least transcribed'),
                    },
                    onValueChanged: (value) {
                      setState(() => _strategy = value!);
                      _handleChanged();
                    },
                    groupValue: _strategy,
                  ),
                  if (_selection == FilterSelection.percentile)
                    SizedBox(
                      width: 200,
                      child: TextFormField(
                        controller: _percentileController,
                        decoration: const InputDecoration(labelText: 'Percentile', suffix: Text('th')),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() =>
                          _percentile = ((double.tryParse(_percentileController.text) ?? 0) / 100).clamp(0, 1));
                          _handleChanged();
                        },
                        validator: (value) {
                          final parsed = double.tryParse(_percentileController.text);
                          if (parsed == null || parsed < 0 || parsed > 100) return 'Enter a number between 0 and 100';
                          return null;
                        },
                      ),
                    ),
                  if (_selection == FilterSelection.fixed)
                    SizedBox(
                      width: 200,
                      child: TextFormField(
                        controller: _countController,
                        decoration: const InputDecoration(labelText: 'Count'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() =>
                          _count = (int.tryParse(_countController.text) ?? 0).clamp(0, sourceGenesLength));
                          _handleChanged();
                        },
                        validator: (value) {
                          final parsed = int.tryParse(_countController.text);
                          if (parsed == null || parsed < 0 || parsed > sourceGenesLength) {
                            return 'Enter a number between 0 and $sourceGenesLength';
                          }
                          return null;
                        },
                      ),
                    ),
                  CupertinoSlidingSegmentedControl<FilterSelection>(
                    children: const {
                      FilterSelection.fixed: Text('Genes'),
                      FilterSelection.percentile: Text('Percentile'),
                    },
                    onValueChanged: (value) {
                      setState(() => _selection = value!);
                      _handleChanged();
                    },
                    groupValue: _selection,
                  ),
                ],
              ),
              if (_selection == FilterSelection.percentile) ...[
                const SizedBox(height: 16),
                Text(
                    'Genes included in the analysis from each stage are genes whose transcripts will represent ${((_percentile ?? 0) * 100).toStringAsFixed(2)}% of all transcripts transcribed from the total number of protein-coding genes in each selected stage.',
                    style: textTheme.labelMedium),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _handleChanged() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final updatedSelection = StageSelection(
        selectedStages: List.from(_selectedStages),
        strategy: _strategy,
        selection: _selection,
        percentile: _percentile,
        count: _count,
      );

      widget.onChanged(updatedSelection);
      GeneModel.of(context).setStageSelection(updatedSelection);
    }
  }



  void _handleToggle(String key, bool value) {
    setState(() {
      if (value) {
        _selectedStages.add(key);
      } else {
        _selectedStages.remove(key);
      }
    });
    _handleChanged();
  }

}

class _StageCard extends StatelessWidget {
  final String name;
  final Color? color;
  final bool isSelected;
  final Function(bool value) onToggle;
  final Function(Color color)? onColorChange;
  const _StageCard({required this.name, required this.color, required this.isSelected, required this.onToggle, this.onColorChange});

  @override
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = isSelected ? (color ?? Colors.grey) : (color ?? Colors.grey).withOpacity(0.4);
    final textColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return SizedBox(
      width: 160,
      height: 120,
      child: Card(
        color: backgroundColor,
        child: InkWell(
          onTap: () => onToggle(!isSelected),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  truncate(name.replaceAll('_', ' '), 60),
                  overflow: TextOverflow.fade,
                  style: textTheme.titleSmall?.copyWith(color: textColor),
                  maxLines: 3,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Checkbox(
                        value: isSelected,
                        onChanged: (value) => onToggle(value!)
                    ),
                    if (onColorChange != null)
                      InkWell(
                        onTap: () => _showColorPicker(context),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    if (onColorChange == null) return;

    showColorPickerDialog(
        context: context,
        selected: color ?? Colors.grey
    ).then((newColor) {
      if (newColor != null) {
        onColorChange!(newColor);
      }
    });
  }
}
