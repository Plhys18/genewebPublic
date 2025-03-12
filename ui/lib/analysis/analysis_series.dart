import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_result.dart';
import 'package:geneweb/analysis/distribution.dart';

/// One series in the analysis
class AnalysisSeries {
  final String analysisName;

  /// The color of the series
  final Color color;

  /// The stroke width of the series
  final int stroke;

  /// Whether the series is visible
  final bool visible;

  /// The distribution of the analysis
  final Distribution distribution;

  AnalysisSeries._({
    required this.analysisName,
    required this.color,
    required this.stroke,
    this.visible = true,
    required this.distribution,
  });

  /// Returns a modified copy with optional changes
  AnalysisSeries copyWith({Color? color, int? stroke, bool? visible}) {
    return AnalysisSeries._(
      analysisName: analysisName,
      color: color ?? this.color,
      stroke: stroke ?? this.stroke,
      visible: visible ?? this.visible,
      distribution: distribution,
    );
  }

  /// Converts the object into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'motifName': analysisName,
      'color': color.value,
      'stroke': stroke,
      'visible': visible,
      'distribution': distribution.toJson(),
    };
  }

  /// Constructs an `AnalysisSeries` from JSON
  static AnalysisSeries fromJson(Map<String, dynamic> json) {
    // print("🔵 Parsing AnalysisSeries from JSON: $json");
    return AnalysisSeries._(
      analysisName: json['name'] as String? ?? "Unknown",
      color: parseColor(json['color']),
      stroke: json['stroke'] as int? ?? 4,
      visible: json['visible'] as bool? ?? true,
      distribution: Distribution?.fromJson(json['distribution']),
    );
  }

  /// Parses a color from either an `int` or `String` hex format.
  static Color parseColor(dynamic color) {
    if (color == null) return Colors.black;
    if (color is int) return Color(color);
    if (color is String && color.startsWith("#")) {
      return Color(int.parse(color.replaceFirst("#", "0xff")));
    }
    return Colors.black;
  }
}

