import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';

class StageSubtitle extends StatelessWidget {
  const StageSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final filter = context.select<GeneModel, StageSelection?>((model) => model.filter);
    final stages = filter == null
        ? null
        : filter.stages.isEmpty
            ? 'No stages selected'
            : filter.stages.length == 1
                ? 'Analyze ${filter.stages.first} stage'
                : 'Compare ${filter.stages.length} stages';
    return filter == null
        ? const Text('Use all genes regardless of development stage')
        : filter.stages.isEmpty
            ? const Text('No stages selected')
            : Text(
                '$stages by taking ${filter.strategy.name} ${filter.selection == FilterSelection.fixed ? '${filter.count} genes' : '${(filter.percentile! * 100).round()}th percentile of genes'} based on TPM');
  }
}

class StagePanel extends StatefulWidget {
  final Function(StageSelection? filter) onChanged;

  const StagePanel({Key? key, required this.onChanged}) : super(key: key);

  @override
  State<StagePanel> createState() => _StagePanelState();
}

class _StagePanelState extends State<StagePanel> {
  final _formKey = GlobalKey<FormState>();

  List<String>? _stages;
  FilterStrategy _strategy = FilterStrategy.top;
  FilterSelection _selection = FilterSelection.fixed;
  double _percentile = 0.95;
  int _count = 3200;

  final _percentileController = TextEditingController();
  final _countController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _percentileController.text = '${(_percentile * 100).round()}';
    _countController.text = '$_count';
  }

  @override
  void dispose() {
    _percentileController.dispose();
    _countController.dispose();
    super.dispose();
  }

  StageSelection? get _filter => _stages != null && _formKey.currentState?.validate() == true
      ? StageSelection(
          stages: _stages!,
          strategy: _strategy,
          selection: _selection,
          percentile: _percentile,
          count: _count,
        )
      : null;

  @override
  Widget build(BuildContext context) {
    final keys =
        context.select<GeneModel, List<String>>((model) => model.sourceGenes?.transcriptionRates.keys.toList() ?? []);

    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final filteredGenes =
        _stages != null && _stages!.length == 1 ? sourceGenes?.filter(_filter!, _filter!.stages.first) : null;

    if (sourceGenes == null) return const Center(child: Text('Load source data first'));
    return Align(
      alignment: Alignment.topLeft,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoSlidingSegmentedControl<bool>(
              children: const {
                false: Text('Analyze all genes'),
                true: Text('Compare development stages'),
              },
              groupValue: _stages != null,
              onValueChanged: _handleCompareToggle,
            ),
            if (_stages != null) ...[
              const SizedBox(height: 16),
              Text('Choose stages to compare', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final key in keys)
                    _StageCard(
                      name: key,
                      isSelected: _stages?.contains(key) == true,
                      onToggle: (value) => _handleToggle(key, value),
                    ),
                ],
              ),
            ],
            if (_stages?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text('Choose how to select genes based on TPM in each stage',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
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
                              _count = (int.tryParse(_countController.text) ?? 0).clamp(0, sourceGenes.genes.length));
                          _handleChanged();
                        },
                        validator: (value) {
                          final parsed = int.tryParse(_countController.text);
                          if (parsed == null || parsed < 0 || parsed > sourceGenes.genes.length) {
                            return 'Enter a number between 0 and ${sourceGenes.genes.length}';
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
            ],
          ],
        ),
      ),
    );
  }

  void _handleChanged() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_stages != null) {
        widget.onChanged(StageSelection(
          stages: _stages!,
          strategy: _strategy,
          selection: _selection,
          percentile: _percentile,
          count: _count,
        ));
      } else {
        widget.onChanged(null);
      }
    }
  }

  void _handleToggle(String key, bool value) {
    setState(() {
      if (value) {
        _stages ??= [];
        _stages!.add(key);
      } else {
        _stages!.remove(key);
      }
    });
    _handleChanged();
  }

  void _handleCompareToggle(bool? value) {
    final keys = GeneModel.of(context).sourceGenes?.transcriptionRates.keys.toList() ?? [];
    setState(() {
      if (value == true) {
        _stages = List.of(keys);
      } else {
        _stages = null;
      }
    });
    _handleChanged();
  }
}

class _StageCard extends StatelessWidget {
  final String name;
  final bool isSelected;
  final Function(bool value) onToggle;
  const _StageCard({required this.name, required this.isSelected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 160,
      child: Card(
        color: isSelected ? colorScheme.primaryContainer : null,
        child: InkWell(
          onTap: () => onToggle(!isSelected),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(child: Text(truncate(name, 20), style: textTheme.titleSmall)),
                const SizedBox(height: 8),
                Checkbox(value: isSelected, onChanged: (value) => onToggle(value!))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
