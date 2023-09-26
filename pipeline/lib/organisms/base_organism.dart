abstract class BaseOrganism {
  static const kDefaultDeltaBases = 1000;

  final String name;
  final List<String> ignoredFeatures;
  final List<String> triggerFeatures;
  final bool allowMissingStartCodon;
  final bool useSelfInsteadOfStartCodon;
  final bool useAtg;
  final int deltaBases;

  BaseOrganism({
    required this.name,
    this.ignoredFeatures = const ['chromosome', 'gene', 'transcript'],
    this.triggerFeatures = const ['mRNA'],
    this.allowMissingStartCodon = false,
    this.useSelfInsteadOfStartCodon = false,
    this.useAtg = true,
    this.deltaBases = kDefaultDeltaBases,
  }) : assert(triggerFeatures.isNotEmpty);

  String? tmpKeyFromPath(String path);

  String seqIdTransformer(String seqId) => seqId;

  String? nameTransformer(Map<String, String> attributes) => attributes['Name'];

  String sequenceIdentifier(List<String> line) => line[0];
}
