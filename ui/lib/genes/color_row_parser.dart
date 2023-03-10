import 'package:flutter/material.dart';

class ColorRowParser {
  /// Checks the List of Strings for a color value in #RRGGBB format and return the list of colors or null.
  static List<Color?>? tryParse(List<dynamic> row) {
    final input = row.cast<String>();
//    if (input.any((e) => e.isNotEmpty && !e.startsWith('#'))) return null;
    final colors = input.map((e) {
      if (e.isEmpty) return null;
      final parsed = int.tryParse(e.substring(1), radix: 16);
      if (parsed == null || parsed < 0 || parsed > 0xFFFFFF) return null;
      return Color(parsed + 0xFF000000);
    }).toList();
    return colors;
  }
}
