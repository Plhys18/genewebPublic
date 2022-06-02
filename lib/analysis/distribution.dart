import 'package:geneweb/analysis/analysis.dart';

class Distribution {
  final int min;
  final int max;
  final int interval;
  final String? alignMarker;
  final String name;

  Map<int, int>? _counts;

  Distribution({
    required this.min,
    required this.max,
    required this.interval,
    this.alignMarker,
    required this.name,
  });

  List<DataPoint>? get dataPoints {
    if (_counts == null) return null;
    return [
      for (var i = 0; i < (max - min) ~/ interval; i++)
        DataPoint(min: min + i * interval, max: min + (i + 1) * interval, value: _counts![i] ?? 0),
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
  }
}

class DataPoint {
  final int min;
  final int max;
  final int value;
  DataPoint({required this.min, required this.max, required this.value});

  String get label {
    return '<$min; $max)';
  }
}
