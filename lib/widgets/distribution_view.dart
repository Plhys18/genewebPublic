import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/distribution.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';

class DistributionView extends StatefulWidget {
  final Map<String, Color> colors;
  final bool usePercentages;
  const DistributionView({Key? key, required this.colors, required this.usePercentages}) : super(key: key);

  @override
  State<DistributionView> createState() => _DistributionViewState();
}

class _DistributionViewState extends State<DistributionView> {
  String? label;

  @override
  Widget build(BuildContext context) {
    final distributions = context.select<GeneModel, List<Distribution>>((model) => model.distributions);
    return Column(
      children: [
        Expanded(
          child: charts.LineChart(
            [
              for (final distribution in distributions)
                charts.Series<DistributionDataPoint, int>(
                  id: distribution.name,
                  data: distribution.dataPoints!,
                  domainFn: (DistributionDataPoint point, i) => point.min,
                  measureFn: (DistributionDataPoint point, _) =>
                      widget.usePercentages ? (point.percent * 100) : point.value,
                  labelAccessorFn: (DistributionDataPoint point, _) => '<${point.min}; ${point.max})',
                  colorFn: (DistributionDataPoint point, _) =>
                      charts.ColorUtil.fromDartColor(widget.colors[distribution.name] ?? Colors.grey),
                ),
            ],
            primaryMeasureAxis: charts.NumericAxisSpec(
              tickProviderSpec: charts.BasicNumericTickProviderSpec(
                desiredMinTickCount: 10,
                zeroBound: false,
                dataIsInWholeNumbers: !widget.usePercentages,
              ),
              tickFormatterSpec: charts.BasicNumericTickFormatterSpec(
                  (value) => widget.usePercentages ? '$value%' : '${value?.floor()}'),
            ),
            behaviors: [
              charts.LinePointHighlighter(
                  selectionModelType: charts.SelectionModelType.info,
                  showHorizontalFollowLine: charts.LinePointHighlighterFollowLineType.nearest,
                  showVerticalFollowLine: charts.LinePointHighlighterFollowLineType.nearest),
              if (distributions.first.alignMarker != null)
                charts.RangeAnnotation([
                  charts.LineAnnotationSegment(0, charts.RangeAnnotationAxisType.domain,
                      startLabel: distributions.first.alignMarker)
                ]),
//              charts.SeriesLegend(position: charts.BehaviorPosition.end),
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

  void _onSelectionChanged(charts.SelectionModel<num> model) {
    final key = model.selectedSeries[0].labelAccessorFn!.call(model.selectedDatum[0].index);
    final value = model.selectedSeries[0].measureFn(model.selectedDatum[0].index);
    setState(() => label = '$key: $value');
  }
}
