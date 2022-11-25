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
    final stages = context.select<GeneModel, List<String>>((model) => model.filter?.stages ?? []);
    final expectedResults = context.select<GeneModel, int>((model) => model.expectedResults);
    if (expectedResults > 60 && stages.length > 5) {
      return Text('Analysis would result in $expectedResults series, reduce the number of selected stages');
    }
    if (stages.isEmpty) {
      return const Text('No stages selected');
    }
    final isMain = stages.contains(GeneModel.kAllStages);
    final realStages = stages.where((s) => s != GeneModel.kAllStages).toList();
    List<String> texts = [];
    if (isMain) texts.add('Genome');
    if (realStages.isNotEmpty) {
      texts.add(realStages.length == 1 ? realStages.first : '${realStages.length} other stages');
    }
    return Text(texts.join(' and '));
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

  late List<String> _stages;
  late FilterStrategy _strategy;
  late FilterSelection _selection;
  late double _percentile;
  late int _count;

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

  void _updateStateFromModel() {
    final filter = GeneModel.of(context).filter ?? StageSelection();
    _stages = filter.stages;
    _strategy = filter.strategy;
    _selection = filter.selection;
    _percentile = filter.percentile;
    _count = filter.count;
    _percentileController.text = '${(_percentile * 100).round()}';
    _countController.text = '$_count';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allStagesKeys =
        context.select<GeneModel, List<String>>((model) => model.sourceGenes?.transcriptionRates.keys.toList() ?? []);
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    if (sourceGenes == null) return const Center(child: Text('Load source data first'));
    final public = context.select<GeneModel, bool>((model) => model.publicSite);
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.topLeft,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GENOME', style: textTheme.titleSmall),
            Text('Distribution of the motif across the genome.', style: textTheme.caption),
            const SizedBox(height: 16),
            _StageCard(
              name: 'GENOME',
              isSelected: _stages.contains(GeneModel.kAllStages) == true,
              onToggle: (value) => _handleToggle(GeneModel.kAllStages, value),
            ),
            const SizedBox(height: 16),
            Text('DEVELOPMENTAL STAGES', style: textTheme.titleSmall),
            Text('Distribution of the motif in genes with elevated transcript levels in certain developmental stage.',
                style: textTheme.caption),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in allStagesKeys)
                  _StageCard(
                    name: key,
                    isSelected: _stages.contains(key) == true,
                    onToggle: (value) => _handleToggle(key, value),
                  ),
              ],
            ),
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
                        setState(
                            () => _percentile = ((double.tryParse(_percentileController.text) ?? 0) / 100).clamp(0, 1));
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
                if (!public)
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
        ),
      ),
    );
  }

  void _handleChanged() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onChanged(StageSelection(
        stages: _stages,
        strategy: _strategy,
        selection: _selection,
        percentile: _percentile,
        count: _count,
      ));
    }
  }

  void _handleToggle(String key, bool value) {
    setState(() {
      if (value) {
        _stages.add(key);
      } else {
        _stages.remove(key);
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
