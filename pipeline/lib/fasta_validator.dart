import 'package:pipeline/fasta.dart';
import 'package:pipeline/gff.dart';
import 'package:pipeline/tpm.dart';

class FastaValidator {
  final Gff gff;
  final Map<String, Tpm> tpm;
  final Fasta fasta;

  FastaValidator(this.gff, this.fasta, this.tpm);

  void validate() {
    for (final gene in gff.genes) {
      final startCodon = gene.startCodon();
      List<ValidationError> errors = [];
      if (startCodon == null) {
        errors.add(ValidationError.noStartCodon('Start codon is missing'));
      }
      // check that there is a corresponding sequence
      final sequence = fasta.sequences[gene.seqid];
      if (sequence == null) {
        errors.add(ValidationError.noSequenceFound(
            'Sequence `${gene.seqid}` not found in fasta file. Got (${fasta.sequences.keys.join(', ')}).'));
      }
      if (startCodon != null && sequence != null) {
        // check that we get either ATG (forward) or CAT (reverse)
        if (startCodon.start - 1 < 0 || startCodon.end > sequence.length) {
          errors.add(ValidationError.invalidStartCodon(
              'Start codon is out of bounds. Start: ${startCodon.start}, end: ${startCodon.end}, sequence length: ${sequence.length}'));
        } else {
          final startCodonSequence = sequence.substring(startCodon.start - 1, startCodon.end);
          if (gene.strand == Strand.forward && startCodonSequence != 'ATG') {
            errors.add(ValidationError.invalidStartCodon('Expected start codon `ATG`, got `$startCodonSequence`'));
          } else if (gene.strand == Strand.reverse && startCodonSequence != 'CAT') {
            errors.add(ValidationError.invalidStartCodon('Expected start codon `CAT`, got `$startCodonSequence`'));
          } else if (gene.strand == null) {
            errors.add(ValidationError.invalidStrand('Strand is not defined'));
          }
        }
      }
      // check that we get data in TPM
      final id = gene.name;
      if (id == null) {
        errors.add(ValidationError.noIdFound('Gene name not found'));
      } else {
        for (final tpmKey in tpm.keys) {
          final genes = tpm[tpmKey]!.genes;
          if (!genes.containsKey(id)) {
            errors.add(ValidationError.noTpmDataFound('TPM data missing for stage $tpmKey'));
          } else if (genes[id]!.length != 1) {
            errors.add(ValidationError.multipleTpmDataFound(
                'Multiple TPM data (${genes[id]!.length}) found for stage $tpmKey'));
          }
        }
      }
      gene.errors = errors;
    }
  }
}

class ValidationError {
  final ValidationErrorType type;
  final String? message;
  ValidationError(this.type, this.message);

  factory ValidationError.noSequenceFound(String? message) {
    return ValidationError(ValidationErrorType.noSequenceFound, message);
  }

  factory ValidationError.noStartCodon(String? message) {
    return ValidationError(ValidationErrorType.noStartCodonFound, message);
  }

  factory ValidationError.noTpmDataFound(String? message) {
    return ValidationError(ValidationErrorType.noTpmDataFound, message);
  }

  factory ValidationError.multipleTpmDataFound(String? message) {
    return ValidationError(ValidationErrorType.multipleTpmDataFound, message);
  }

  factory ValidationError.invalidStartCodon(String? message) {
    return ValidationError(ValidationErrorType.invalidStartCodon, message);
  }

  factory ValidationError.noIdFound(String? message) {
    return ValidationError(ValidationErrorType.noIdFound, message);
  }

  factory ValidationError.invalidStrand(String? message) {
    return ValidationError(ValidationErrorType.invalidStrand, message);
  }
}

enum ValidationErrorType {
  noSequenceFound,
  noIdFound,
  noStartCodonFound,
  noFivePrimeUtrFound,
  noThreePrimeUtrFound,
  noTpmDataFound,
  multipleTpmDataFound,
  invalidStartCodon,
  invalidStrand,
}
