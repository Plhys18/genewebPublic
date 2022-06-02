import 'package:geneweb/analysis/analysis_result.dart';
import 'package:geneweb/analysis/distribution.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/filter_definition.dart';
import 'package:geneweb/genes/gene.dart';
import 'package:geneweb/genes/gene_list.dart';

class Analysis {
  final GeneList geneList;
  final int min;
  final int max;
  final int interval;
  final String? alignMarker;
  final FilterDefinition filter;
  final Motif motif;

  /// When `true`, analysis will filter overlapping matches
  final bool noOverlaps;

  List<AnalysisResult>? result;
  Distribution? distribution;

  Analysis(
      {required this.geneList,
      required this.noOverlaps,
      required this.min,
      required this.max,
      required this.interval,
      required this.motif,
      required this.filter,
      this.alignMarker});

  void run(Motif motif) {
    List<AnalysisResult> results = [];
    for (var gene in geneList.genes) {
      results.addAll(_findMatches(gene, motif));
    }
    result = results;
    distribution = Distribution(
        min: min, max: max, interval: interval, alignMarker: alignMarker, name: '${filter.label} - ${motif.name}')
      ..run(this);
  }

  List<AnalysisResult> _findMatches(Gene gene, Motif motif) {
    List<AnalysisResult> result = [];
    final definitions = {
      ...motif.toRegExp(),
      ...motif.toReverseComplementRegExp(),
    };
    for (final definition in definitions.keys) {
      final regexp = definitions[definition]!;
      final matches = regexp.allMatches(gene.data).map((match) {
        final midMatchDelta = (match.group(0)!.length / 2).floor();
        return AnalysisResult(
          gene: gene,
          motif: motif,
          rawPosition: match.start,
          position: match.start + midMatchDelta,
          match: definition,
          matchedSequence: match.group(0)!,
        );
      }).toList();
      result.addAll(matches);
    }
    return noOverlaps ? filterOverlappingMatches(result) : result;
  }

  /// Filter out matches that overlap each other
  static List<AnalysisResult> filterOverlappingMatches(List<AnalysisResult> list) {
    list.sort(
      (a, b) => a.rawPosition.compareTo(b.rawPosition),
    );

    final List<AnalysisResult> excludedResults = [];
    final List<AnalysisResult> includedResults = [];

    for (final result in list) {
      if (excludedResults.contains(result)) continue;
      includedResults.add(result);
      final overlaps = list.where((e) =>
          result != e &&
          e.rawPosition >= result.rawPosition &&
          e.rawPosition < result.rawPosition + result.match.length);
      excludedResults.addAll(overlaps);
    }
    assert(includedResults.length + excludedResults.length == list.length);
    return includedResults;
  }
}
