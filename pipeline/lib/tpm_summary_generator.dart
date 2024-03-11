import 'package:pipeline/fasta_validator.dart';
import 'package:pipeline/gff.dart';
import 'package:pipeline/tpm.dart';

/// Generates a file with the summary of all (valid) genes and their TPM values
class TPMSummaryGenerator {
  /// Gff data
  final Gff gff;

  /// TPM data
  final Map<String, Tpm> tpm;

  TPMSummaryGenerator(this.gff, this.tpm);

  /// Generates a CSV file contents with the summary of all (valid) genes and their TPM values
  List<List<String>> toCsv() {
    List<List<String>> result = [];

    // Header
    result.add([
      'Gene',
      'isValid',
      ...tpm.keys,
      'validationErrors',
    ]);

    // Content
    for (final gene in gff.genes) {
      // Ignore genes with validation errors
      if (gene.errors == null) StateError('Validation must be run before generating fasta file');
      if (gene.errors!.any((e) => e.type == ValidationErrorType.redundantTranscript)) continue;

      final geneTpm = [
        for (final tpmKey in tpm.keys) _formatTpm(tpm[tpmKey]?.get(gene).firstOrNull?.avg),
      ];

      // if (geneTpm.any((e) => e == '')) {
      //   print('$gene ${[
      //     for (final tpmKey in tpm.keys) '$tpmKey:${_formatTpm(tpm[tpmKey]?.get(gene).firstOrNull?.avg)}',
      //   ].join()}');
      // }

      result.add([
        gene.transcriptId!,
        '${gene.errors!.isEmpty}',
        ...geneTpm,
        gene.errors!.map((e) => e.type.name).join('|'),
      ]);
    }
    return result;
  }

  String _formatTpm(double? tpm) {
    if (tpm == null) return '';
    return tpm.toString();
  }
}
