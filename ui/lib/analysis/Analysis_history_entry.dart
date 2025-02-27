import 'package:geneweb/analysis/analysis_series.dart';

/// Represents a historical record of an analysis
class AnalysisHistoryEntry {
  /// The unique identifier for the history entry
  final String id;

  /// The timestamp when the analysis was run
  final DateTime timestamp;

  /// The [AnalysisSeries] that was run
  final AnalysisSeries analysisSeries;

  AnalysisHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.analysisSeries,
  });

  /// Convert to a JSON-compatible map
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'analysisSeries': analysisSeries.toJson(),
  };

  /// Create an instance from a JSON-compatible map
  factory AnalysisHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AnalysisHistoryEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      analysisSeries: AnalysisSeries.fromJson(json['analysisSeries']),
    );
  }
}
