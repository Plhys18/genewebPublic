import 'package:flutter/material.dart';
import 'package:geneweb/genes/filter_definition.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';

class FilterForm extends StatefulWidget {
  final Function(FilterDefinition filter) onSubmit;

  const FilterForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<FilterForm> createState() => _FilterFormState();
}

class _FilterFormState extends State<FilterForm> {
  final _formKey = GlobalKey<FormState>();

  String? _transcriptionKey;
  FilterStrategy? _strategy;

  @override
  Widget build(BuildContext context) {
    final keys =
        context.select<GeneModel, List<String>>((model) => model.sourceGenes?.transcriptionRates.keys.toList() ?? []);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String?>(
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Any'),
                ),
                for (final key in keys) DropdownMenuItem(value: key, child: Text(key)),
              ],
              onChanged: (value) => setState(() => _transcriptionKey = value),
              value: _transcriptionKey,
              decoration: const InputDecoration(labelText: 'Stage')),
          DropdownButtonFormField<FilterStrategy?>(
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Any'),
                ),
                for (final key in FilterStrategy.values) DropdownMenuItem(value: key, child: Text(key.name)),
              ],
              onChanged: (value) => setState(() => _strategy = value),
              value: _strategy,
              decoration: const InputDecoration(labelText: 'Selection strategy')),
          const SizedBox(
            height: 16,
          ),
          ElevatedButton(onPressed: _handleSubmit, child: const Text('Update Filter')),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSubmit(FilterDefinition(transcriptionKey: _transcriptionKey, strategy: _strategy));
    }
  }
}
