/// Holds data for selected stages and TPM filtering to use (optional)
class StageSelection {
  /// List of selected stages
  List<String> selectedStages;

  /// Strategy to use for filtering genes
  final FilterStrategy? strategy;

  /// Selection method to use for filtering
  final FilterSelection? selection;

  /// Percentile to use for filtering
  final double? percentile;

  /// Count to use for filtering
  final int? count;

  StageSelection({
    List<String>? selectedStages,
    this.strategy = FilterStrategy.top,
    this.selection = FilterSelection.percentile,
    this.percentile = 0.9,
    this.count = 3200,
  }) : selectedStages = selectedStages ?? [];

  @override
  String toString() {
    if (strategy == null || selection == null) {
      return '${selectedStages.length} stages';
    }
    return '${selectedStages.length} stages: ${strategy!.name} ${selection == FilterSelection.fixed ? count : '${(percentile! * 100).round()}th'}';
  }
}

enum FilterStrategy { top, bottom }

enum FilterSelection { fixed, percentile }
