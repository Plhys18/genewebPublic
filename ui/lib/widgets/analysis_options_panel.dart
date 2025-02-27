import 'package:flutter/material.dart';

import '../analysis/analysis_options.dart';

class AnalysisOptionsPanel extends StatefulWidget {
  final AnalysisOptions initialOptions;
  final Function(AnalysisOptions) onChanged;

  const AnalysisOptionsPanel({super.key, required this.initialOptions, required this.onChanged});

  @override
  State<AnalysisOptionsPanel> createState() => _AnalysisOptionsPanelState();
}

class _AnalysisOptionsPanelState extends State<AnalysisOptionsPanel> {
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
    _min = widget.initialOptions.min;
    _max = widget.initialOptions.max;
    _interval = widget.initialOptions.bucketSize;
    _alignMarker = widget.initialOptions.alignMarker;
    _minController.text = '$_min';
    _maxController.text = '$_max';
    _intervalController.text = '$_interval';
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<String?>(
                value: _alignMarker,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Sequence start')),
                  DropdownMenuItem(value: "TSS", child: Text("TSS")),
                  DropdownMenuItem(value: "ATG", child: Text("ATG")),
                ],
                onChanged: (value) => _updateOptions(alignMarker: value),
                decoration: const InputDecoration(labelText: 'Motif mapping'),
              ),
            ),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _minController,
                decoration: const InputDecoration(labelText: 'Genomic interval Min [bp]'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateOptions(min: int.tryParse(value) ?? _min),
              ),
            ),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _maxController,
                decoration: const InputDecoration(labelText: 'Genomic interval Max [bp]'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateOptions(max: int.tryParse(value) ?? _max),
              ),
            ),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _intervalController,
                decoration: const InputDecoration(labelText: 'Bucket size [bp]'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateOptions(bucketSize: int.tryParse(value) ?? _interval),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateOptions({int? min, int? max, int? bucketSize, String? alignMarker}) {
    setState(() {
      _min = min ?? _min;
      _max = max ?? _max;
      _interval = bucketSize ?? _interval;
      _alignMarker = alignMarker ?? _alignMarker;
    });
    widget.onChanged(AnalysisOptions(min: _min, max: _max, bucketSize: _interval, alignMarker: _alignMarker));
  }
}
