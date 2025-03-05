import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_result.dart';
import 'package:geneweb/analysis/distribution.dart';
/// One series in the analysis
class AnalysisSeries {
  final String name;

  /// The name of Motif that was searched
  final String motifName;

  /// The color of the series
  final Color color;

  /// The stroke width of the series
  final int stroke;

  /// Whether the series is visible
  final bool visible;

  /// The results of the analysis (i.e. the motifs found in the genes)
  final List<AnalysisResult> result;

  /// The distribution of the analysis
  final Distribution? distribution;

  AnalysisSeries._({
    required this.motifName,
    required this.name,
    required this.color,
    required this.stroke,
    this.visible = true,
    required this.result,
    this.distribution,
  });
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'motifName': motifName,
      'color': color.value,
      'stroke': stroke,
      'visible': visible,
      'result': result.map((r) => r.toJson()).toList(),
      'distribution': distribution?.toJson(),
    };
  }
  AnalysisSeries copyWith({Color? color, int? stroke, bool? visible}) {
    return AnalysisSeries._(
      name: name,
      motifName: motifName,
      color: color ?? this.color,
      stroke: stroke ?? this.stroke,
      visible: visible ?? this.visible,
      result: result,
      distribution: distribution,
    );
  }

  static AnalysisSeries fromJson(Map<String, dynamic> json) {
    return AnalysisSeries._(
      name: json['name'] as String ?? "Unknown",
      motifName: json['motifName'] as String,
      color: Color(json['color'] as int),
      stroke: json['stroke'] as int,
      visible: json['visible'] as bool,
      result: (json['result'] as List<AnalysisResult>?)
          !.map((r) => AnalysisResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      distribution: json['distribution'] != null
          ? Distribution.fromJson(json['distribution'] as Map<String, dynamic>) : null,
    );
  }


}



/// The result of a drill down
class DrillDownResult {
  final String pattern;
  final int count;
  final double? share;
  final double? shareOfAll;

  DrillDownResult(this.pattern, this.count, this.share, this.shareOfAll);
}
