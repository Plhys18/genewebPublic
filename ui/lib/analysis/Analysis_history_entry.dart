import 'package:geneweb/analysis/analysis_options.dart';

/// Represents a historical analysis entry from the user's past analyses
class AnalysisHistoryEntry {
  final int id;
  final String name;
  final String organismName;
  final String fileName;
  final String createdAt;
  final List<String> motifs;
  final List<String> stages;
  final Map<String, dynamic>? options;

  AnalysisHistoryEntry({
    required this.id,
    required this.name,
    required this.organismName,
    required this.fileName,
    required this.createdAt,
    required this.motifs,
    required this.stages,
    this.options,
  });

  /// Creates an AnalysisHistoryEntry from JSON
  factory AnalysisHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AnalysisHistoryEntry(
      id: json['id'],
      name: json['name'] ?? 'Unnamed Analysis',
      organismName: json['organism'] ?? '',
      fileName: json['file_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      motifs: List<String>.from(json['motifs'] ?? []),
      stages: List<String>.from(json['stages'] ?? []),
      options: json['options'],
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'file_name': fileName,
      'organism': organismName,
      'created_at': createdAt,
      'motifs': motifs,
      'stages': stages,
      'options': options,
    };
  }

  /// Gets the analysis options if available
  AnalysisOptions? getAnalysisOptions() {
    if (options == null) return null;
    return AnalysisOptions.fromJson(options!);
  }
}
