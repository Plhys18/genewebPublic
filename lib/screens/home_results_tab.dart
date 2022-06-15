import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/distribution.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/output/distributions_output.dart';
import 'package:geneweb/widgets/distribution_view.dart';
import 'package:provider/provider.dart';

class HomeResultsTab extends StatelessWidget {
  const HomeResultsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Align(alignment: Alignment.topLeft, child: _Results()),
      ),
    );
  }
}

class _Results extends StatefulWidget {
  const _Results({Key? key}) : super(key: key);

  @override
  State<_Results> createState() => _ResultsState();
}

class _ResultsState extends State<_Results> with AutomaticKeepAliveClientMixin {
  final Map<String, Color> _colors = {};
  final Map<String, int> _stroke = {};
  bool _usePercentages = false;
  bool _groupByGenes = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final distributions = context.select<GeneModel, List<Distribution>>((model) => model.distributions);
    if (distributions.isEmpty) {
      return const Center(child: Text('There are no results'));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoSlidingSegmentedControl<bool>(
                    children: const {
                      false: Text('Motifs'),
                      true: Text('Genes'),
                    },
                    onValueChanged: (value) => setState(() => _groupByGenes = value!),
                    groupValue: _groupByGenes,
                  ),
                  const SizedBox(width: 16),
                  CupertinoSlidingSegmentedControl<bool>(
                    children: const {
                      false: Text('Counts'),
                      true: Text('Percentages'),
                    },
                    onValueChanged: (value) => setState(() => _usePercentages = value!),
                    groupValue: _usePercentages,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                  height: 300,
                  child: DistributionView(
                    colors: _colors,
                    stroke: _stroke,
                    usePercentages: _usePercentages,
                    groupByGenes: _groupByGenes,
                  )),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                children: [
                  ElevatedButton(onPressed: () => _handleExport(context), child: const Text('Save XLSX')),
                ],
              )
            ],
          ),
        ),
        Expanded(child: _buildListView(context, distributions)),
      ],
    );
  }

  Widget _buildListView(BuildContext context, List<Distribution> distributions) {
    return ReorderableListView(
      shrinkWrap: true,
      onReorder: _handleReorder,
      children: [
        for (final distribution in distributions)
          ListTile(
            key: Key(distribution.name),
            dense: true,
            leading: IconButton(
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () => _handleColorChange(context, distribution),
              icon: ColorIndicator(
                color: _colors[distribution.name] ??= Colors.grey,
                borderRadius: 4,
              ),
            ),
            title: Text(distribution.name),
            subtitle: Text(
              '${distribution.totalGenesCount} genes (${distribution.totalGenesWithMotifCount} with motif), ${distribution.totalCount} motifs',
            ),
            trailing: Wrap(
              children: [
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _handleStrokeChange(context, distribution),
                  icon: Text(_stroke[distribution.name]?.toString() ?? '2'),
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.clear),
                  onPressed: () => _handleDelete(context, distribution),
                  tooltip: 'Delete',
                ),
                const SizedBox(width: 16)
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    final output = DistributionsOutput(GeneModel.of(context).distributions);
    final data = output.toExcel();
  }

  Future<void> _handleColorChange(BuildContext context, Distribution distribution) async {
    final color = await showColorPickerDialog(context, _colors[distribution.name] ??= Colors.grey);
    setState(() => _colors[distribution.name] = color);
  }

  Future<void> _handleStrokeChange(BuildContext context, Distribution distribution) async {
    final stroke = _stroke[distribution.name] ?? 2;
    switch (stroke) {
      case 1:
        setState(() => _stroke[distribution.name] = 2);
        break;
      case 2:
        setState(() => _stroke[distribution.name] = 4);
        break;
      case 4:
        setState(() => _stroke[distribution.name] = 1);
        break;
      default:
        setState(() => _stroke[distribution.name] = 2);
        break;
    }
  }

  void _handleDelete(BuildContext context, Distribution distribution) {
    GeneModel.of(context).removeDistribution(distribution);
  }

  @override
  bool get wantKeepAlive => true;

  void _handleReorder(int oldIndex, int newIndex) {
    final distributions = List<Distribution>.from(GeneModel.of(context).distributions);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = distributions.removeAt(oldIndex);
    distributions.insert(newIndex, item);
    GeneModel.of(context).updateDistributions(distributions);
  }
}
