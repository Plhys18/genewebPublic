import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis.dart';
import 'package:geneweb/analysis/distribution.dart';

class AnalysisView extends StatefulWidget {
  final Analysis analysis;

  const AnalysisView({Key? key, required this.analysis}) : super(key: key);

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: charts.LineChart(
            [
              charts.Series<DistributionDataPoint, int>(
                id: 'Distribution',
                data: widget.analysis.distribution!.dataPoints!,
                domainFn: (DistributionDataPoint point, i) => point.min,
                measureFn: (DistributionDataPoint point, _) => point.count,
                seriesColor: charts.ColorUtil.fromDartColor(widget.analysis.color),
//                colorFn: (_, __) => MaterialPalette.blue.shadeDefault,
                labelAccessorFn: (DistributionDataPoint point, _) => '<${point.min}; ${point.max})',
              ),
            ],
            primaryMeasureAxis: const charts.NumericAxisSpec(
                tickProviderSpec: charts.BasicNumericTickProviderSpec(desiredTickCount: 10)),
            behaviors: [
              charts.LinePointHighlighter(
                  selectionModelType: charts.SelectionModelType.info,
                  showHorizontalFollowLine: charts.LinePointHighlighterFollowLineType.nearest,
                  showVerticalFollowLine: charts.LinePointHighlighterFollowLineType.nearest),
              if (widget.analysis.alignMarker != null)
                charts.RangeAnnotation([
                  charts.LineAnnotationSegment(0, charts.RangeAnnotationAxisType.domain,
                      startLabel: widget.analysis.alignMarker?.toUpperCase())
                ]),
            ],
            // selectionModels: [
            //   SelectionModelConfig(
            //     changedListener: _onSelectionChanged,
            //   )
            // ],
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
