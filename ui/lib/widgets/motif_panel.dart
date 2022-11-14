import 'package:flutter/material.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/analysis/presets.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';

class MotifSubtitle extends StatelessWidget {
  const MotifSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final motif = context.select<GeneModel, Motif?>((model) => model.motif);
    return motif == null
        ? const Text('Choose a motif to analyze')
        : Text(truncate('${motif.name} (${motif.definitions.join(', ')})', 100));
  }
}

class MotifPanel extends StatefulWidget {
  final Function(Motif? motif) onChanged;

  const MotifPanel({Key? key, required this.onChanged}) : super(key: key);

  @override
  State<MotifPanel> createState() => _MotifPanelState();
}

class _MotifPanelState extends State<MotifPanel> {
  final _formKey = GlobalKey<FormState>();

  String? _motifName;
  String? _motifDefinition;
  final _nameController = TextEditingController();
  final _definitionController = TextEditingController();
  final _reverseComplementsController = TextEditingController();
  bool _showEditor = false;

  @override
  void dispose() {
    _nameController.dispose();
    _definitionController.dispose();
    _reverseComplementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    if (sourceGenes == null) return const Center(child: Text('Load source data first'));
    Motif? motif;
    if (_motifDefinition != null) {
      final defs = _getDefinitions(_motifDefinition!);
      if (Motif.validate(defs) == null) {
        motif = Motif(name: 'X', definitions: defs);
      }
    }
    return Align(
      alignment: Alignment.topLeft,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_showEditor && motif != null)
              TextButton(child: const Text('Edit motif…'), onPressed: () => setState(() => _showEditor = true)),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...Presets.analyzedMotifs.map((m) => _MotifCard(
                      motif: m,
                      onSelected: () => _handlePresetSelected(m),
                      isSelected: m.definitions.join(',') == motif?.definitions.join(','),
                    )),
                TextButton(onPressed: () => _handlePresetSelected(null), child: const Text('Custom motif…'))
              ],
            ),
            const SizedBox(height: 16),
            if (_showEditor)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _nameController,
                      validator: (value) => value != null && value.isNotEmpty ? null : 'Enter the motif name',
                      onChanged: (value) {
                        setState(() => _motifName = value);
                        _handleChanged();
                      },
                      onSaved: (value) => _motifName = value,
                      decoration: const InputDecoration(
                        labelText: "Motif name",
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: _definitionController,
                      validator: _validateMotifDefinition,
                      onChanged: (value) {
                        setState(() => _motifDefinition = value);
                        _handleChanged();
                      },
                      onSaved: (value) => _motifDefinition = value,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: "Motif definition. Separate multiple by new line",
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: _reverseComplementsController,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      maxLines: null,
                      readOnly: true,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: "Reverse complements (read-only)",
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (_showEditor)
              Text('R = AG, Y = CT, W = AT, S = GC, M = AC, K = GT, B = CGT, D = AGT, H = ACT, V = ACG, N = ACGT',
                  style: Theme.of(context).textTheme.caption!),
          ],
        ),
      ),
    );
  }

  void _handleChanged() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final motif = _motifDefinition == null
          ? null
          : Motif(name: _motifName ?? 'Unnamed motif', definitions: _getDefinitions(_motifDefinition!));
      _reverseComplementsController.text = motif?.reverseDefinitions.join('\n') ?? '';
      widget.onChanged(motif);
    }
  }

  List<String> _getDefinitions(String raw) {
    return raw.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
  }

  String? _validateMotifDefinition(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the motif definition';
    }
    final defs = _getDefinitions(value);
    try {
      Motif.validate(defs);
    } catch (error) {
      return error.toString();
    }
    return null;
  }

  void _handlePresetSelected(Motif? motif) {
    _nameController.text = motif?.name ?? '';
    _definitionController.text = motif?.definitions.join('\n') ?? '';
    _reverseComplementsController.text = motif?.reverseDefinitions.join('\n') ?? '';
    setState(() {
      _motifName = motif?.name;
      _motifDefinition = motif?.definitions.join('\n');
      _showEditor = motif == null;
    });
    _handleChanged();
  }
}

class _MotifCard extends StatelessWidget {
  final Motif motif;
  final VoidCallback onSelected;
  final bool isSelected;
  const _MotifCard({required this.motif, required this.onSelected, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 200,
      child: Card(
        color: isSelected ? colorScheme.primaryContainer : null,
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(child: Text(truncate(motif.name, 20), style: textTheme.titleSmall)),
                const SizedBox(height: 8),
                FittedBox(child: Text(truncate(motif.definitions.join(', '), 25), style: textTheme.caption)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
