import 'package:pipeline/fasta.dart';
import 'package:pipeline/gff.dart';
import 'package:pipeline/tpm.dart';

class FastaValidator {
  final Gff gff;
  final Map<String, Tpm> tpm;
  final Fasta fasta;
  final bool useTss;
  final bool allowMissingStartCodon;

  FastaValidator(this.gff, this.fasta, this.tpm, {this.useTss = false, this.allowMissingStartCodon = false});

  Future<void> validate() async {
    for (final gene in gff.genes) {
      List<ValidationError> errors = [];

      // check that there is a corresponding sequence
      final sequence = (await fasta.sequence(gene.seqid));
      if (sequence == null) {
        errors.add(ValidationError.noSequenceFound('Sequence `${gene.seqid}` not found in fasta file.'));
      }

      // Start codon validation
      final startCodons = gene.startCodons();
      if (!allowMissingStartCodon) {
        if (startCodons.isEmpty) {
          errors.add(ValidationError.noStartCodonFound('Start codon is missing'));
        } else if (startCodons.length > 1) {
          errors.add(ValidationError.multipleStartCodonsFound('Multiple start codons found (${startCodons.length}).'));
        }
      }
      final startCodon = startCodons.isEmpty ? null : startCodons.first;
      if (startCodon != null && sequence != null) {
        // check that we get either ATG (forward) or CAT (reverse)
        if (startCodon.start - 1 < 0 || startCodon.end > sequence.sequence.length) {
          errors.add(ValidationError.invalidStartCodon(
              'Start codon is out of bounds. Start: ${startCodon.start}, end: ${startCodon.end}, sequence ${sequence.seqId} length: ${sequence.sequence.length}'));
        } else {
          final startCodonSequence = sequence.sequence.substring(startCodon.start - 1, startCodon.end);
          if (gene.strand == Strand.forward && startCodonSequence != 'ATG') {
            errors.add(ValidationError.invalidStartCodon('Expected start codon `ATG`, got `$startCodonSequence`'));
          } else if (gene.strand == Strand.reverse && startCodonSequence != 'CAT') {
            errors.add(ValidationError.invalidStartCodon('Expected start codon `CAT`, got `$startCodonSequence`'));
          } else if (gene.strand == null) {
            errors.add(ValidationError.invalidStrand('Strand is not defined'));
          }
        }
      }

      // Five-prime-UTR
      final fivePrimeUtr = gene.fivePrimeUtr();
      if (useTss && fivePrimeUtr == null) {
        errors.add(ValidationError.noFivePrimeUtrFound('Five prime UTR is missing'));
      }
      if (fivePrimeUtr != null && sequence != null) {
        // check that we get either ATG (forward) or CAT (reverse)
        if (fivePrimeUtr.start - 1 < 0 || fivePrimeUtr.end > sequence.sequence.length) {
          errors.add(ValidationError.invalidFivePrimeUtr(
              'Five prime UTR is out of bounds. Start: ${fivePrimeUtr.start}, end: ${fivePrimeUtr.end}, sequence ${sequence.seqId} length: ${sequence.sequence.length}'));
        } else {
          final fivePrimeUtrLength = fivePrimeUtr.end - fivePrimeUtr.start + 1;
          if (fivePrimeUtrLength < 1) {
            errors.add(ValidationError.invalidFivePrimeUtr('Suspicious five prime UTR length: $fivePrimeUtrLength'));
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

  factory ValidationError.noStartCodonFound(String? message) {
    return ValidationError(ValidationErrorType.noStartCodonFound, message);
  }

  factory ValidationError.multipleStartCodonsFound(String? message) {
    return ValidationError(ValidationErrorType.multipleStartCodonsFound, message);
  }

  factory ValidationError.noFivePrimeUtrFound(String? message) {
    return ValidationError(ValidationErrorType.noFivePrimeUtrFound, message);
  }

  factory ValidationError.invalidFivePrimeUtr(String? message) {
    return ValidationError(ValidationErrorType.invalidFivePrimeUtr, message);
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
  invalidStrand,
  noStartCodonFound,
  multipleStartCodonsFound,
  invalidStartCodon,
  noFivePrimeUtrFound,
  invalidFivePrimeUtr,
  noTpmDataFound,
  multipleTpmDataFound,
}
