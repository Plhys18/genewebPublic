import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_result.dart';

import 'distributionDataPoints.dart';

/// Holds the result of series distribution
class Distribution {
  /// The minimum position to include in the distribution
  final int min;

  /// The maximum position to include in the distribution
  final int max;

  /// The bucket size to use for the distribution
  final int bucketSize;

  /// The marker to which data is aligned (usually ATG or TSS)
  final String? alignMarker;

  /// The name of the series
  final String name;

  /// The color of the series
  final Color? color;

  Map<int, int>? _counts;

  late int _totalCount;

  /// Total count of motifs
  int get totalCount => _totalCount;

  Map<int, Set<String>>? _genes;

  late int _totalGenesCount;

  /// Total count of genes
  int get totalGenesCount => _totalGenesCount;

  late int _totalGenesWithMotifCount;

  /// Total count of genes with motif
  int get totalGenesWithMotifCount => _totalGenesWithMotifCount;

  Distribution({
    required this.min,
    required this.max,
    required this.bucketSize,
    this.alignMarker,
    required this.name,
    required this.color,
  });

  /// Returns the distribution as a list of [DistributionDataPoint]
  List<DistributionDataPoint>? get dataPoints {
    if (_counts == null || _genes == null) return null;
    return [
      for (var i = 0; i < (max - min) ~/ bucketSize; i++)
        DistributionDataPoint(
          min: min + i * bucketSize,
          max: min + (i + 1) * bucketSize,
          count: _counts![i] ?? 0,
          percent: (_counts![i] ?? 0) / _totalCount,
          genes: _genes![i] ?? {},
          genesPercent: (_genes![i]?.length ?? 0) / _totalGenesCount,
        ),
    ];
  }

  /// Calculates the distribution from the list of [results]
  void run(List<AnalysisResult> results, int totalGenesCount) {
    Map<int, int> counts = {};
    Map<int, Set<String>> geneCounts = {};

    for (final result in results) {
      final position = result.position -
          (alignMarker != null ? result.gene.markers[alignMarker]! : 0);
      if (position < min || position > max) {
        continue;
      }
      final intervalIndex = (position - min) ~/ bucketSize;
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
    _totalGenesWithMotifCount =
        results.map((result) => result.gene.geneId).toSet().length;
  }
  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'bucketSize': bucketSize,
      'alignMarker': alignMarker,
      'name': name,
      'color': color?.value,
      'dataPoints': dataPoints?.map((dp) => dp.toJson()).toList(),
      'totalCount': totalCount,
      'totalGenesCount': totalGenesCount,
      'totalGenesWithMotifCount': totalGenesWithMotifCount,
    };
  }

  static Distribution fromJson(Map<String, dynamic> json) {
    final distribution = Distribution(
      min: json['min'] as int,
      max: json['max'] as int,
      bucketSize: json['bucketSize'] as int,
      alignMarker: json['alignMarker'] as String?,
      name: json['name'] as String,
      color: json['color'] != null ? Color(json['color'] as int) : null,
    );
    return distribution;
  }
}