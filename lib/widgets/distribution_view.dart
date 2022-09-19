import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/distribution.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';

class DistributionView extends StatefulWidget {
  final Map<String, Color> colors;
  final Map<String, int> stroke;
  final bool usePercentages;
  final bool groupByGenes;
  final double? verticalAxisMin;
  final double? verticalAxisMax;
  final double? horizontalAxisMin;
  final double? horizontalAxisMax;
  const DistributionView(
      {Key? key,
      required this.colors,
      required this.stroke,
      required this.usePercentages,
      required this.groupByGenes,
      required this.verticalAxisMin,
      required this.verticalAxisMax,
      required this.horizontalAxisMin,
      required this.horizontalAxisMax})
      : super(key: key);

  @override
  State<DistributionView> createState() => _DistributionViewState();
}

class _DistributionViewState extends State<DistributionView> {
  String? label;

  String get leftAxisTitle {
    if (widget.groupByGenes) {
      return widget.usePercentages ? 'Genes [%]' : 'Genes';
    } else {
      return widget.usePercentages ? 'Occurrences [%]' : 'Occurrences';
    }
  }

  String get subtitle {
    if (widget.groupByGenes) {
      return widget.usePercentages
          ? 'Count of genes with motif in given interval as a percentage of total genes selected for the analysis.'
          : 'Count of genes with motif in given interval.';
    } else {
      return widget.usePercentages
          ? 'Count of motif occurrences in given interval as a percentage of total count of motifs found in genes selected for the analysis.'
          : 'Count of motif occurrences in given interval.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final distributions = context.select<GeneModel, List<Distribution>>((model) => model.distributions);
    const defaultVerticalMin = 0;
    final defaultVerticalMax = _verticalMaximum(distributions);
    final defaultHorizontalMin = distributions.first.min;
    final defaultHorizontalMax = distributions.first.max;

    return Column(
      children: [
        Text(subtitle),
        Expanded(
          child: charts.LineChart(
            [
              for (final distribution in distributions)
                charts.Series<DistributionDataPoint, int>(
                  id: distribution.name,
                  data: distribution.dataPoints!,
                  domainFn: (DistributionDataPoint point, i) => point.min,
                  measureFn: _measureFn,
                  labelAccessorFn: (DistributionDataPoint point, _) => '<${point.min}; ${point.max})',
                  strokeWidthPxFn: (_, __) => widget.stroke[distribution.name] ?? 2,
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
              viewport: charts.NumericExtents(
                  widget.verticalAxisMin ?? defaultVerticalMin, widget.verticalAxisMax ?? defaultVerticalMax ?? 0),
            ),
            domainAxis: charts.NumericAxisSpec(
                viewport: charts.NumericExtents(widget.horizontalAxisMin ?? defaultHorizontalMin,
                    widget.horizontalAxisMax ?? defaultHorizontalMax)),
            behaviors: [
              charts.ChartTitle(leftAxisTitle, behaviorPosition: charts.BehaviorPosition.start),
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

  num? _measureFn(DistributionDataPoint point, int? index) {
    if (widget.groupByGenes) {
      return widget.usePercentages ? (point.genesPercent * 100) : point.genesCount;
    } else {
      return widget.usePercentages ? (point.percent * 100) : point.count;
    }
  }

  num? _verticalMaximum(List<Distribution> distributions) {
    num? max;
    for (final distribution in distributions) {
      for (final point in distribution.dataPoints!) {
        final value = _measureFn(point, null);
        if (max == null || value! > max) {
          max = value;
        }
      }
    }
    return max;
  }
}
