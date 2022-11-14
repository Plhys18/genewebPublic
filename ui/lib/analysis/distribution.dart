import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_result.dart';

class Distribution {
  final int min;
  final int max;
  final int interval;
  final String? alignMarker;
  final String name;
  final Color? color;

  Map<int, int>? _counts;
  late int _totalCount;
  int get totalCount => _totalCount;

  Map<int, Set<String>>? _genes;
  late int _totalGenesCount;
  int get totalGenesCount => _totalGenesCount;
  late int _totalGenesWithMotifCount;
  int get totalGenesWithMotifCount => _totalGenesWithMotifCount;

  Distribution({
    required this.min,
    required this.max,
    required this.interval,
    this.alignMarker,
    required this.name,
    required this.color,
  });

  List<DistributionDataPoint>? get dataPoints {
    if (_counts == null || _genes == null) return null;
    return [
      for (var i = 0; i < (max - min) ~/ interval; i++)
        DistributionDataPoint(
          min: min + i * interval,
          max: min + (i + 1) * interval,
          count: _counts![i] ?? 0,
          percent: (_counts![i] ?? 0) / _totalCount,
          genes: _genes![i] ?? {},
          genesPercent: (_genes![i]?.length ?? 0) / _totalGenesCount,
        ),
    ];
  }

  void run(List<AnalysisResult> results, int totalGenesCount) {
    Map<int, int> counts = {};
    Map<int, Set<String>> geneCounts = {};
    for (final result in results) {
      final position = result.position - (alignMarker != null ? result.gene.markers[alignMarker]! : 0);
      if (position < min || position > max) {
        continue;
      }
      final intervalIndex = (position - min) ~/ interval;
      counts[intervalIndex] = (counts[intervalIndex] ?? 0) + 1;
      if (geneCounts[intervalIndex] == null) {
        geneCounts[intervalIndex] = {};
      }
      geneCounts[intervalIndex]!.add(result.gene.geneId);
    }
    _counts = counts;
    _genes = {
      for (final key in geneCounts.keys) key: geneCounts[key]!,
    };
    _totalCount = results.length;
    _totalGenesCount = totalGenesCount;
    _totalGenesWithMotifCount = results.map((result) => result.gene.geneId).toSet().length;
  }
}

class DistributionDataPoint {
  final int min;
  final int max;
  final int count;
  final double percent;
  final Set<String> genes;
  final double genesPercent;
  DistributionDataPoint(
      {required this.min,
      required this.max,
      required this.count,
      required this.percent,
      required this.genes,
      required this.genesPercent});

  int get genesCount => genes.length;

  String get label {
    return '<$min; $max)';
  }
}
