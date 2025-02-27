import 'dart:convert';
import 'dart:ui';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import '../analysis/analysis_series.dart';
import '../analysis/distribution.dart';
import '../analysis/distributionDataPoints.dart';
import '../utilities/api_service.dart';

/// Widget that builds the analysis series distribution graph
class DistributionView extends StatefulWidget {
  final String? focus;
  final bool usePercentages;
  final bool groupByGenes;
  final double? verticalAxisMin;
  final double? verticalAxisMax;
  final double? horizontalAxisMin;
  final double? horizontalAxisMax;

  const DistributionView({
    super.key,
    required this.focus,
    required this.usePercentages,
    required this.groupByGenes,
    required this.verticalAxisMin,
    required this.verticalAxisMax,
    required this.horizontalAxisMin,
    required this.horizontalAxisMax,
  });

  @override
  State<DistributionView> createState() => _DistributionViewState();
}

class _DistributionViewState extends State<DistributionView> {
  String? label;
  late final _key = GlobalKey();
  List<AnalysisSeries> _analyses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalyses();
  }

  Future<void> _fetchAnalyses() async {
    print("Fetching analyses in distribution_view.dart");
    try {
      final analysesData = await ApiService().fetchAnalyses();
      setState(() {
        _analyses = analysesData.map((json) => AnalysisSeries.fromJson(json)).toList();
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = "Error loading analyses: $error";
        _loading = false;
      });
    }
  }

  String get leftAxisTitle {
    if (widget.groupByGenes) {
      return widget.usePercentages ? 'Genes [%]' : 'Genes';
    } else {
      return widget.usePercentages ? 'Occurrences [%]' : 'Occurrences';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_analyses.isEmpty) return const Center(child: Text('No series enabled'));

    final distributions = _analyses.map((a) => a.distribution!).toList();
    final defaultVerticalMin = 0;
    final defaultVerticalMax = _verticalMaximum(distributions);
    final defaultHorizontalMin = distributions.first.min;
    final defaultHorizontalMax = distributions.first.max;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(leftAxisTitle)),
            const SizedBox(width: 16.0),
            TextButton(onPressed: _handleSave, child: const Text('Save PNG')),
          ],
        ),
        Expanded(
          child: RepaintBoundary(
            key: _key,
            child: ColoredBox(
              color: Colors.white,
              child: charts.LineChart(
                [
                  for (final analysis in _analyses)
                    charts.Series<DistributionDataPoint, int>(
                      id: analysis.name,
                      data: analysis.distribution!.dataPoints!,
                      domainFn: (DistributionDataPoint point, i) => point.min,
                      measureFn: _measureFn,
                      strokeWidthPxFn: (_, __) => analysis.stroke,
                      seriesColor: charts.ColorUtil.fromDartColor(
                          widget.focus == analysis.name ? analysis.color : Colors.grey.withOpacity(0.1)),
                    ),
                ],
                animate: false,
                primaryMeasureAxis: charts.NumericAxisSpec(
                  viewport: charts.NumericExtents(
                    widget.verticalAxisMin ?? defaultVerticalMin,
                    widget.verticalAxisMax ?? defaultVerticalMax ?? 0,
                  ),
                ),
                domainAxis: charts.NumericAxisSpec(
                    viewport: charts.NumericExtents(
                        widget.horizontalAxisMin ?? defaultHorizontalMin,
                        widget.horizontalAxisMax ?? defaultHorizontalMax)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    final renderObject = _key.currentContext!.findRenderObject();
    final boundary = renderObject as RenderRepaintBoundary;
    final screenshot = await boundary.toImage(pixelRatio: 3);
    final bytes = await screenshot.toByteData(format: ImageByteFormat.png);
    if (bytes == null) return;
    await FileSaver.instance.saveFile(
      name: 'graph.png',
      bytes: bytes.buffer.asUint8List(),
      mimeType: MimeType.png,
    );
  }

  num? _measureFn(DistributionDataPoint point, int? index) {
    return widget.groupByGenes
        ? (widget.usePercentages ? point.genesPercent * 100 : point.genesCount)
        : (widget.usePercentages ? point.percent * 100 : point.count);
  }

  num? _verticalMaximum(List<Distribution> distributions) {
    return distributions.expand((d) => d.dataPoints!).map(_measureFn as Function(DistributionDataPoint e)).reduce((a, b) => a! > b! ? a : b);
  }
}
