import 'package:flutter/material.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/analysis/presets.dart';

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
  final nameController = TextEditingController();
  final definitionController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    definitionController.dispose();
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
          DropdownButtonFormField<Motif?>(
              items: [
                for (final motif in Presets.analyzedMotifs) DropdownMenuItem(value: motif, child: Text(motif.name)),
              ],
              onChanged: _handlePresetSelected,
              value: null,
              decoration: const InputDecoration(labelText: 'Motif presets')),
          const SizedBox(height: 16),
          TextFormField(
            controller: nameController,
            validator: (value) => value != null && value.isNotEmpty ? null : 'Please enter the motif name',
            onChanged: (value) {
              setState(() => _motifName = value);
              _handleChanged();
            },
            onSaved: (value) => _motifName = value,
            decoration: const InputDecoration(
              labelText: "Motif name",
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: definitionController,
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
              const VerticalDivider(),
              if (motif != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reverse definitions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(
                      height: 8.0,
                    ),
                    ...motif.reverseDefinitions.map((s) => Text(s)).toList(),
                  ],
                )
            ],
          ),
        ],
      ),
    );
  }

  void _handleChanged() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onChanged(Motif(name: _motifName!, definitions: _getDefinitions(_motifDefinition!)));
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
    if (motif == null) return;
    nameController.text = motif.name;
    definitionController.text = motif.definitions.join('\n');
    setState(() {
      _motifName = motif.name;
      _motifDefinition = motif.definitions.join('\n');
    });
    _handleChanged();
  }
}
