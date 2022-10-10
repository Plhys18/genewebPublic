import 'dart:convert';

class Gene {
  static final geneIdRegExp = RegExp(r"(?<gene>[A-Za-z0-9+_\.]+)");
  static final markersRegExp = RegExp(r";MARKERS (?<json>\{.*\})$");
  static final transcriptionRatesRegExp = RegExp(r";TRANSCRIPTION_RATES (?<json>\{.*\})$");

  /// Gene name including splicing variant, e.g. `ATG0001.1`
  final String geneId;

  /// Raw nucleotides data
  final String data;

  /// Header line (>GENE ID...)
  final String header;

  /// Notes
  final List<String> notes;

  final Map<String, num> transcriptionRates;
  final Map<String, int> markers;

  Gene({
    required this.geneId,
    required this.data,
    required this.header,
    required this.notes,
    this.transcriptionRates = const {},
    this.markers = const {},
  });

  String? _geneCode;
  String get geneCode => _geneCode ??= geneId.split('.').first;

  String get geneSplicingVariant => geneId.split('.').last;

  factory Gene.fromFasta(List<String> lines) {
    String? header;
    String? geneId;
    List<String> notes = [];
    List<String> data = [];
    Map<String, num>? transcriptionRates;
    Map<String, int>? markers;

    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line[0] == '>') {
        if (header != null) {
          throw Exception('Multiple header lines');
        }
        header = line;
        geneId = geneIdRegExp.firstMatch(line)?.namedGroup('gene');
      } else if (line[0] == ';') {
        final transcriptionRatesJson = transcriptionRatesRegExp.firstMatch(line)?.namedGroup('json');
        if (transcriptionRatesJson != null) {
          transcriptionRates = Map<String, num>.from(jsonDecode(transcriptionRatesJson));
        }
        final markersJson = markersRegExp.firstMatch(line)?.namedGroup('json');
        if (markersJson != null) {
          markers = Map<String, int>.from(jsonDecode(markersJson));
        }
        notes.add(line);
      } else {
        data.add(line.trim());
      }
    }
    if (header == null || geneId == null) {
      throw Exception('Invalid record: ${lines.join('\n')}');
    }
    final sequence = data.join();
    final atg = markers?['atg'];
    if (atg != null) {
      final codon = sequence.substring(atg - 1, atg - 1 + 3);
      if (codon != 'ATG' && codon != 'CAT') {
        print('Invalid ATG codon at position $atg: $codon ($sequence)');
        throw StateError('ATG not found'); //TODO
      }
    } else {
      print('No ATG marker');
    }
    return Gene(
      geneId: geneId,
      data: sequence,
      header: header,
      notes: notes,
      transcriptionRates: transcriptionRates ?? {},
      markers: markers ?? {},
    );
  }

  @override
  String toString() {
    return geneId;
  }
}
