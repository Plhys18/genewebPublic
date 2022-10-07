import 'dart:convert';
import 'dart:math';

import 'package:pipeline/fasta.dart';
import 'package:pipeline/gff.dart';
import 'package:pipeline/tpm.dart';
import 'package:string_splitter/string_splitter.dart';

class FastaGenerator {
  static const reverseComplements = {
    'A': 'T',
    'G': 'C',
    'C': 'G',
    'T': 'A',
    'U': 'A',
    'R': 'Y',
    'Y': 'R',
    'N': 'N',
    'W': 'W',
    'S': 'S',
    'M': 'K',
    'K': 'M',
    'B': 'V',
    'H': 'D',
    'D': 'H',
    'V': 'B',
  };

  final Gff gff;
  final Map<String, Tpm> tpm;
  final Fasta fasta;

  FastaGenerator(this.gff, this.fasta, this.tpm);

  Stream<List<String>> toFasta(int deltaBases) async* {
    for (final gene in gff.genes) {
      if (gene.errors == null) StateError('Validation must be run before generating fasta file');
      if (gene.errors!.isNotEmpty) continue;
      final geneTpm = {
        for (final tpmKey in tpm.keys) tpmKey: tpm[tpmKey]!.genes[gene.name]!.first,
      };
      final geneTpmJson = {
        for (final tpmKey in geneTpm.keys) tpmKey: geneTpm[tpmKey]!.avg,
      };
      final start = gene.startCodon()!.start - 1;
      final end = gene.startCodon()!.end;
      final wholeSequence = fasta.sequences[gene.seqid]!;
      final before = wholeSequence.substring(max(0, start - deltaBases), start);
      final codon = wholeSequence.substring(start, end);
      final after = wholeSequence.substring(end + 1, min(wholeSequence.length, end + deltaBases + 1));
      final sequence = gene.strand == Strand.forward
          ? '$before$codon$after'
          : '${_reverse(after)}${_reverse(codon)}${_reverse(before)}';
      final atgPosition = gene.strand == Strand.forward ? before.length + 1 : after.length + 1;
      final validationCodon = sequence.substring(atgPosition - 1, atgPosition - 1 + 3);
      assert(validationCodon == 'ATG', 'Unexpected codon: $codon');
      final splitSequences = StringSplitter.chunk(sequence, 80);

      final List<String> result = [
        '>${gene.name} ${gene.strand!.name.toUpperCase()}',
        ';SOURCE $gene',
        ';DESCRIPTION ${geneTpm.values.first.description}',
        ';TRANSCRIPTION_RATES ${jsonEncode(geneTpmJson)}',
        ';MARKERS {"atg":$atgPosition}',
        ...splitSequences
      ];
      yield result;
    }
  }

  String _reverse(String sequence) {
    for (int i = sequence.length - 1; i >= 0; i--) {
      if (!reverseComplements.containsKey(sequence[i])) {
        throw (StateError('No reverse complement for `${sequence[i]}`'));
      }
    }
    final result = [
      for (int i = sequence.length - 1; i >= 0; i--) reverseComplements[sequence[i]]!,
    ].join();
    return result;
  }
}
