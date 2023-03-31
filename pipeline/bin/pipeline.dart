import 'dart:io';

import 'package:csv/csv.dart';
import 'package:pipeline/fasta.dart';
import 'package:pipeline/fasta_generator.dart';
import 'package:pipeline/fasta_validator.dart';
import 'package:pipeline/gff.dart';
import 'package:pipeline/tpm.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.length > 2) {
    throw ArgumentError('Invalid number of arguments.\n\nUsage: dart pipeline.dart <directory> [--with-tss]');
  }
  final organism = arguments[0];
  final useTss = arguments.contains('--with-tss');

  // Find files
  print('Searching input data for `$organism`. TSS: $useTss');
  final configuration = await BatchConfiguration.fromPath('source_data/$organism');
  print(' - fasta file: `${configuration.fastaFile.path}`');
  print(' - gff file: `${configuration.gffFile.path}`');
  for (final tpmFile in configuration.tpmFiles) {
    print(' - tpm file: `${tpmFile.path}`');
  }

  // Create output directory, if not exists
  final outputPath = 'output';
  Directory(outputPath).createSync();

  // Load gff file
  final ignoredFeatures =
      organism == 'Arabidopsis_small_rna' ? const ['chromosome', 'gene'] : const ['chromosome', 'gene', 'transcript'];
  final triggerFeatures = organism == 'Arabidopsis_small_rna' ? const ['transcript'] : const ['mRNA'];

  final gff = await Gff.fromFile(
    configuration.gffFile,
    ignoredFeatures: ignoredFeatures,
    triggerFeatures: triggerFeatures,
    nameTransformer: (attributes) {
      // Some source files mismatch gene names in GFF and TPM tables
      switch (organism) {
        case 'Amborella_trichopoda':
          // Convert `evm_27.model.AmTr_v1.0_scaffold00001.1` to `evm_27.TU.AmTr_v1.0_scaffold00001.1`
          final original = attributes['Name'];
          if (original == null) return null;
          final parts = original.split('.');
          return [parts[0], 'TU', ...parts.sublist(2)].join('.');
        case 'Zea_mays':
          // We use transcript_id instead of Name
          return attributes['transcript_id'];
        case 'Ginkgo_biloba':
          // We use ID instead of Name
          return attributes['ID'];
        case 'Arabidopsis_small_rna':
          return attributes['transcript_id'];
        default:
          return attributes['Name'];
      }
    },
  );
  print('Loaded `${configuration.gffFile.path}` with ${gff.genes.length} genes');
  print(' - ${gff.genes.where((g) => g.startCodon() != null).length} with start_codon');
  print(' - ${gff.genes.where((g) => g.fivePrimeUtr() != null).length} with five_prime_UTR');
  print(' - ${gff.genes.where((g) => g.threePrimeUtr() != null).length} with three_prime_UTR');

  // Load fasta file
  print('Loading `${configuration.fastaFile.path}`. This may take a while...');
  final fasta = await Fasta.load(configuration.fastaFile);
  print('Loaded fasta file `${configuration.fastaFile.path}` with ${fasta.availableSequences.length} sequences');

  // Load tpm files
  Map<String, Tpm> tpm = {};
  for (final tpmFile in configuration.tpmFiles) {
    final tpmKey = RegExp(r'^.*\/[0-9]+\.\s*([^.]*)').firstMatch(tpmFile.path)?.group(1) ??
        RegExp(r'^.*\/([^.]*)').firstMatch(tpmFile.path)?.group(1) ??
        tpmFile.path;
    try {
      final tpmData = await Tpm.fromFile(
        tpmFile,
        sequenceIdentifier: (line) {
          // Some organisms define the gene as an alias instead as a sequence
          switch (organism) {
            case 'Amborella_trichopoda': // It's in the Alias field
              return line[1];
            case 'Zea_mays':
              // We need to convert `Zm00001e000001_P001` to `Zm00001e000001_T001` used in GFF
              return line[0].replaceAll('_P', '_T');
            case 'Arabidopsis_thaliana_mitochondrion':
            case 'Arabidopsis_thaliana_chloroplast':
              // All names in GFF have .1, but TPM files do not have it
              return '${line[0]}.1';
            case 'Arabidopsis_small_rna':
              // Add .1 to TPM
              return '${line[0]}.1';
            default:
              return line[0];
          }
        },
      );
      tpm[tpmKey] = tpmData;
      print('Loaded tpm file `${tpmFile.path}` as `$tpmKey` with ${tpmData.genes.length} genes');
    } on FormatException catch (error) {
      print('Error loading tpm file `${tpmFile.path}`: ${error.message}');
    } on FileSystemException catch (error) {
      print('Error loading tpm file `${tpmFile.path}`: ${error.message}');
    } on StateError catch (error) {
      print('Error loading tpm file `${tpmFile.path}`: ${error.message}');
    }
  }

  // Validate data
  final validator =
      FastaValidator(gff, fasta, tpm, useTss: useTss, allowMissingStartCodon: organism == 'Arabidopsis_small_rna');
  await validator.validate();

  // Print validation results
  print('Validation results:');
  print(' - total genes: ${gff.genes.length}');
  print(' - valid genes: ${gff.genes.where((g) => g.errors!.isEmpty).length}');
  for (final errorType in ValidationErrorType.values) {
    print(
        ' - error ${errorType.name}: ${gff.genes.where((g) => g.errors!.where((e) => e.type == errorType).isNotEmpty).length}');
  }

  // Save validation results
  final validationOutputFile = File('$outputPath/$organism${useTss ? '-with-tss' : ''}.errors.csv');
  final errors = [
    ['gene_id', 'errors'],
    for (final gene in gff.genes)
      if (gene.errors!.isNotEmpty) [gene.name, gene.errors!.map((e) => e.message).join(' | ')],
  ];
  validationOutputFile.writeAsStringSync(ListToCsvConverter().convert(errors));
  print('Wrote errors to `${validationOutputFile.path}`');

  // Save resulting fasta file
  final fastaOutputFile = File('$outputPath/$organism${useTss ? '-with-tss' : ''}.fasta');
  final fastaSink = fastaOutputFile.openWrite(mode: FileMode.writeOnly);
  final generator = FastaGenerator(gff, fasta, tpm,
      useTss: useTss,
      useSelfInsteadOfStartCodon: organism == 'Arabidopsis_small_rna',
      useAtg: organism != 'Arabidopsis_small_rna');
  final deltaBases = organism == 'Arabidopsis_small_rna' ? 0 : 1000;
  await for (final gene in generator.toFasta(deltaBases)) {
    fastaSink.writeln(gene.join("\n"));
  }
  await fastaSink.flush();
  await fastaSink.close();
  print('Wrote fasta to `${fastaOutputFile.path}`');
  await fasta.cleanup();
  print('Cleaned up temporary files');
  exit(0);
}

class BatchConfiguration {
  final FileSystemEntity fastaFile;
  final FileSystemEntity gffFile;
  final List<FileSystemEntity> tpmFiles;
  BatchConfiguration({required this.fastaFile, required this.gffFile, required this.tpmFiles});

  static Future<BatchConfiguration> fromPath(String path) async {
    final dir = Directory(path);
    final List<FileSystemEntity> dirEntities = await dir.list().toList();
    final fastaFiles = dirEntities.where((e) => e.path.endsWith('.fa') || e.path.endsWith('.fasta'));
    if (fastaFiles.length != 1) throw StateError('Expected exactly one FASTA file, ${fastaFiles.length} files found.');
    final fastaFile = fastaFiles.first;
    final gffFiles = dirEntities.where((e) => e.path.endsWith('.gff') || e.path.endsWith('.gff3'));
    if (gffFiles.length != 1) throw StateError('Expected exactly one GFF file, ${gffFiles.length} files found.');
    final gffFile = gffFiles.first;
    final tpmDir = Directory('$path/TPM');
    final List<FileSystemEntity> tpmFiles = await tpmDir.list().toList();
    if (tpmFiles.isEmpty) throw StateError('Expected at least one TPM file, ${tpmFiles.length} files found.');
    tpmFiles.sort((a, b) => a.path.compareTo(b.path));
    return BatchConfiguration(fastaFile: fastaFile, gffFile: gffFile, tpmFiles: tpmFiles);
  }
}
