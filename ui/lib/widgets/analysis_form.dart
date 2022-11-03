import 'package:flutter/material.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/analysis/presets.dart';
import 'package:truncate/truncate.dart';

class AnalysisForm extends StatefulWidget {
  final Function(Motif motif) onChanged;

  const AnalysisForm({Key? key, required this.onChanged}) : super(key: key);

  @override
  State<AnalysisForm> createState() => _AnalysisFormState();
}

class _AnalysisFormState extends State<AnalysisForm> {
  final _formKey = GlobalKey<FormState>();

  String? _motifName;
  String? _motifDefinition;
  final _nameController = TextEditingController();
  final _definitionController = TextEditingController();
  final _reverseComplementsController = TextEditingController();
  bool _showPresets = true;
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
    Motif? motif;
    if (_motifDefinition != null) {
      final defs = _getDefinitions(_motifDefinition!);
      if (Motif.validate(defs) == null) {
        motif = Motif(name: 'X', definitions: defs);
      }
    }
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!_showPresets)
                TextButton(
                    child: const Text('Show presets'),
                    onPressed: () => setState(() {
                          _showPresets = true;
                          _showEditor = false;
                        })),
              if (!_showEditor)
                TextButton(
                    child: Text(motif == null ? 'Enter custom motif' : 'Edit motif'),
                    onPressed: () => setState(() {
                          _showPresets = false;
                          _showEditor = true;
                        })),
            ],
          ),
          if (_showPresets)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...Presets.analyzedMotifs.map((m) => _MotifCard(motif: m, onSelected: () => _handlePresetSelected(m))),
                _MotifCard(motif: null, onSelected: () => _handlePresetSelected(null)),
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
    );
  }

  void _handleChanged() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final motif = Motif(name: _motifName!, definitions: _getDefinitions(_motifDefinition!));
      _reverseComplementsController.text = motif.reverseDefinitions.join('\n');
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
      _showPresets = false;
      _showEditor = motif == null;
    });
    _handleChanged();
  }
}

class _MotifCard extends StatelessWidget {
  final Motif? motif;
  final VoidCallback onSelected;
  const _MotifCard({required this.motif, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 80,
      child: Card(
        color: motif == null ? Theme.of(context).colorScheme.surfaceVariant : null,
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: motif == null
                ? const Center(
                    child: Text('Custom motif…'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(motif!.name, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(truncate(motif!.definitions.join(', '), 50), style: Theme.of(context).textTheme.caption),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
