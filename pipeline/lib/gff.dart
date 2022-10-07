import 'dart:io';
import 'package:collection/collection.dart';
import 'package:pipeline/fasta_validator.dart';

class Gff {
  final List<GffFeature> genes;

  Gff({required this.genes});

  static Future<Gff> fromFile(FileSystemEntity entity) async {
    final file = File(entity.path);
    final lines = await file.readAsLines();
    final List<GffFeature> genes = [];
    for (final line in lines) {
      if (line.startsWith('#')) continue;
      final feature = GffFeature.fromLine(line);
      if (feature.type == 'gene') continue;
      if (feature.type == 'mRNA') {
        genes.add(feature);
      } else {
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
  final String seqid;
  final String source;
  final String type;
  final int start;
  final int end;
  final int? score;
  final Strand? strand;
  final int? phase;
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
      this.attributes,
      required this.features});

  factory GffFeature.fromLine(String line) {
    final parts = line.split('\t');
    return GffFeature(
      seqid: parts[0],
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
      attributes: _parseAttributes(parts[8]),
      features: [],
    );
  }

  static Map<String, String> _parseAttributes(String attributes) {
    final parts = attributes.split(';');
    final Map<String, String> map = {};
    for (final part in parts) {
      final keyValue = part.split('=');
      map[keyValue[0]] = keyValue[1];
    }
    return map;
  }

  @override
  String toString() {
    return '$name $seqid $type $start $end ${strand?.name} ${attributes?.entries.map((e) => '${e.key}=${e.value}').join(';')}';
  }

  GffFeature? startCodon() {
    return features.firstWhereOrNull((element) => element.type == 'start_codon');
  }

  GffFeature? fivePrimeUtr() {
    return features.firstWhereOrNull((element) => element.type == 'five_prime_UTR');
  }

  GffFeature? threePrimeUtr() {
    return features.firstWhereOrNull((element) => element.type == 'three_prime_UTR');
  }

  String? get name => attributes?['Name'];
}

enum Strand { forward, reverse }
