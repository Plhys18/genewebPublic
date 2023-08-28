import 'dart:convert';
import 'dart:math';

import 'package:pipeline/fasta.dart';
import 'package:pipeline/gff.dart';
import 'package:pipeline/tpm.dart';
import 'package:string_splitter/string_splitter.dart';
import 'package:collection/collection.dart';

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
  final bool useTss;
  final bool useAtg;
  final bool useSelfInsteadOfStartCodon;

  FastaGenerator(this.gff, this.fasta, this.tpm,
      {this.useTss = false, this.useAtg = true, this.useSelfInsteadOfStartCodon = false})
      : assert(!useTss || useAtg, 'TSS can only be used with ATG');

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
      final start = (useSelfInsteadOfStartCodon ? gene.start : gene.startCodon()!.start) - 1;
      final end = useSelfInsteadOfStartCodon ? gene.end : gene.startCodon()!.end;
      final tssDelta = !useTss
          ? null
          : gene.strand == Strand.forward
              ? start - gene.fivePrimeUtr()!.start
              : gene.fivePrimeUtr()!.end - end;
      final wholeSequence = (await fasta.sequence(gene.seqid))!.sequence; // shall not pass validation
      final before = wholeSequence.substring(max(0, start - deltaBases), start);
      final codon = wholeSequence.substring(start, end);
      final after = wholeSequence.substring(end + 1, min(wholeSequence.length, end + deltaBases + 1));
      final sequence = gene.strand == Strand.forward
          ? '$before$codon$after'
          : '${_reverse(after)}${_reverse(codon)}${_reverse(before)}';
      final atgPosition = !useAtg
          ? null
          : gene.strand == Strand.forward
              ? before.length + 1
              : after.length + 1;
      final tssPosition = useTss ? atgPosition! - tssDelta! : null;
      assert(!useTss || tssPosition != null, 'TSS not found for gene ${gene.name}');
      if (useAtg) {
        final validationCodon = sequence.substring(atgPosition! - 1, atgPosition - 1 + 3);
        assert(validationCodon == 'ATG', 'Unexpected codon: $codon');
      }
      final splitSequences = StringSplitter.chunk(sequence, 80);

      final markers = {
        if (useAtg) "atg": atgPosition,
        if (useTss) "tss": tssPosition,
      };

      final List<String> result = [
        '>${gene.name} ${gene.strand!.name.toUpperCase()}',
        ';SOURCE $gene',
        ';DESCRIPTION ${geneTpm.values.firstOrNull?.description}',
        ';TRANSCRIPTION_RATES ${jsonEncode(geneTpmJson)}',
        if (markers.isNotEmpty) ';MARKERS ${jsonEncode(markers)}',
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
