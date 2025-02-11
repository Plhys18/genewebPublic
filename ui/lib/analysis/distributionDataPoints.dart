
/// Holds a datapoint of the distribution
class DistributionDataPoint {
  /// The minimum position of the interval (inclusive)
  final int min;

  /// The maximum position of the interval (exclusive)
  final int max;

  /// The number of matches in the interval
  final int count;

  /// The percentage of matches in the interval
  final double percent;

  /// The genes with the motif in the interval
  final Set<String> genes;

  /// The percentage of genes with the motif in the interval
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
  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'count': count,
      'percent': percent,
      'genes': genes.toList(),
      'genesPercent': genesPercent,
    };
  }

  static DistributionDataPoint fromJson(Map<String, dynamic> json) {
    return DistributionDataPoint(
      min: json['min'] as int,
      max: json['max'] as int,
      count: json['count'] as int,
      percent: (json['percent'] as num).toDouble(),
      genes: Set<String>.from(json['genes'] as List),
      genesPercent: (json['genesPercent'] as num).toDouble(),
    );
  }
}

