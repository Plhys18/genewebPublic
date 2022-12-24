import 'dart:convert';
import 'dart:io';

class Tpm {
  final Map<String, List<TpmFeature>> genes;

  Tpm({required this.genes});

  static Future<Tpm> fromFile(FileSystemEntity entity, {String Function(List<String> line)? sequenceIdentifier}) async {
    final file = File(entity.path);
    List<String> lines;
    try {
      lines = await file.readAsLines(encoding: Utf8Codec(allowMalformed: true));
    } on FileSystemException catch (_) {
      lines = await file.readAsLines(encoding: ascii); //UTF-8 causes problems with some files
      // if it throws again, its not a valid file
    }
    final Map<String, List<TpmFeature>> sequences = {};
    TPMFileFormat format;
    final firstLine = lines.first;
    if (firstLine == 'Sequence	Aliases	Description	Avg.Expression	Min.Expression	Max.Expression') {
      format = TPMFileFormat.long;
    } else {
      format = TPMFileFormat.short;
    }

    for (final line in lines.skip(1)) {
      final feature = TpmFeature.fromLine(line, sequenceIdentifier: sequenceIdentifier, format: format);
      if (sequences.containsKey(feature.sequence)) {
        sequences[feature.sequence]!.add(feature);
      } else {
        sequences[feature.sequence] = [feature];
      }
    }
    return Tpm(genes: sequences);
  }
}

class TpmFeature {
  final String sequence;
  final String? aliases;
  final String? description;
  final double avg;
  final double? min;
  final double? max;

  TpmFeature({
    required this.sequence,
    this.aliases,
    this.description,
    required this.avg,
    this.min,
    this.max,
  });

  factory TpmFeature.fromLine(String line,
      {required String Function(List<String> line)? sequenceIdentifier, required TPMFileFormat format}) {
    if (format == TPMFileFormat.short) {
      final parts = line.split(RegExp(r'[\s,]'));
      if (parts.length != 2) throw StateError('Invalid line: $line');
      final sequence = sequenceIdentifier != null ? sequenceIdentifier(parts) : parts[0];
      return TpmFeature(
        sequence: sequence,
        avg: double.parse(parts[1]),
      );
    } else if (format == TPMFileFormat.long) {
      final parts = line.split('\t');
      if (parts.length != 6) throw StateError('Invalid line: $line');
      final sequence = sequenceIdentifier != null ? sequenceIdentifier(parts) : parts[0];
      return TpmFeature(
        sequence: sequence,
        aliases: parts[1],
        description: parts[2],
        avg: double.parse(parts[3]),
        min: double.parse(parts[4]),
        max: double.parse(parts[5]),
      );
    }
    throw StateError('Invalid format: $format');
  }

  @override
  String toString() {
    return '$sequence $min $avg $max';
  }
}

enum TPMFileFormat { long, short }
