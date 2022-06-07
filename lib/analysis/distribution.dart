import 'package:geneweb/analysis/analysis.dart';

class Distribution {
  final int min;
  final int max;
  final int interval;
  final String? alignMarker;
  final String name;

  Map<int, int>? _counts;
  late int _totalCount;

  Distribution({
    required this.min,
    required this.max,
    required this.interval,
    this.alignMarker,
    required this.name,
  });

  List<DistributionDataPoint>? get dataPoints {
    if (_counts == null) return null;
    return [
      for (var i = 0; i < (max - min) ~/ interval; i++)
        DistributionDataPoint(
            min: min + i * interval,
            max: min + (i + 1) * interval,
            value: _counts![i] ?? 0,
            percent: (_counts![i] ?? 0) / _totalCount),
    ];
  }

  void run(Analysis analysis) {
    Map<int, int> counts = {};
    for (final result in analysis.result!) {
      final position = result.position - (alignMarker != null ? result.gene.markers[alignMarker]! : 0);
      if (position < min || position > max) {
        continue;
      }
      final intervalIndex = (position - min) ~/ interval;
      counts[intervalIndex] = (counts[intervalIndex] ?? 0) + 1;
    }
    _counts = counts;
    _totalCount = analysis.result!.length;
  }
}

class DistributionDataPoint {
  final int min;
  final int max;
  final int value;
  final double percent;
  DistributionDataPoint({required this.min, required this.max, required this.value, required this.percent});

  String get label {
    return '<$min; $max)';
  }
}
