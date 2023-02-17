import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

/// Parses a CSV file with the following format:
/// ```
/// stage1, stage2, stage3, ...
/// #RRGGBB, #RRGGBB, #RRGGBB, ...
/// gene1, gene1, gene3, ...
/// gene2, gene3, gene4, ...
/// gene4, , , ...
/// ```
///
/// Colors row is optional, but must be in row 2 if present.
class StagesData {
  static const _converter = CsvToListConverter();

  final Map<String, Set<String>> stages;
  final Map<String, Color> colors;

  StagesData(this.stages, this.colors);

  factory StagesData.fromCsv(String csv) {
    final table = _converter.convert(csv);
    if (table.length < 2) {
      throw ArgumentError('CSV must have at least 2 rows');
    }
    final stageNames = table[0];
    if (stageNames.isEmpty) {
      throw ArgumentError('CSV must have at least 1 column');
    }

    final Map<String, Set<String>> stages = {};
    Map<String, Color> colors = {};
    for (int rowIndex = 1; rowIndex < table.length; rowIndex++) {
      final row = table[rowIndex];
      if (rowIndex == 1) {
        final colorRow = _colorsRow(row);
        if (colorRow != null) {
          for (var i = 0; i < row.length; i++) {
            final color = colorRow[i];
            final stage = stageNames[i];
            if (color != null) {
              colors[stage] = color;
            }
          }
        }
        continue;
      }
      for (var i = 0; i < row.length; i++) {
        final gene = row[i];
        final stage = stageNames[i];
        if (gene.isEmpty) {
          continue;
        }
        stages[stage] ??= {};
        stages[stage]!.add(gene);
      }
    }
    return StagesData(stages, colors);
  }

  /// Checks the List of Strings for a color value in #RRGGBB format and if all list items are either color or empty, it returns the list of colors or null. Otherwise it returns null
  static List<Color?>? _colorsRow(List<dynamic> row) {
    final input = row.cast<String>();
    if (input.any((e) => e.isNotEmpty && !e.startsWith('#'))) return null;
    final colors = input.map((e) {
      if (e.isEmpty) return null;
      final parsed = int.tryParse(e.substring(1), radix: 16);
      if (parsed == null || parsed < 0 || parsed > 0xFFFFFF) return null;
      return Color(parsed + 0xFF000000);
    }).toList();
    return colors;
  }
}
