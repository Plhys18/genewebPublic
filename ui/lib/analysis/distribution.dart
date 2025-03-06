import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_result.dart';

import 'analysis_series.dart';
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


  late List<DistributionDataPoint> dataPoints;

  late int _totalCount;

  /// Total count of motifs
  int get totalCount => _totalCount;

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
    required int totalCount,
    required int totalGenesCount,
    required int totalGenesWithMotifCount,
    required dataPoints,
  });


  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'bucketSize': bucketSize,
      'alignMarker': alignMarker,
      'name': name,
      'color': color?.value,
      'dataPoints': dataPoints.map((dataPoint) => dataPoint.toJson()).toList(),
      'totalCount': totalCount,
      'totalGenesCount': totalGenesCount,
      'totalGenesWithMotifCount': totalGenesWithMotifCount,
    };
  }

  factory Distribution.fromJson(Map<String, dynamic> json) {
    return Distribution(
      min: json['min'] as int,
      max: json['max'] as int,
      bucketSize: json['bucket_size'] as int,
      name: json['name'] as String,
      color: AnalysisSeries.parseColor(json['color']),
      alignMarker: json['align_marker'] as String?,
      totalCount: json['total_count'] as int,
      totalGenesCount: json['total_genes_count'] as int,
      totalGenesWithMotifCount: json['total_genes_with_motif_count'] as int,
      dataPoints: (json['data_points'] as List<dynamic>)
          .map((dataPoint) => DistributionDataPoint.fromJson(dataPoint as Map<String, dynamic>))
          .toList(),
    );
  }


}