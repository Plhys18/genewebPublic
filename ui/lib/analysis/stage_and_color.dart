import 'package:flutter/material.dart';

/// Visual representation of an individual stage
class StageAndColor {
  /// The name of the stage
  final String stage;

  /// The color of the stage
  final Color color;

  /// The stroke width of the stage
  final int stroke;

  /// Whether the stage is checked by default
  final bool isCheckedByDefault;

  StageAndColor(this.stage, this.color,
      {this.stroke = 4, this.isCheckedByDefault = true});

  factory StageAndColor.fromJson(Map<String, dynamic> json) {
    return StageAndColor(
      json['stage'] ?? 'Unknown',
      _parseColor(json['color'] ?? '#000000'),
      stroke: json['stroke'] ?? 4,
      isCheckedByDefault: json['isCheckedByDefault'] ?? true,
    );
  }

  static Color _parseColor(String colorString) {
    colorString = colorString.trim().toUpperCase();

    final namedColors = {
      'ORANGE': Colors.orange,
      'TEAL': Colors.teal,
      'PURPLE': Colors.purple,
      'ORCHID': Colors.purpleAccent,
      'BROWN': Colors.brown,
      'BLUE': Colors.blue,
      'RED': Colors.red,
      'YELLOW': Colors.yellow,
      'GREEN': Colors.green,
      'BLACK': Colors.black,
      'WHITE': Colors.white,
      'GREY': Colors.grey,
    };

    if (namedColors.containsKey(colorString)) {
      return namedColors[colorString]!;
    }

    if (colorString.startsWith('#')) {
      colorString = colorString.substring(1);
    }

    if (colorString.length == 6) {
      colorString = 'FF$colorString';
    }

    try {
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return Colors.black;
    }

}
}
