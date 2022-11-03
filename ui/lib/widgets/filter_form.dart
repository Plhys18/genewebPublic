import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/genes/filter_definition.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/output/genes_output.dart';
import 'package:provider/provider.dart';

class FilterForm extends StatefulWidget {
  final Function(StageSelection? filter) onChanged;

  const FilterForm({Key? key, required this.onChanged}) : super(key: key);

  @override
  State<FilterForm> createState() => _FilterFormState();
}

class _FilterFormState extends State<FilterForm> {
  final _formKey = GlobalKey<FormState>();

  String? _transcriptionKey;
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

  StageSelection? get _filter => _transcriptionKey != null && _formKey.currentState!.validate()
      ? StageSelection(
          key: _transcriptionKey!,
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
    final filter = _filter;
    final filteredGenes = filter != null ? sourceGenes?.filter(filter) : null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: DropdownButtonFormField<String?>(
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All stages'),
                  ),
                  for (final key in keys) DropdownMenuItem(value: key, child: Text(key)),
                ],
                onChanged: (value) {
                  setState(() => _transcriptionKey = value);
                  _handleChanged();
                },
                value: _transcriptionKey,
                decoration: const InputDecoration(labelText: 'Development stage')),
          ),
          if (_transcriptionKey != null) ...[
            const SizedBox(height: 16),
            Text('Gene selection based on $_transcriptionKey TPM:'),
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
                            _count = (int.tryParse(_countController.text) ?? 0).clamp(0, sourceGenes!.genes.length));
                        _handleChanged();
                      },
                      validator: (value) {
                        final parsed = int.tryParse(_countController.text);
                        if (parsed == null || parsed < 0 || parsed > sourceGenes!.genes.length) {
                          return 'Enter a number between 0 and ${sourceGenes!.genes.length}';
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
            if (filter != null) ...[
              const SizedBox(height: 16),
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text('Source file: ${sourceGenes?.genes.length ?? '?'} genes',
                    style: Theme.of(context).textTheme.caption!),
                const Icon(Icons.keyboard_arrow_right_sharp),
                Text('Filtered $filter', style: Theme.of(context).textTheme.caption!),
                TextButton(onPressed: _handleSave, child: const Text('Save filtered genes')),
                Text('(${filteredGenes?.genes.length ?? '?'} genes)', style: Theme.of(context).textTheme.caption!),
              ]),
            ],
          ],
        ],
      ),
    );
  }

  void _handleSave() {
    if (_filter == null) return;
    final filteredGenes = GeneModel.of(context).sourceGenes!.filter(_filter!);
    final output = GenesOutput(filteredGenes);
    final data = output.toExcel(_filter.toString());
  }

  void _handleChanged() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_transcriptionKey != null) {
        widget.onChanged(StageSelection(
          key: _transcriptionKey!,
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
}
