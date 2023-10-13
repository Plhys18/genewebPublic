/// Defines behavior for preset organisms.
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

  String? transcriptParser(Map<String, String> attributes) => attributes['Name'];

  String? fallbackTranscriptParser(Map<String, String> attributes) {
    final transcriptId = transcriptParser(attributes);
    if (transcriptId?.contains('.') != true) return null;
    final parts = transcriptId?.split('.');
    final candidate = '${parts?.take(parts.length - 1).join('.')}.1';

    if (candidate == transcriptId) {
      return null;
    } else {
      return candidate;
    }
  }

  String sequenceIdentifier(List<String> line) => line[0];
}
