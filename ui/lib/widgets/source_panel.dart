import 'package:flutter/material.dart';
import 'package:geneweb/analysis/organism.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/utilities/api_service.dart';
import 'package:provider/provider.dart';

/// Widget shown just below the panel headline
class SourceSubtitle extends StatelessWidget {
  const SourceSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final sourceGenesLength = context.select<GeneModel, int?>((model) => model.sourceGenesLength);
    final sourceStageKeysLength = context.select<GeneModel, int?>((model) => model.sourceGenesKeysLength);
    final name = context.select<GeneModel, String?>((model) => model.name);
    return sourceGenesLength == null
        ? const Text(
        'Motif positions are mapped relative to the transcription start sites (TSS) or translation start site (ATG)')
        : Wrap(
      children: [
        Text('$name', style: const TextStyle(fontStyle: FontStyle.italic)),
        Text(', $sourceGenesLength genes, $sourceStageKeysLength stages'),
      ],
    );
  }
}

class SourcePanel extends StatefulWidget {
  const SourcePanel({super.key, required this.onShouldClose});

  final VoidCallback onShouldClose;

  @override
  State<SourcePanel> createState() => _SourcePanelState();
}

class _SourcePanelState extends State<SourcePanel> {
  String? _loadingMessage;
  List<Organism> _organisms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchOrganisms();
  }

  Future<void> fetchOrganisms() async {
    setState(() => _loading = true);
    try {
      final organisms = await ApiService().getOrganisms();
      if (mounted) {
        setState(() {
          _organisms = organisms;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = "Error loading organisms: $error";
          _loading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: _loadingMessage != null
          ? _buildLoadingState()
          : _buildLoad(context),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_loadingMessage!, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildLoad(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: _organisms.map((organism) => _OrganismCard(
            organism: organism,
            onSelected: () => _handleSelectOrganism(organism),

          )).toList(),
        ),
      ],
    );
  }

  Future<void> _handleSelectOrganism(Organism organism) async {
    try {
      var model = GeneModel.of(context);
      setState(() => _loadingMessage = "Setting active organism: ${organism.name}…");
      model.fetchOrganismDetails(organism.name);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Now working with ${organism.name}.")));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error selecting organism: $error"), backgroundColor: Colors.red));
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
                const SizedBox(height: 8),
                if (!organism.public) const Icon(Icons.lock, size: 12),
                Text(organism.description ?? ' ', style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
