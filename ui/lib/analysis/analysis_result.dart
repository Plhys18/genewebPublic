import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/gene.dart';

class AnalysisResult {
  final Gene gene;
  final Motif motif;
  final num position;
  final num rawPosition;
  final String match;
  final String matchedSequence;

  String get broadMatch {
    final safeSequence = '          ${gene.data}          ';
    return safeSequence.substring(rawPosition.toInt() + 2, rawPosition.toInt() + match.length + 18);
  }

  AnalysisResult({
    required this.gene,
    required this.motif,
    required this.rawPosition,
    required this.position,
    required this.match,
    required this.matchedSequence,
  });
}
