/// Represents a historical record of an analysis
class AnalysisHistoryEntry {
  /// The unique identifier for the history entry
  final int id;
  final String name;
  final DateTime createdAt;


  AnalysisHistoryEntry({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// Convert to a JSON-compatible map
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt.toIso8601String(),
  };

  /// Create an instance from a JSON-compatible map
  factory AnalysisHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AnalysisHistoryEntry(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
