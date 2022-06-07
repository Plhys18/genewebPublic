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
  bool _usePercentages = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final distributions = context.select<GeneModel, List<Distribution>>((model) => model.distributions);
    if (distributions.isEmpty) {
      return const Center(child: Text('There are no distributions'));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: CupertinoSlidingSegmentedControl<bool>(
                  children: const {
                    false: Text('Counts'),
                    true: Text('Percentages'),
                  },
                  onValueChanged: (value) => setState(() => _usePercentages = value!),
                  groupValue: _usePercentages,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(height: 300, child: DistributionView(colors: _colors, usePercentages: _usePercentages)),
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
    return ListView(
      shrinkWrap: true,
      children: [
        for (final distribution in distributions)
          ListTile(
            dense: true,
            leading: ColorIndicator(
              color: _colors[distribution.name] ??= Colors.grey,
              width: 16,
              height: 16,
              borderRadius: 4,
            ),
            onTap: () => _handleColorChange(context, distribution),
            title: Text(distribution.name),
            trailing: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _handleDelete(context, distribution),
              tooltip: 'Delete',
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

  void _handleDelete(BuildContext context, Distribution distribution) {
    GeneModel.of(context).removeDistribution(distribution);
  }

  @override
  bool get wantKeepAlive => true;
}
