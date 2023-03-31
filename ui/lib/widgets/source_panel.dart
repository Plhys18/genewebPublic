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
        ? const Text(
            'Motif positions are mapped relative to the transcription start sites (TSS) or translation start site (ATG)')
        : Text(
            '$name, ${sourceGenes.genes.length} genes${sourceGenes.mergeTranscripts == true ? ' (first transcript only)' : ''}, ${sourceGenes.stageKeys.length} stages');
  }
}

class SourcePanel extends StatefulWidget {
  static const List<Organism> kOrganisms = [
    Organism(name: 'Marchantia polymorpha', filename: 'Marchantia_polymorpha.fasta.zip', description: 'ATG'),
    Organism(
        public: true,
        name: 'Marchantia polymorpha',
        filename: 'Marchantia_polymorpha-with-tss.fasta.zip',
        description: 'ATG, TSS'),
    Organism(name: 'Physcomitrella patens', filename: 'Physcomitrella_patens.fasta.zip', description: 'ATG'),
    Organism(
        public: true,
        name: 'Physcomitrella patens',
        filename: 'Physcomitrella_patens-with-tss.fasta.zip',
        description: 'ATG, TSS'),
    Organism(
        public: true, name: 'Amborella trichopoda', filename: 'Amborella_trichopoda.fasta.zip', description: 'ATG'),
    Organism(public: true, name: 'Oryza sativa', filename: 'Oryza_sativa.fasta.zip', description: 'ATG'),
    Organism(name: 'Zea mays', filename: 'Zea_mays.fasta.zip', description: 'ATG'),
    Organism(public: true, name: 'Zea mays', filename: 'Zea_mays-with-tss.fasta.zip', description: 'ATG, TSS'),
    Organism(name: 'Solanum lycopersicum', filename: 'Solanum_lycopersicum.fasta.zip', description: 'ATG'),
    Organism(
        public: true,
        name: 'Solanum lycopersicum',
        filename: 'Solanum_lycopersicum-with-tss.fasta.zip',
        description: 'ATG, TSS'),
    Organism(public: true, name: 'Arabidopsis thaliana', filename: 'Arabidopsis.fasta.zip', description: 'ATG, TSS'),
    Organism(
        name: 'Arabidopsis thaliana',
        filename: 'Arabidopsis-variants.fasta.zip',
        description: 'TSS, ATG, all splicing variants'),
    Organism(
        name: 'Arabidopsis thaliana',
        filename: 'Arabidopsis_thaliana_mitochondrion.fasta.zip',
        description: 'Mitochondrion dataset'),
    Organism(
        name: 'Arabidopsis thaliana',
        filename: 'Arabidopsis_thaliana_chloroplast.fasta.zip',
        description: 'Chloroplast dataset'),
    Organism(
        name: 'Arabidopsis thaliana',
        filename: 'Arabidopsis_thaliana_small_rna.fasta.zip',
        description: 'Small RNA dataset'),
  ];

  const SourcePanel({super.key, required this.onShouldClose});

  final VoidCallback onShouldClose;

  @override
  State<SourcePanel> createState() => _SourcePanelState();
}

class _SourcePanelState extends State<SourcePanel> {
  String? _loadingMessage;
  double? _progress;
  bool _mergeTranscripts = false;

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
        Text(_loadingMessage!, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: _progress),
      ],
    );
  }

  Widget _buildLoad(BuildContext context) {
    final public = context.select<GeneModel, bool>((model) => model.publicSite);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.0,
          children: [
            Checkbox(value: _mergeTranscripts, onChanged: (value) => setState(() => _mergeTranscripts = value!)),
            const Text('Include only the first transcript from each gene'),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...SourcePanel.kOrganisms.where((o) => o.public || public == false).map((organism) => _OrganismCard(
                organism: organism,
                onSelected: organism.filename == null ? null : () => _handleDownloadFasta(organism.filename!))),
            if (!public) TextButton(onPressed: _handlePickFastaFile, child: const Text('Load custom .fasta file…')),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadedState(BuildContext context) {
    final public = context.select<GeneModel, bool>((model) => model.publicSite);
    final sourceGenes = context.select<GeneModel, GeneList>((model) => model.sourceGenes!);
    final sampleErrors = sourceGenes.errors.take(100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!public)
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(onPressed: _handlePickTPMFile, child: const Text('Add custom TPM (.csv)…')), //TODO
              TextButton(onPressed: _handlePickStagesFile, child: const Text('Add custom Stages (.csv)…')),
            ],
          ),
        const SizedBox(height: 16),
        TextButton(onPressed: _handleClear, child: const Text('Choose another species…')),
        if (sourceGenes.errors.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16.0),
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sampleErrors
                    .map((e) => Text('$e', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)))
                    .toList(),
                if (sourceGenes.errors.length > sampleErrors.length)
                  Text('and ${sourceGenes.errors.length - sampleErrors.length} other errors.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _handlePickFastaFile() async {
    try {
      setState(() => _loadingMessage = 'Picking file…');
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        return;
      }
      final filename = result.files.single.name;
      setState(() => _loadingMessage = 'Loading $filename…');
      await Future.delayed(const Duration(milliseconds: 100));
      if (kIsWeb) {
        final data = const Utf8Decoder().convert(result.files.single.bytes!);
        debugPrint('Loaded ${data.length} bytes');
        await _model.loadFastaFromString(data, name: filename, merge: _mergeTranscripts);
      } else {
        final path = result.files.single.path!;
        await _model.loadFastaFromFile(path, filename: filename, merge: _mergeTranscripts);
      }
      if (_model.sourceGenes!.errors.isEmpty) {
        _scaffoldMessenger.showSnackBar(SnackBar(content: Text('Imported ${_model.sourceGenes?.genes.length} genes.')));
      } else {
        _scaffoldMessenger.showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                'Imported ${_model.sourceGenes?.genes.length} genes, ${_model.sourceGenes?.errors.length} errors.')));
      }
      if (_model.publicSite) {
        widget.onShouldClose();
      }
    } catch (error) {
      _scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error loading data: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _loadingMessage = null);
    }
  }

  Future<void> _handlePickStagesFile() async {
    try {
      setState(() => _loadingMessage = 'Picking file…');
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        return;
      }
      final filename = result.files.single.name;
      setState(() => _loadingMessage = 'Loading $filename…');
      await Future.delayed(const Duration(milliseconds: 100));
      bool status;
      if (kIsWeb) {
        final data = const Utf8Decoder().convert(result.files.single.bytes!);
        debugPrint('Loaded ${data.length} bytes');
        status = _model.loadStagesFromString(data);
      } else {
        final path = result.files.single.path!;
        status = await _model.loadStagesFromFile(path);
      }

      _scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('Imported ${_model.sourceGenes?.stages?.length ?? 0} stages.')));
      if (status) {
        widget.onShouldClose();
      }
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
      final bytes =
          await _downloadFile(Uri.https(kIsWeb ? Uri.base.authority : 'golem-dev.ncbr.muni.cz', 'datasets/$filename'));
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
      await _model.loadFastaFromString(content, name: name, merge: _mergeTranscripts);
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

  Future<void> _handlePickTPMFile() async {
    try {
      setState(() => _loadingMessage = 'Picking file…');
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        return;
      }
      final filename = result.files.single.name;
      setState(() => _loadingMessage = 'Loading $filename…');
      await Future.delayed(const Duration(milliseconds: 100));
      bool status;
      if (kIsWeb) {
        final data = const Utf8Decoder().convert(result.files.single.bytes!);
        debugPrint('Loaded ${data.length} bytes');
        status = _model.loadTPMFromString(data);
      } else {
        final path = result.files.single.path!;
        status = await _model.loadTPMFromFile(path);
      }

      _scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Imported TPM rates for ${_model.sourceGenes?.stages?.length ?? 0} stages.')));
      if (status) {
        widget.onShouldClose();
      }
    } catch (error) {
      _scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error loading data: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _loadingMessage = null);
    }
  }
}

class Organism {
  final String name;
  final String? filename;
  final String? description;
  final bool public;

  const Organism({required this.name, this.filename, this.description, this.public = false});
}

class _OrganismCard extends StatelessWidget {
  final Organism organism;
  final VoidCallback? onSelected;
  const _OrganismCard({required this.organism, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 240,
      child: Card(
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                    child: Text(organism.name, style: textTheme.titleSmall!.copyWith(fontStyle: FontStyle.italic))),
                const SizedBox(height: 8),
                FittedBox(
                    child: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!organism.public) const Icon(Icons.lock, size: 12),
                    Text(organism.description ?? '', style: textTheme.bodySmall),
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
