import 'package:pipeline/gff.dart';
import 'package:pipeline/organisms/base_organism.dart';

class Azolla extends BaseOrganism {
  Azolla() : super(name: 'Azolla filiculoides');

  @override
  bool get oneTranscriptPerGene => false;

  @override
  String? transcriptParser(Map<String, String> attributes) {
    // We use transcript_id instead of Name
    return attributes['Parent'];
  }

  @override
  String seqIdTransformer(String seqId) {
    return 'lcl|$seqId';
  }

  @override
  String? stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'([^.]*).tsv').firstMatch(filename)?.group(1);
    return key;
  }

  @override
  List<String> gffLinesPreprocessor(List<String> lines) {
    List<String> result = [];
    List<String> cdsLines = [];
    Strand? strand;
    for (final line in lines) {
      result.add(line);
      if (line.startsWith('#')) continue;
      final feature = GffFeature.fromLine(line, transcriptParser: transcriptParser, seqIdTransformer: seqIdTransformer);
      if (feature.type == 'mRNA') {
        strand = feature.strand;
      } else if (feature.type == 'CDS') {
        cdsLines.add(line);
      } else if (cdsLines.isNotEmpty) {
        assert(strand != null);
        final startCodonLine = _findStartCodon(strand == Strand.forward ? cdsLines.first : cdsLines.last, strand!);
        result.add(startCodonLine);
        cdsLines.clear();
      }
    }
    return result;
  }

  String _findStartCodon(String line, Strand strand) {
    final feature = GffFeature.fromLine(line, transcriptParser: transcriptParser, seqIdTransformer: seqIdTransformer);
    final parts = line.split('\t');
    final start = feature.strand == Strand.forward ? feature.start : feature.end - 2;
    final end = feature.strand == Strand.forward ? feature.start + 2 : feature.end;
    final newLine = [parts[0], parts[1], 'start_codon', start, end, parts[5], parts[6], parts[7], parts[8]];
    return newLine.join('\t');
  }
}
