import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/organism.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

/// Widget shown just below the panel headline
class SourceSubtitle extends StatelessWidget {
  const SourceSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final sourceGenes =
        context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    final name = context.select<GeneModel, String?>((model) => model.name);
    return sourceGenes == null
        ? const Text(
            'Motif positions are mapped relative to the transcription start sites (TSS) or translation start site (ATG)')
        : Wrap(
            children: [
              Text('$name',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
              Text(
                  ', ${sourceGenes.genes.length} genes, ${sourceGenes.stageKeys.length} stages'),
            ],
          );
  }
}

/// Widget that builds the panel with organism selection
class SourcePanel extends StatefulWidget {
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
    final sourceGenes =
        context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
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

  Future<List<Organism>> fetchOrganismNames() async {
    final response = await http.get(Uri.parse("http://localhost:8000/api/organisms/"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data["organisms"])
          .map((name) => Organism(name: name, filename: "$name.fasta"))
          .toList();
    } else {
      throw Exception("Failed to fetch organism names");
    }
  }

  Widget _buildLoad(BuildContext context) {

    return FutureBuilder<List<Organism>>(
      future: fetchOrganismNames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text("Error loading organisms: ${snapshot.error}");
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("No organisms available");
        }

        final organisms = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: organisms.map((organism) => _OrganismCard(
                organism: organism,
                onSelected: () => _handleSelectOrganism(organism),
              )).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadedState(BuildContext context) {
    final publicSite =
        context.select<GeneModel, bool>((model) => model.publicSite);
    final sourceGenes =
        context.select<GeneModel, GeneList>((model) => model.sourceGenes!);
    final sampleErrors = sourceGenes.errors.take(100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!publicSite)
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                  onPressed: _handlePickTPMFile,
                  child: const Text('Add custom TPM (.csv)…')), //TODO
              TextButton(
                  onPressed: _handlePickStagesFile,
                  child: const Text('Add custom Stages (.csv)…')),
            ],
          ),
        const SizedBox(height: 16),
        TextButton(
            onPressed: _handleClear,
            child: const Text('Choose another species…')),
        if (sourceGenes.errors.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16.0),
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sampleErrors.map((e) => Text('$e',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onErrorContainer))),
                if (sourceGenes.errors.length > sampleErrors.length)
                  Text(
                      'and ${sourceGenes.errors.length - sampleErrors.length} other errors.',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onErrorContainer)),
              ],
            ),
          ),
      ],
    );
  }
  Future<void> _handleSelectOrganism(Organism organism) async {
    try {
      setState(() => _loadingMessage = "Setting active organism: ${organism.name}…");

      final model = GeneModel.of(context);
      await model.loadOrganismFromBackend(organism.name);

      _scaffoldMessenger.showSnackBar(SnackBar(
        content: Text("Now working with ${organism.name}."),
      ));

      widget.onShouldClose();
    } catch (error) {
      _scaffoldMessenger.showSnackBar(SnackBar(
        content: Text("Error selecting organism: $error"),
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

      _scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(
              'Imported ${_model.sourceGenes?.stages?.length ?? 0} stages.')));
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

  void _handleClear() {
    //TODO this needs to be implemented and readded
    // _model.reset();
    _scaffoldMessenger.showSnackBar(const SnackBar(
        content:
            Text('Cleared all data. Please pick a new organism to analyze.')));
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
        debugPrint('Downloaded ${data.length ~/ (1024 * 1024)} MB');
        status = _model.loadTPMFromString(data);
      } else {
        final path = result.files.single.path!;
        status = await _model.loadTPMFromFile(path);
      }

      _scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(
              'Imported TPM rates for ${_model.sourceGenes?.stages?.length ?? 0} stages.')));
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
                    child: Text(organism.name,
                        style: textTheme.titleSmall!
                            .copyWith(fontStyle: FontStyle.italic))),
                const SizedBox(height: 8),FittedBox(
                    child: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!organism.public) const Icon(Icons.lock, size: 12),
                    Text(organism.description ?? ' ',
                        style: textTheme.bodySmall),
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
