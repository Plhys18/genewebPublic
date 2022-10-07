import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis.dart';
import 'package:geneweb/genes/gene_model.dart';

class DrillDownView extends StatefulWidget {
  const DrillDownView({Key? key}) : super(key: key);

  @override
  State<DrillDownView> createState() => _DrillDownViewState();
}

class _DrillDownViewState extends State<DrillDownView> {
  List<String> patterns = [];

  List<DrillDownResult>? _results;

  @override
  void initState() {
    super.initState();
    _update();
  }

  void _update([String? pattern]) {
    final analysis = GeneModel.of(context).analysis!;
    setState(() {
      _results = analysis.drillDown(pattern);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_results == null) return const Center(child: CircularProgressIndicator());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            child: const Text('Motif'),
            onPressed: () => _handleBreadCrumb(null),
          ),
          for (final pattern in patterns) ...[
            const Text('>'),
            TextButton(
              child: Text(pattern),
              onPressed: () => _handleBreadCrumb(pattern),
            ),
          ]
        ],
      ),
      Expanded(
          child: (_results?.length ?? 0) > 0
              ? ListView.builder(itemBuilder: _itemBuilder, shrinkWrap: true, itemCount: _results?.length ?? 0)
              : const Center(child: Text('Selected pattern cannot be drilled down any further'))),
    ]);
  }

  Widget _itemBuilder(BuildContext context, int index) {
    return ListTile(
      dense: true,
      title: Text(_results![index].pattern),
      subtitle: Text(
          'matches ${(_results![index].share * 100).round()}% of selection, (${(_results![index].shareOfAll * 100).round()}% of all results)'),
      trailing: Text(_results![index].count.toString()),
      onTap: () => _handleDrillDownDeeper(_results![index].pattern),
    );
  }

  void _handleDrillDownDeeper(String pattern) {
    setState(() {
      patterns.add(pattern);
      _update(pattern);
    });
  }

  void _handleBreadCrumb(String? pattern) {
    if (pattern == null) {
      setState(() {
        patterns = [];
        _update();
      });
    } else {
      setState(() {
        patterns = [...patterns.takeWhile((e) => e != pattern).toList(), pattern];
        _update(pattern);
      });
    }
  }
}
