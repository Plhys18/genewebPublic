import 'dart:io';
import 'package:collection/collection.dart';
import 'package:pipeline/fasta.dart';
import 'package:pipeline/fasta_validator.dart';

/// Contains parsed GFF data
class Gff {
  /// Genes found in GFF
  final List<GffFeature> genes;

  Gff._({required this.genes});

  /// Creates the object from GFF file
  static Future<Gff> fromFile(
    FileSystemEntity entity, {
    required String? Function(Map<String, String> attributes) transcriptParser,
    String? Function(Map<String, String> attributes)? fallbackTranscriptParser,
    required String Function(String seqId) seqIdTransformer,
    List<String> ignoredFeatures = const ['chromosome', 'gene', 'transcript'],
    List<String> triggerFeatures = const ['mRNA'],
    List<String> Function(List<String> lines)? linesPreprocessor,
    String transcriptSeparator = '.',
  }) async {
    final file = File(entity.path);
    final rawLines = await file.readAsLines();
    final lines = linesPreprocessor?.call(rawLines) ?? rawLines;
    final List<GffFeature> genes = [];
    for (final line in lines) {
      if (line.startsWith('#')) continue;
      final feature = GffFeature.fromLine(
        line,
        transcriptParser: transcriptParser,
        fallbackTranscriptParser: fallbackTranscriptParser,
        seqIdTransformer: seqIdTransformer,
        transcriptSeparator: transcriptSeparator,
      );
      if (ignoredFeatures.contains(feature.type)) continue;
      if (triggerFeatures.contains(feature.type)) {
        genes.add(feature);
      } else {
        assert(
            genes.isNotEmpty, 'Feature $feature does not have a parent gene.');
        final parent = genes.last;
        if (parent.start > feature.start || parent.end < feature.end) {
          // print('Feature $feature does not fall into its parent bounds.');
          continue; // ignore the error
        }
        parent.features.add(feature);
      }
    }
    return Gff._(genes: genes);
  }
}

/// Single feature from GFF file
class GffFeature {
  static final kGtfRegExp = RegExp(r'^\s*([^"]+)\s+"([^"]+)"\s*$');

  final String seqId;
  final String source;
  final String type;
  final int start;
  final int end;
  final int? score;
  final Strand? strand;
  final int? phase;

  final String transcriptSeparator;

  /// Transcript Id - usually Name, ID or transcript_id
  ///
  /// See also [geneId]
  final String? transcriptId;

  /// Fallback Transcript Id - set as the .1 variant of the transcriptId
  final String? fallbackTranscriptId;

  final Map<String, String>? attributes;
  List<GffFeature> features;
  List<ValidationError>? errors;

  /// GeneId - i.e. the gene without transcript number
  ///
  /// See also [transcriptId], [transcriptNumber]
  String? get geneId {
    if (transcriptId?.contains(transcriptSeparator) != true) return transcriptId;
    final parts = transcriptId!.split(transcriptSeparator);
    return parts.take(parts.length - 1).join(transcriptSeparator);
  }

  /// Transcript number - i.e. the number after the last dot in transcriptId
  ///
  /// See also [transcriptId]
  int? get transcriptNumber {
    if (transcriptId?.contains(transcriptSeparator) != true) return null;
    final parts = transcriptId!.split(transcriptSeparator);
    return int.tryParse(parts.last);
  }

  GffFeature._({
    required this.seqId,
    required this.source,
    required this.type,
    required this.start,
    required this.end,
    this.score,
    this.strand,
    this.phase,
    this.transcriptId,
    this.fallbackTranscriptId,
    this.attributes,
    required this.features,
    this.transcriptSeparator = '.',
  });

  /// Creates the object from GFF line
  factory GffFeature.fromLine(
    String line, {
    required String? Function(Map<String, String> attributes) transcriptParser,
    String? Function(Map<String, String> attributes)? fallbackTranscriptParser,
    required String Function(String seqId) seqIdTransformer,
    String transcriptSeparator = '.',
  }) {
    final parts = line.split('\t');
    final attributes = _parseAttributes(parts[8]);
    return GffFeature._(
      seqId: seqIdTransformer(parts[0]),
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
      transcriptId: transcriptParser(attributes),
      fallbackTranscriptId: fallbackTranscriptParser?.call(attributes),
      features: [],
      transcriptSeparator: transcriptSeparator,
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
    return '$transcriptId $seqId $type $start $end ${strand?.name} ${attributes?.entries.map((e) => '${e.key}=${e.value}').join(';')}';
  }

  /// Lists all start codons defined in the GFF feature
  ///
  /// See also [validStartCodons] that will filter out invalid start codons
  List<GffFeature> startCodons() {
    return features.where((element) => element.type == 'start_codon').toList();
  }

  /// Lists all valid start codons defined in the GFF feature
  ///
  /// See also [startCodons] that will list all start codons
  List<GffFeature> validStartCodons(FastaGene sequence, Strand strand) {
    final allStartCodons = startCodons();
    final List<GffFeature> validStartCodons = [];
    final sequenceLength = sequence.sequence.length;
    for (final startCodon in allStartCodons) {
      // check that we get either ATG (forward) or CAT (reverse)
      if (startCodon.start - 1 < 0 || startCodon.end > sequenceLength) {
        continue;
      } else {
        final startCodonSequence =
            sequence.sequence.substring(startCodon.start - 1, startCodon.end);
        if (strand == Strand.forward && startCodonSequence == 'ATG') {
          validStartCodons.add(startCodon);
        } else if (strand == Strand.reverse && startCodonSequence == 'CAT') {
          validStartCodons.add(startCodon);
        }
      }
    }
    return validStartCodons;
  }

  GffFeature? startCodon() {
    return features
        .firstWhereOrNull((element) => element.type == 'start_codon');
  }

  GffFeature? transcript() {
    return features.firstWhereOrNull((element) => element.type == 'transcript');
  }

  List<GffFeature> fivePrimeUtrs() {
    return features
        .where((element) => element.type == 'five_prime_UTR')
        .toList();
  }

  GffFeature? fivePrimeUtr() {
    final candidates = fivePrimeUtrs();
    if (candidates.isEmpty) return null;
    return strand == Strand.forward ? candidates.first : candidates.last;
  }

  GffFeature? threePrimeUtr() {
    return features
        .firstWhereOrNull((element) => element.type == 'three_prime_UTR');
  }
}

enum Strand { forward, reverse }
