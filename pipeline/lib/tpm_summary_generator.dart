import 'package:pipeline/gff.dart';
import 'package:pipeline/tpm.dart';

class TPMSummaryGenerator {
  /// Gff data
  final Gff gff;

  /// TPM data
  final Map<String, Tpm> tpm;

  TPMSummaryGenerator(this.gff, this.tpm);

  List<List<String>> toCsv() {
    List<List<String>> result = [];

    // Header
    result.add(['Gene', ...tpm.keys]);

    // Content
    for (final gene in gff.genes) {
      // Ignore genes with validation errors
      if (gene.errors == null) StateError('Validation must be run before generating fasta file');
      if (gene.errors!.isNotEmpty) continue;

      final geneTpm = [
        for (final tpmKey in tpm.keys) tpm[tpmKey]!.genes[gene.name]!.first.avg.toString(),
      ];

      result.add([gene.name!, ...geneTpm]);
    }
    return result;
  }
}
