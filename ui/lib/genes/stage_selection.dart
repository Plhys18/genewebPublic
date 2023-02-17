/// Holds data for selected [selectedStages] and TPM filtering to use (optional)
class StageSelection {
  final List<String> selectedStages;
  final FilterStrategy? strategy;
  final FilterSelection? selection;
  final double? percentile;
  final int? count;

  StageSelection({
    this.selectedStages = const [],
    this.strategy = FilterStrategy.top,
    this.selection = FilterSelection.percentile,
    this.percentile = 0.9,
    this.count = 3200,
  });

  @override
  String toString() {
    if (strategy == null || selection == null) return '${selectedStages.length} stages';
    return '${selectedStages.length} stages: ${strategy!.name} ${selection == FilterSelection.fixed ? count : '${(percentile! * 100).round()}th'}';
  }
}

enum FilterStrategy { top, bottom }

enum FilterSelection { fixed, percentile }
