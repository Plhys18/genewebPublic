class FilterDefinition {
  final String? transcriptionKey;
  final FilterStrategy? strategy;

  FilterDefinition({
    this.transcriptionKey,
    this.strategy,
  });

  String get label {
    if (transcriptionKey == null || strategy == null) {
      return 'All';
    }
    return '$transcriptionKey.${strategy!.name}';
  }
}

enum FilterStrategy { top3200, bottom3200, top95th, bottom5th }
