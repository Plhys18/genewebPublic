import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis.dart';
import 'package:geneweb/analysis/distribution.dart';

class AnalysisDistribution extends StatefulWidget {
  final Analysis analysis;

  const AnalysisDistribution({Key? key, required this.analysis}) : super(key: key);

  @override
  State<AnalysisDistribution> createState() => _AnalysisDistributionState();
}

class _AnalysisDistributionState extends State<AnalysisDistribution> {
  String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LineChart(
            [
              Series<DataPoint, int>(
                id: 'Distribution',
                data: widget.analysis.distribution!.dataPoints!,
                domainFn: (DataPoint point, i) => point.min,
                measureFn: (DataPoint point, _) => point.value,
                colorFn: (_, __) => MaterialPalette.blue.shadeDefault,
                labelAccessorFn: (DataPoint point, _) => '<${point.min}; ${point.max})',
              ),
            ],
            primaryMeasureAxis:
                const NumericAxisSpec(tickProviderSpec: BasicNumericTickProviderSpec(desiredTickCount: 10)),
            behaviors: [
              LinePointHighlighter(
                  selectionModelType: SelectionModelType.info,
                  showHorizontalFollowLine: LinePointHighlighterFollowLineType.nearest,
                  showVerticalFollowLine: LinePointHighlighterFollowLineType.nearest),
              RangeAnnotation(
                  [LineAnnotationSegment(0, RangeAnnotationAxisType.domain, startLabel: widget.analysis.alignMarker)]),
            ],
            selectionModels: [
              SelectionModelConfig(
                changedListener: _onSelectionChanged,
              )
            ],
          ),
        ),
        if (label != null)
          Text(
            label!,
            style: Theme.of(context).textTheme.caption,
          ),
      ],
    );
  }

  void _onSelectionChanged(SelectionModel<num> model) {
    final key = model.selectedSeries[0].labelAccessorFn!.call(model.selectedDatum[0].index);
    final value = model.selectedSeries[0].measureFn(model.selectedDatum[0].index);
    setState(() => label = '$key: $value');
  }
}
