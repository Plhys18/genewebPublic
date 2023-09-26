import 'dart:io';
import 'package:collection/collection.dart';
import 'package:pipeline/fasta_validator.dart';

class Gff {
  final List<GffFeature> genes;

  Gff({required this.genes});

  static Future<Gff> fromFile(
    FileSystemEntity entity, {
    required String? Function(Map<String, String> attributes) nameTransformer,
    required String Function(String seqId) seqIdTransformer,
    List<String> ignoredFeatures = const ['chromosome', 'gene', 'transcript'],
    List<String> triggerFeatures = const ['mRNA'],
  }) async {
    final file = File(entity.path);
    final lines = await file.readAsLines();
    final List<GffFeature> genes = [];
    for (final line in lines) {
      if (line.startsWith('#')) continue;
      final feature = GffFeature.fromLine(line, nameTransformer: nameTransformer, seqIdTransformer: seqIdTransformer);
      if (ignoredFeatures.contains(feature.type)) continue;
      if (triggerFeatures.contains(feature.type)) {
        genes.add(feature);
      } else {
        assert(genes.isNotEmpty, 'Feature $feature does not have a parent gene.');
        final parent = genes.last;
        if (parent.start > feature.start || parent.end < feature.end) {
          // print('Feature $feature does not fall into its parent bounds.');
          continue; // ignore the error
        }
        parent.features.add(feature);
      }
    }
    return Gff(genes: genes);
  }
}

class GffFeature {
  static final kGtfRegExp = RegExp(r'^\s*([^"]+)\s+"([^"]+)"\s*$');

  final String seqid;
  final String source;
  final String type;
  final int start;
  final int end;
  final int? score;
  final Strand? strand;
  final int? phase;
  final String? name;
  final Map<String, String>? attributes;
  List<GffFeature> features;
  List<ValidationError>? errors;

  GffFeature(
      {required this.seqid,
      required this.source,
      required this.type,
      required this.start,
      required this.end,
      this.score,
      this.strand,
      this.phase,
      this.name,
      this.attributes,
      required this.features});

  factory GffFeature.fromLine(
    String line, {
    required String? Function(Map<String, String> attributes) nameTransformer,
    required String Function(String seqId) seqIdTransformer,
  }) {
    final parts = line.split('\t');
    final attributes = _parseAttributes(parts[8]);
    return GffFeature(
      seqid: seqIdTransformer(parts[0]),
      source: parts[1],
      type: parts[2],
      start: int.parse(parts[3]),
      end: int.parse(parts[4]),
      score: int.tryParse(parts[5]),
      strand: parts[6] == '+'
          ? Strand.forward
          : parts[6] == '-'
              ? Strand.reverse
              : null,
      phase: int.tryParse(parts[7]),
      attributes: attributes,
      name: nameTransformer(attributes),
      features: [],
    );
  }

  static Map<String, String> _parseAttributes(String attributes) {
    final parts = attributes.split(';');
    final Map<String, String> map = {};
    for (final part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        // GFF3 format
        map[keyValue[0]] = keyValue[1];
      } else {
        // GFF2/GTF format
        final match = kGtfRegExp.firstMatch(part);
        if (match != null) {
          final key = match.group(1)!.trim();
          final value = match.group(2)!.trim();
          map[key] = value;
        }
      }
    }
    return map;
  }

  @override
  String toString() {
    return '$name $seqid $type $start $end ${strand?.name} ${attributes?.entries.map((e) => '${e.key}=${e.value}').join(';')}';
  }

  List<GffFeature> startCodons() {
    return features.where((element) => element.type == 'start_codon').toList();
  }

  GffFeature? startCodon() {
    return features.firstWhereOrNull((element) => element.type == 'start_codon');
  }

  GffFeature? transcript() {
    return features.firstWhereOrNull((element) => element.type == 'transcript');
  }

  List<GffFeature> fivePrimeUtrs() {
    return features.where((element) => element.type == 'five_prime_UTR').toList();
  }

  GffFeature? fivePrimeUtr() {
    final candidates = fivePrimeUtrs();
    if (candidates.isEmpty) return null;
    return strand == Strand.forward ? candidates.first : candidates.last;
  }

  GffFeature? threePrimeUtr() {
    return features.firstWhereOrNull((element) => element.type == 'three_prime_UTR');
  }
}

enum Strand { forward, reverse }
