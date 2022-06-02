/// Stores motif to search
///
/// Codes via https://www.genome.jp/kegg/catalog/codes1.html
class Motif {
  final String name;
  final List<String> definitions;

  static const reverseComplements = {
    'A': 'T',
    'G': 'C',
    'C': 'G',
    'T': 'A',
    'U': 'A',
    'R': 'Y',
    'Y': 'R',
    'N': 'N',
    'W': 'W',
    'S': 'S',
    'M': 'K',
    'K': 'M',
    'B': 'V',
    'H': 'D',
    'D': 'H',
    'V': 'B',
  };

  Motif({required this.name, required this.definitions});

  static String? validate(List<String> definitions) {
    if (definitions.isEmpty) {
      throw ArgumentError('Definition cannot be empty');
    }
    if (definitions.where((definition) => !RegExp(r"^[AGCTURYNWSMKBHDV]+$").hasMatch(definition)).isNotEmpty) {
      throw ArgumentError('Motif definition contains invalid characters');
    }
    return null;
  }

  Map<String, RegExp> toRegExp() {
    return {
      for (final definition in definitions) definition: _toRegExp(definition),
    };
  }

  RegExp _toRegExp(String def) {
    final List<String> result = [
      for (int i = 0; i < def.length; i++) _nucleotideCodeToRegExpPart(def[i]),
    ];
    return RegExp(result.join());
  }

  Map<String, RegExp> toReverseComplementRegExp() {
    return {
      for (final definition in reverseDefinitions) definition: _toRegExp(definition),
    };
  }

  List<String> get reverseDefinitions {
    List<String> complements = [];
    for (final definition in definitions) {
      final result = List<String>.generate(definition.length, (index) {
        final code = definition[index];
        final reverse = reverseComplements[code];
        if (reverse == null) {
          ArgumentError('Unsupported code `$code`');
        }
        return reverse!;
      });
      complements.add(result.reversed.join());
    }
    return complements;
  }

  String _nucleotideCodeToRegExpPart(String code) {
    switch (code) {
      case 'A':
      case 'G':
      case 'C':
      case 'T':
      case 'U':
        return code;
      case 'R':
        return '[AG]';
      case 'Y':
        return '[CT]';
      case 'N':
        return '.';
      case 'W':
        return '[AT]';
      case 'S':
        return '[GC]';
      case 'M':
        return '[AC]';
      case 'K':
        return '[GT]';
      case 'B':
        return '[GCT]';
      case 'H':
        return '[ACT]';
      case 'D':
        return '[AGT]';
      case 'V':
        return '[AGC]';
      default:
        throw ArgumentError('Unsupported code `$code`');
    }
  }
}
