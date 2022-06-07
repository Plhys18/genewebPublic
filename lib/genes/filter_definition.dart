class FilterDefinition {
  final String key;
  final FilterStrategy strategy;
  final FilterSelection selection;
  final double? percentile;
  final int? count;

  FilterDefinition({
    required this.key,
    required this.strategy,
    required this.selection,
    this.percentile,
    this.count,
  });

  @override
  String toString() {
    return '$key.${strategy.name}${selection == FilterSelection.fixed ? count! : '${(percentile! * 100).round()}th'}';
  }
}

enum FilterStrategy { top, bottom }

enum FilterSelection { fixed, percentile }
