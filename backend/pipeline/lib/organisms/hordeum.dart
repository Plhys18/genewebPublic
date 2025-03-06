import 'package:pipeline/gff.dart';
import 'package:pipeline/organisms/base_organism.dart';

class Hordeum extends BaseOrganism {
  Hordeum() : super(name: 'Hordeum vulgare');

  @override
  String? transcriptParser(Map<String, String> attributes) {
    // We use transcript_id instead of Name
    return attributes['Parent'];
  }

  @override
  String? stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'Hordeum_([^.]*).tsv').firstMatch(filename)?.group(1);
    return key;
  }

  @override
  List<String> gffLinesPreprocessor(List<String> lines) {
    List<String> result = [];
    for (final line in lines) {
      result.add(line);
      if (line.startsWith('#')) continue;
      final feature = GffFeature.fromLine(line, transcriptParser: transcriptParser, seqIdTransformer: seqIdTransformer);
      if (feature.type == 'CDS') {
        final parts = line.split('\t');
        if (parts[8].contains('.1.V3.CDS.1;')) {
          final start = feature.strand == Strand.forward ? feature.start : feature.end - 2;
          final end = feature.strand == Strand.forward ? feature.start + 2 : feature.end;
          final newLine = [parts[0], parts[1], 'start_codon', start, end, parts[5], parts[6], parts[7], parts[8]];
          result.add(newLine.join('\t'));
        }
      }
    }
    return result;
  }
}
