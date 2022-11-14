import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class SourceSubtitle extends StatelessWidget {
  const SourceSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final name = context.select<GeneModel, String?>((model) => model.name);
    return sourceGenes == null
        ? const Text('Please choose an organism to analyze')
        : Text('$name, ${sourceGenes.genes.length} genes');
  }
}

class SourcePanel extends StatefulWidget {
  static const List<_Organism> kOrganisms = [
    _Organism(
        name: 'Arabidopsis thaliana', filename: 'Arabidopsis.fasta.zip', description: 'TSS, ATG, no splicing variants'),
    _Organism(
        name: 'Arabidopsis thaliana',
        filename: 'Arabidopsis-variants.fasta.zip',
        description: 'TSS, ATG, splicing variants'),
    _Organism(name: 'Ambo', filename: 'Ambo.fasta.zip', description: 'ATG'),
    _Organism(name: 'Ginkgo', filename: 'Ginkgo.fasta.zip', description: 'ATG'),
    _Organism(name: 'Marchantia', filename: 'Mp.fasta.zip', description: 'ATG'),
    _Organism(name: 'Marchantia', filename: 'Mp-with-tss.fasta.zip', description: 'ATG, TSS'),
    _Organism(name: 'Physco', filename: 'Physco.fasta.zip', description: 'ATG'),
    _Organism(name: 'Physco', filename: 'Physco-with-tss.fasta.zip', description: 'ATG, TSS'),
    _Organism(name: 'Sola', filename: 'Sola.fasta.zip', description: 'ATG'),
    _Organism(name: 'Sola', filename: 'Sola-with-tss.fasta.zip', description: 'ATG, TSS'),
    _Organism(name: 'Zea', filename: 'Zea.fasta.zip', description: 'ATG'),
    _Organism(name: 'Zea', filename: 'Zea-with-tss.fasta.zip', description: 'ATG, TSS'),
  ];

  const SourcePanel({super.key, required this.onShouldClose});

  final VoidCallback onShouldClose;

  @override
  State<SourcePanel> createState() => _SourcePanelState();
}

class _SourcePanelState extends State<SourcePanel> {
  String? _loadingMessage;
  double? _progress;

  late final _model = GeneModel.of(context);
  late final _scaffoldMessenger = ScaffoldMessenger.of(context);

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    return Align(
        alignment: Alignment.topLeft,
        child: _loadingMessage != null
            ? _buildLoadingState()
            : sourceGenes == null
                ? _buildLoad(context)
                : _buildLoadedState(context));
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_loadingMessage!),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: _progress),
      ],
    );
  }

  Widget _buildLoad(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...SourcePanel.kOrganisms.map((organism) =>
                _OrganismCard(organism: organism, onSelected: () => _handleDownloadFasta(organism.filename))),
            TextButton(onPressed: _handlePickFile, child: const Text('Open .fasta file…')),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadedState(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList>((model) => model.sourceGenes!);
    final sampleErrors = sourceGenes.errors.take(100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(onPressed: _handleClear, child: const Text('Choose another organism')),
        if (sourceGenes.errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Found ${sourceGenes.errors.length} errors during the import, listing first ${sampleErrors.length}:'),
          const SizedBox(height: 16),
          ...sampleErrors.map((e) => Text('$e')).toList(),
        ],
      ],
    );
  }

  Future<void> _handlePickFile() async {
    try {
      setState(() => _loadingMessage = 'Picking file…');
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        debugPrint('Cancelled');
        return;
      }
      final filename = result.files.single.name;
      setState(() => _loadingMessage = 'Loading $filename…');
      await Future.delayed(const Duration(milliseconds: 100));
      if (kIsWeb) {
        final data = String.fromCharCodes(result.files.single.bytes!);
        debugPrint('Loaded ${data.length} bytes');
        await _model.loadFromString(data, name: filename);
      } else {
        final path = result.files.single.path!;
        await _model.loadFromFile(path, filename: filename);
      }
      if (_model.sourceGenes!.errors.isEmpty) {
        _scaffoldMessenger.showSnackBar(SnackBar(content: Text('Imported ${_model.sourceGenes?.genes.length} genes.')));
      } else {
        _scaffoldMessenger.showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                'Imported ${_model.sourceGenes?.genes.length} genes, ${_model.sourceGenes?.errors.length} errors.')));
      }
      widget.onShouldClose();
    } catch (error) {
      _scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error loading data: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _loadingMessage = null);
    }
  }

  Future<void> _handleDownloadFasta(String filename) async {
    setState(() => _loadingMessage = 'Downloading $filename…');
    setState(() => _progress = null);
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      debugPrint('Preparing download of $filename');
      final bytes = await _downloadFile(Uri.https('temp-geneweb.s3.eu-west-1.amazonaws.com', filename));
      debugPrint('Downloaded ${bytes.length ~/ (1024 * 1024)} MB');
      if (mounted) setState(() => _loadingMessage = 'Decompressing ${bytes.length ~/ (1024 * 1024)} MB…');
      if (mounted) setState(() => _progress = 0.8);
      await Future.delayed(const Duration(milliseconds: 100));
      final archive = ZipDecoder().decodeBytes(bytes);
      debugPrint('Decoded $archive');
      final file = archive.firstWhere((f) => f.isFile); //StateError if not found
      final name = file.name.split('/').last;
      if (!name.endsWith('.fasta') && !name.endsWith('.fa')) {
        throw StateError('Expected .fasta file, got $name');
      }
      debugPrint('Found $file');
      final content = const Utf8Decoder().convert(file.content);
      debugPrint('Decoded ${content.length ~/ (1024 * 1024)} MB of data');
      if (mounted) setState(() => _loadingMessage = 'Analyzing $name (${content.length ~/ (1024 * 1024)} MB)…');
      if (mounted) setState(() => _progress = 0.9);
      await Future.delayed(const Duration(milliseconds: 100));
      await _model.loadFromString(content, name: name);
      debugPrint('Finished loading');
      if (_model.sourceGenes!.errors.isEmpty) {
        _scaffoldMessenger.showSnackBar(SnackBar(content: Text('Imported ${_model.sourceGenes?.genes.length} genes.')));
      } else {
        _scaffoldMessenger.showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                'Imported ${_model.sourceGenes?.genes.length} genes, ${_model.sourceGenes?.errors.length} errors.')));
      }
      widget.onShouldClose();
    } catch (error) {
      _scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error loading data: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _loadingMessage = null);
      if (mounted) setState(() => _progress = null);
    }
  }

  Future<List<int>> _downloadFile(Uri uri) async {
    debugPrint('Starting download $uri');
    final request = http.Request('GET', uri);
    debugPrint('Sending request');
    final http.StreamedResponse response = await http.Client().send(request);
    debugPrint('Got $response');
    final contentLength = response.contentLength;
    debugPrint('Will download $contentLength bytes');
    int downloadedBytes = 0;
    List<int> bytes = [];
    await response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        downloadedBytes += newBytes.length;
        if (mounted) setState(() => _progress = contentLength == null ? null : (downloadedBytes / contentLength * 0.8));
      },
      onDone: () async {
        debugPrint('Stream done');
      },
      onError: (e) {
        throw StateError('Error downloading file: $e');
      },
      cancelOnError: true,
    ).asFuture();
    return bytes;
  }

  void _handleClear() {
    _model.reset();
    _scaffoldMessenger
        .showSnackBar(const SnackBar(content: Text('Cleared all data. Please pick a new organism to analyze.')));
  }
}

class _Organism {
  final String name;
  final String filename;
  final String? description;

  const _Organism({required this.name, required this.filename, this.description});
}

class _OrganismCard extends StatelessWidget {
  final _Organism? organism;
  final VoidCallback onSelected;
  const _OrganismCard({required this.organism, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 240,
      child: Card(
        color: organism == null ? Theme.of(context).colorScheme.surfaceVariant : null,
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: organism == null
                ? const Center(
                    child: Text('Load local fasta file…'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(child: Text(organism!.name, style: textTheme.titleLarge)),
                      const SizedBox(height: 8),
                      FittedBox(child: Text(organism!.description ?? '', style: textTheme.caption)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
