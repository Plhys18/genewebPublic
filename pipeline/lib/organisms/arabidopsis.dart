import 'package:pipeline/organisms/base_organism.dart';

abstract class Arabidopsis extends BaseOrganism {
  Arabidopsis({
    required super.name,
    super.ignoredFeatures = const ['chromosome', 'gene', 'transcript'],
    super.triggerFeatures = const ['mRNA'],
    super.allowMissingStartCodon = false,
    super.useSelfInsteadOfStartCodon = false,
    super.useAtg = true,
    super.deltaBases = BaseOrganism.kDefaultDeltaBases,
  });

  @override
  String? stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^([0-9]+\.)?\s*Arabidopsis_([^.]*)').firstMatch(filename)?.group(2);
    return key;
  }

  @override
  String seqIdTransformer(String seqId) => seqId.replaceAll('Chr', '');

  @override
  String sequenceIdentifier(List<String> line) {
    // All names in GFF have .1, but TPM files do not have it
    return '${line[0]}.1';
  }
}

class ArabidopsisSmallRna extends Arabidopsis {
  ArabidopsisSmallRna()
      : super(
          name: 'Arabidopsis thaliana (small_rna)',
          ignoredFeatures: const ['chromosome', 'gene'],
          triggerFeatures: const ['transcript'],
          allowMissingStartCodon: true,
          useSelfInsteadOfStartCodon: true,
          useAtg: false,
          deltaBases: 0,
        );

  @override
  String stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^([^.]*)').firstMatch(filename)!.group(1)!;
    return key;
  }

  @override
  String? transcriptParser(Map<String, String> attributes) {
    return attributes['transcript_id'];
  }
}

class ArabidopsisThaliana extends Arabidopsis {
  ArabidopsisThaliana() : super(name: 'Arabidopsis thaliana');
  @override
  String stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^Arabidopsis_([^.]*)').firstMatch(filename)!.group(1)!;
    return key;
  }
}

class ArabidopsisChloroplast extends Arabidopsis {
  ArabidopsisChloroplast() : super(name: 'Arabidopsis thaliana (chloroplast)');
}

class ArabidopsisMitochondrion extends Arabidopsis {
  ArabidopsisMitochondrion() : super(name: 'Arabidopsis thaliana (mitochondrion)');
}
