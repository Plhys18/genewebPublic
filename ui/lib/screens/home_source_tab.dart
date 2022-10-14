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

class HomeSourceTab extends StatelessWidget {
  const HomeSourceTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: _Source(),
      ),
    );
  }
}

class _Source extends StatefulWidget {
  const _Source({Key? key}) : super(key: key);

  @override
  State<_Source> createState() => _SourceState();
}

class _SourceState extends State<_Source> {
  late final _model = GeneModel.of(context);
  String? _loadingMessage;
  double? _progress;

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    if (_loadingMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 32.0),
          child: SizedBox(
            width: 300.0,
            child: Column(
              children: [
                Text(_loadingMessage!),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress),
              ],
            ),
          ),
        ),
      );
    }
    return sourceGenes == null ? _buildLoad(context) : _buildLoadedState(context);
  }

  Widget _buildLoad(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Choose organism to analyze'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ElevatedButton(
                onPressed: () => _handleDownloadFasta('Arabidopsis.fasta.zip'), child: const Text('Arabidopsis')),
            ElevatedButton(onPressed: () => _handleDownloadFasta('Ambo.fasta.zip'), child: const Text('Ambo')),
            ElevatedButton(onPressed: () => _handleDownloadFasta('Ginkgo.fasta.zip'), child: const Text('Ginkgo')),
            ElevatedButton(onPressed: () => _handleDownloadFasta('Mp.fasta.zip'), child: const Text('Mp')),
            ElevatedButton(onPressed: () => _handleDownloadFasta('Physco.fasta.zip'), child: const Text('Physco')),
            ElevatedButton(onPressed: () => _handleDownloadFasta('Sola.fasta.zip'), child: const Text('Sola')),
            ElevatedButton(onPressed: () => _handleDownloadFasta('Zea.fasta.zip'), child: const Text('Zea')),
          ],
        ),
        const Divider(height: 32.0),
        const Text('... or load your own FASTA file'),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _handlePickFile, child: const Text('Choose file')),
      ],
    );
  }

  Widget _buildLoadedState(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList>((model) => model.sourceGenes!);
    final filename = context.select<GeneModel, String?>((model) => model.name);
    final sampleErrors = sourceGenes.errors.take(100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Loaded $filename with ${sourceGenes.genes.length} genes'),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _handleClear, child: const Text('Clear')),
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
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
      } else {
        debugPrint('Cancelled');
      }
      if (_model.sourceGenes!.errors.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text('Imported ${_model.sourceGenes?.genes.length} genes.')));
      } else {
        messenger.showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                'Imported ${_model.sourceGenes?.genes.length} genes, ${_model.sourceGenes?.errors.length} errors.')));
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error loading data: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _loadingMessage = null);
    }
  }

  Future<void> _handleDownloadFasta(String filename) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingMessage = 'Downloading $filename…');
    setState(() => _progress = null);
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      debugPrint('Preparing download of $filename');
      final bytes = await _downloadFile(Uri.https('temp-geneweb.s3.eu-west-1.amazonaws.com', filename));
      debugPrint('Downloaded ${bytes.length ~/ (1024 * 1024)} kB');
      setState(() => _loadingMessage = 'Decompressing ${bytes.length ~/ (1024 * 1024)} MB…');
      setState(() => _progress = 0.8);
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
      setState(() => _loadingMessage = 'Analyzing $name (${content.length ~/ (1024 * 1024)} MB)…');
      setState(() => _progress = 0.9);
      await Future.delayed(const Duration(milliseconds: 100));
      await _model.loadFromString(content, name: name);
      debugPrint('Finished loading');
      if (_model.sourceGenes!.errors.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text('Imported ${_model.sourceGenes?.genes.length} genes.')));
      } else {
        messenger.showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                'Imported ${_model.sourceGenes?.genes.length} genes, ${_model.sourceGenes?.errors.length} errors.')));
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error loading data: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _loadingMessage = null);
      setState(() => _progress = null);
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
        debugPrint('Got ${newBytes.length} bytes');
        bytes.addAll(newBytes);
        downloadedBytes += newBytes.length;
        setState(() => _progress = contentLength == null ? null : (downloadedBytes / contentLength * 0.8));
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
  }
}
