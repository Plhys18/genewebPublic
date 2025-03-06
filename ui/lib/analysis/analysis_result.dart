import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/gene.dart';

/// Holds the result of a single motif position in the gene
class AnalysisResult {
  /// The motifName it was found in
  final String motifName;

  /// The position of the motif midpoint (in the string, starting from 0)
  final num position;

  /// The raw position of the motif (in the string, starting from 0)
  final num rawPosition;

  AnalysisResult({
    required this.motifName,
    required this.rawPosition,
    required this.position,
  });

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'rawPosition': rawPosition,
    };
  }

  static AnalysisResult fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      motifName: json['name'] as String,
      rawPosition: json['rawPosition'] as num,
      position: json['position'] as num,
    );
  }
}