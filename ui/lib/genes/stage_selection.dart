class StageSelection {
  final List<String> stages;
  final FilterStrategy strategy;
  final FilterSelection selection;
  final double percentile;
  final int count;

  StageSelection({
    this.stages = const [],
    this.strategy = FilterStrategy.top,
    this.selection = FilterSelection.percentile,
    this.percentile = 0.9,
    this.count = 3200,
  });

  @override
  String toString() {
    return '$stages.${strategy.name}${selection == FilterSelection.fixed ? count : '${(percentile * 100).round()}th'}';
  }
}

enum FilterStrategy { top, bottom }

enum FilterSelection { fixed, percentile }
