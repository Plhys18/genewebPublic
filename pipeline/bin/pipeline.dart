import 'dart:io';

import 'package:csv/csv.dart';
import 'package:pipeline/fasta.dart';
import 'package:pipeline/fasta_generator.dart';
import 'package:pipeline/fasta_validator.dart';
import 'package:pipeline/gff.dart';
import 'package:pipeline/tpm.dart';

void main(List<String> arguments) async {
  if (arguments.length != 1) throw ArgumentError('Expected exactly one argument - folder with input data');
  final organism = arguments[0];

  /// Find files
  print('Searching input data for `$organism`');
  final configuration = await BatchConfiguration.fromPath('source_data/$organism');
  print(' - fasta file: `${configuration.fastaFile.path}`');
  print(' - gff file: `${configuration.gffFile.path}`');
  for (final tpmFile in configuration.tpmFiles) {
    print(' - tpm file: `${tpmFile.path}`');
  }

  /// Create output directory, if not exists
  final outputPath = 'output/$organism';
  Directory(outputPath).createSync();

  /// Load gff file
  final gff = await Gff.fromFile(configuration.gffFile);
  print('Loaded `${configuration.gffFile.path}` with ${gff.genes.length} genes');
  print(' - ${gff.genes.where((g) => g.startCodon() != null).length} with start_codon');
  print(' - ${gff.genes.where((g) => g.fivePrimeUtr() != null).length} with five_prime_UTR');
  print(' - ${gff.genes.where((g) => g.threePrimeUtr() != null).length} with three_prime_UTR');

  /// Load fasta file
  final fasta = await Fasta.fromFile(configuration.fastaFile);
  print('Loaded fasta file `${configuration.fastaFile.path}` with ${fasta.sequences.length} sequences');

  /// Load tpm files
  Map<String, Tpm> tpm = {};
  for (final tpmFile in configuration.tpmFiles) {
    final tpmKey = tpmFile.path.split('/').last;
    final tpmData = await Tpm.fromFile(tpmFile);
    tpm[tpmKey] = tpmData;
    print('Loaded tpm file `${tpmFile.path}` with ${tpmData.genes.length} genes');
  }

  /// Validate data
  final validator = FastaValidator(gff, fasta, tpm);
  validator.validate();

  /// Print validation results
  print('Validation results:');
  print(' - total genes: ${gff.genes.length}');
  print(' - valid genes: ${gff.genes.where((g) => g.errors!.isEmpty).length}');
  for (final errorType in ValidationErrorType.values) {
    print(
        ' - error ${errorType.name}: ${gff.genes.where((g) => g.errors!.where((e) => e.type == errorType).isNotEmpty).length}');
  }

  /// Save validation results;
  final validationOutputFile = File('$outputPath/errors.csv');
  final errors = [
    ['gene_id', 'errors'],
    for (final gene in gff.genes)
      if (gene.errors!.isNotEmpty) [gene.name, gene.errors!.map((e) => e.message).join(' | ')],
  ];
  validationOutputFile.writeAsStringSync(ListToCsvConverter().convert(errors));
  print('Wrote errors to `${validationOutputFile.path}`');

  /// Save resulting fasta file
  final fastaOutputFile = File('$outputPath/genes.fasta');
  final fastaSink = fastaOutputFile.openWrite(mode: FileMode.writeOnly);
  final generator = FastaGenerator(gff, fasta, tpm);
  await for (final gene in generator.toFasta(1000)) {
    fastaSink.writeln(gene.join("\n"));
  }
  fastaSink.close();
  print('Wrote fasta to `${fastaOutputFile.path}`');
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
    if (fastaFiles.length != 1) throw StateError('Expected exactly one fasta file, ${fastaFiles.length} files found.');
    final fastaFile = fastaFiles.first;
    final gffFiles = dirEntities.where((e) => e.path.endsWith('.gff'));
    if (gffFiles.length != 1) throw StateError('Expected exactly one gff file, ${gffFiles.length} files found.');
    final gffFile = gffFiles.first;
    final tpmDir = Directory('$path/TPM');
    final List<FileSystemEntity> tpmFiles = await tpmDir.list().toList();
    if (tpmFiles.isEmpty) throw StateError('Expected at least one tpm file, ${tpmFiles.length} files found.');
    return BatchConfiguration(fastaFile: fastaFile, gffFile: gffFile, tpmFiles: tpmFiles);
  }
}
