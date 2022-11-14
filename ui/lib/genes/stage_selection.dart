class StageSelection {
  final List<String> stages;
  final FilterStrategy strategy;
  final FilterSelection selection;
  final double? percentile;
  final int? count;

  StageSelection({
    required this.stages,
    required this.strategy,
    required this.selection,
    this.percentile,
    this.count,
  });

  @override
  String toString() {
    return '$stages.${strategy.name}${selection == FilterSelection.fixed ? count! : '${(percentile! * 100).round()}th'}';
  }
}

enum FilterStrategy { top, bottom }

enum FilterSelection { fixed, percentile }
