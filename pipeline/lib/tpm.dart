import 'dart:io';

class Tpm {
  final Map<String, List<TpmFeature>> genes;

  Tpm({required this.genes});

  static Future<Tpm> fromFile(FileSystemEntity entity) async {
    final file = File(entity.path);
    final lines = await file.readAsLines();
    final Map<String, List<TpmFeature>> sequences = {};

    final firstLine = lines.first;
    if (firstLine != 'Sequence	Aliases	Description	Avg.Expression	Min.Expression	Max.Expression') {
      throw StateError('Invalid header line: $firstLine');
    }

    for (final line in lines.skip(1)) {
      final feature = TpmFeature.fromLine(line);
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
  final String aliases;
  final String description;
  final double avg;
  final double min;
  final double max;

  TpmFeature({
    required this.sequence,
    required this.aliases,
    required this.description,
    required this.avg,
    required this.min,
    required this.max,
  });

  factory TpmFeature.fromLine(String line) {
    final parts = line.split('\t');
    return TpmFeature(
      sequence: parts[0],
      aliases: parts[1],
      description: parts[2],
      avg: double.parse(parts[3]),
      min: double.parse(parts[4]),
      max: double.parse(parts[5]),
    );
  }

  @override
  String toString() {
    return '$sequence $min $avg $max';
  }
}
