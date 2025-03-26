import 'package:faabul_color_picker/faabul_color_picker.dart';
import 'package:flutter/material.dart';
import '../utilities/api_service.dart';

class ColorPreference {
  final int? id;
  final String name;
  final Color color;
  final int strokeWidth;
  final String type;

  ColorPreference({
    this.id,
    required this.name,
    required this.color,
    required this.strokeWidth,
    required this.type,
  });

  factory ColorPreference.fromJson(Map<String, dynamic> json, String type) {
    return ColorPreference(
      id: json['id'],
      name: json['name'],
      color: Color(int.parse(json['color'].substring(1), radix: 16) + 0xFF000000),
      strokeWidth: json['stroke_width'] ?? 4,
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': '#${color.value.toRadixString(16).substring(2)}',
      'stroke_width': strokeWidth,
      'type': type,
    };
  }

  ColorPreference copyWith({
    int? id,
    String? name,
    Color? color,
    int? strokeWidth,
    String? type,
  }) {
    return ColorPreference(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      type: type ?? this.type,
    );
  }
}

class ColorPreferencesManager extends StatefulWidget {
  final String type;
  final String itemName;
  final Color initialColor;
  final int initialStrokeWidth;
  final Function(Color color, int strokeWidth) onPreferenceSet;

  const ColorPreferencesManager({
    Key? key,
    required this.type,
    required this.itemName,
    required this.initialColor,
    this.initialStrokeWidth = 4,
    required this.onPreferenceSet,
  }) : super(key: key);

  @override
  State<ColorPreferencesManager> createState() => _ColorPreferencesManagerState();
}

class _ColorPreferencesManagerState extends State<ColorPreferencesManager> {
  late Color _selectedColor;
  late int _strokeWidth;
  bool _isSaving = false;
  bool _hasCustomPreference = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _strokeWidth = widget.initialStrokeWidth;
    _checkExistingPreference();
  }

  Future<void> _checkExistingPreference() async {
    try {
      final response = await ApiService().getRequest('api/preferences/');

      final preferences = widget.type == 'motif'
          ? response['motifs'] as List
          : response['stages'] as List;

      final existing = preferences.firstWhere(
            (pref) => pref['name'] == widget.itemName,
        orElse: () => {},
      );

      if (existing.isNotEmpty) {
        setState(() {
          _hasCustomPreference = true;
          _selectedColor = Color(int.parse(existing['color'].substring(1), radix: 16) + 0xFF000000);
          _strokeWidth = existing['stroke_width'] ?? 4;
        });
      }
    } catch (e) {
      debugPrint('Error checking preferences: $e');
    }
  }

  Future<void> _savePreference() async {
    setState(() => _isSaving = true);

    try {
      final preference = ColorPreference(
        name: widget.itemName,
        color: _selectedColor,
        strokeWidth: _strokeWidth,
        type: widget.type,
      );

      await ApiService().postRequest('api/preferences/set/', preference.toJson());

      widget.onPreferenceSet(_selectedColor, _strokeWidth);

      setState(() {
        _isSaving = false;
        _hasCustomPreference = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Color preference saved')),
      );
    } catch (e) {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving preference: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetPreference() async {
    if (!_hasCustomPreference) return;

    setState(() => _isSaving = true);

    try {
      await ApiService().getRequest('api/preferences/reset/?type=${widget.type}&name=${widget.itemName}');

      setState(() {
        _isSaving = false;
        _hasCustomPreference = false;
        _selectedColor = widget.initialColor;
        _strokeWidth = widget.initialStrokeWidth;
      });

      widget.onPreferenceSet(widget.initialColor, widget.initialStrokeWidth);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Color preference reset')),
      );
    } catch (e) {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting preference: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.type == 'motif' ? 'Motif' : 'Stage'}: ${widget.itemName}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (_hasCustomPreference)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'Using custom color',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Color:'),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showColorPicker(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Stroke width:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _strokeWidth,
                  items: [2, 4, 6, 8].map((width) =>
                      DropdownMenuItem(
                        value: width,
                        child: Text('$width'),
                      )
                  ).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _strokeWidth = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_hasCustomPreference)
                  OutlinedButton(
                    onPressed: _isSaving ? null : _resetPreference,
                    child: const Text('Reset'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _savePreference,
                  child: _isSaving
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)
                  )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showColorPicker() async {
    final color = await showColorPickerDialog(
      context: context,
      selected: _selectedColor,
    );

    if (color != null) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

}