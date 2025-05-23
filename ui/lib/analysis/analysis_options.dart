/// Options for the analysis
class AnalysisOptions {
  /// The minimum value of the distribution
  final int min;

  /// The maximum value of the distribution
  final int max;

  /// The size of the buckets in the distribution
  final int bucketSize;

  /// The marker to align the distribution to (usually ATG or TSS)
  final String? alignMarker;

  AnalysisOptions({this.min = -1000, this.max = 1000, this.bucketSize = 30, this.alignMarker});

  AnalysisOptions copyWith({int? min, int? max, int? bucketSize, String? alignMarker}) {
    return AnalysisOptions(
      min: min ?? this.min,
      max: max ?? this.max,
      bucketSize: bucketSize ?? this.bucketSize,
      alignMarker: alignMarker ?? this.alignMarker,
    );
  }

  static AnalysisOptions? fromJson(Map<String, dynamic> map) {
    if (map.isEmpty) return null;
    return AnalysisOptions(
      min: map['min'] as int? ?? -1000,
      max: map['max'] as int? ?? 1000,
      bucketSize: map['bucketSize'] as int? ?? 30,
      alignMarker: map['alignMarker'] as String?,
    );
  }
}
