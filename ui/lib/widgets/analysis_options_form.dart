import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_options.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';

class AnalysisOptionsForm extends StatefulWidget {
  final Function(AnalysisOptions options) onChanged;
  final bool enabled;

  const AnalysisOptionsForm({Key? key, required this.onChanged, this.enabled = true}) : super(key: key);

  @override
  State<AnalysisOptionsForm> createState() => _AnalysisOptionsFormState();
}

class _AnalysisOptionsFormState extends State<AnalysisOptionsForm> {
  final _formKey = GlobalKey<FormState>();

  late int _min;
  late int _max;
  late int _interval;
  String? _alignMarker;

  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _intervalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final options = GeneModel.of(context).analysisOptions;
    _min = options.min;
    _max = options.max;
    _interval = options.interval;
    _alignMarker = options.alignMarker;
    _minController.text = '$_min';
    _maxController.text = '$_max';
    _intervalController.text = '$_interval';
  }

  @override
  void dispose() {
    super.dispose();
    _minController.dispose();
    _maxController.dispose();
    _intervalController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers =
        context.select<GeneModel, List<String>>((model) => model.sourceGenes?.genes.first.markers.keys.toList() ?? []);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  enabled: widget.enabled,
                  controller: _minController,
                  decoration: const InputDecoration(labelText: 'Distribution min'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() => _min = (int.tryParse(_minController.text) ?? 0));
                    _handleChanged();
                  },
                  validator: (value) {
                    final parsed = int.tryParse(_minController.text);
                    if (parsed == null || parsed >= _max) return 'Enter a number lower than $_max';
                    return null;
                  },
                ),
              ),
              const VerticalDivider(),
              Expanded(
                child: TextFormField(
                  enabled: widget.enabled,
                  controller: _maxController,
                  decoration: const InputDecoration(labelText: 'Distribution max'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() => _max = (int.tryParse(_maxController.text) ?? 0));
                    _handleChanged();
                  },
                  validator: (value) {
                    final parsed = int.tryParse(_maxController.text);
                    if (parsed == null || parsed <= _min) return 'Enter a number greater than $_min';
                    return null;
                  },
                ),
              ),
              const VerticalDivider(),
              Expanded(
                child: TextFormField(
                  enabled: widget.enabled,
                  controller: _intervalController,
                  decoration: const InputDecoration(labelText: 'Step'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() => _interval = (int.tryParse(_intervalController.text) ?? 1).clamp(1, 10000));
                    _handleChanged();
                  },
                  validator: (value) {
                    final parsed = int.tryParse(_intervalController.text);
                    if (parsed == null || parsed < 1 || parsed > 10000) return 'Enter a number between 1 and 10000';
                    return null;
                  },
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<String?>(
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sequence start')),
                      for (final marker in markers) DropdownMenuItem(value: marker, child: Text(marker)),
                    ],
                    onChanged: widget.enabled
                        ? (value) {
                            setState(() => _alignMarker = value);
                            _handleChanged();
                          }
                        : null,
                    value: _alignMarker,
                    decoration: const InputDecoration(labelText: 'Alignment')),
              ),
            ],
          ),
          if (!widget.enabled) ...[
            const SizedBox(height: 16),
            Text('To edit analysis options, please first remove all existing results from the Results tab.',
                style: Theme.of(context).textTheme.caption!)
          ],
        ],
      ),
    );
  }

  void _handleChanged() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (widget.enabled) {
        widget.onChanged(AnalysisOptions(min: _min, max: _max, interval: _interval, alignMarker: _alignMarker));
      }
    }
  }
}
