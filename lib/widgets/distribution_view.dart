import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/distribution.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';

class DistributionView extends StatefulWidget {
  const DistributionView({Key? key}) : super(key: key);

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
          child: LineChart(
            [
              for (final distribution in distributions)
                Series<DataPoint, int>(
                  id: distribution.name,
                  data: distribution.dataPoints!,
                  domainFn: (DataPoint point, i) => point.min,
                  measureFn: (DataPoint point, _) => point.value,
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
              if (distributions.first.alignMarker != null)
                RangeAnnotation([
                  LineAnnotationSegment(0, RangeAnnotationAxisType.domain, startLabel: distributions.first.alignMarker)
                ]),
              SeriesLegend(position: BehaviorPosition.end),
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
