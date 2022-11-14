import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_result.dart';
import 'package:geneweb/analysis/distribution.dart';
import 'package:geneweb/analysis/motif.dart';
import 'package:geneweb/genes/gene.dart';
import 'package:geneweb/genes/gene_list.dart';

class Analysis {
  final GeneList geneList;
  final int min;
  final int max;
  final int interval;
  final String? alignMarker;
  final String name;
  final Motif motif;
  final Color color;
  final int stroke;
  final bool visible;

  /// When `true`, analysis will filter overlapping matches
  final bool noOverlaps;

  final List<AnalysisResult>? result;
  final Distribution? distribution;

  Analysis({
    required this.geneList,
    required this.noOverlaps,
    required this.min,
    required this.max,
    required this.interval,
    required this.motif,
    required this.name,
    required this.color,
    this.alignMarker,
    this.stroke = 2,
    this.visible = true,
    required this.result,
    required this.distribution,
  });

  Analysis copyWith({Color? color, int? stroke, bool? visible}) {
    return Analysis(
      geneList: geneList,
      noOverlaps: noOverlaps,
      min: min,
      max: max,
      interval: interval,
      alignMarker: alignMarker,
      name: name,
      motif: motif,
      color: color ?? this.color,
      stroke: stroke ?? this.stroke,
      visible: visible ?? this.visible,
      result: result,
      distribution: distribution,
    );
  }

  factory Analysis.run({
    required GeneList geneList,
    noOverlaps = true,
    required int min,
    required int max,
    required int interval,
    required Motif motif,
    required String name,
    required Color color,
    String? alignMarker,
    int stroke = 2,
    bool visible = true,
  }) {
    List<AnalysisResult> results = [];
    for (var gene in geneList.genes) {
      results.addAll(_findMatches(gene, motif, noOverlaps));
    }
    final distribution =
        Distribution(min: min, max: max, interval: interval, alignMarker: alignMarker, name: name, color: color)
          ..run(results, geneList.genes.length);
    return Analysis(
      geneList: geneList,
      noOverlaps: noOverlaps,
      min: min,
      max: max,
      interval: interval,
      motif: motif,
      name: name,
      color: color,
      result: results,
      distribution: distribution,
    );
  }

  static List<AnalysisResult> _findMatches(Gene gene, Motif motif, bool noOverlaps) {
    List<AnalysisResult> result = [];
    final definitions = {
      ...motif.regExp,
      ...motif.reverseComplementRegExp,
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

  List<DrillDownResult> drillDown(String? pattern) {
    final filteredResult = pattern == null
        ? result!
        : result!.where((e) => Motif.toRegExp(pattern, true).hasMatch(e.matchedSequence)).toList();
    List<String> testPatterns;
    if (pattern != null) {
      testPatterns = [
        for (int i = 0; i < pattern.length; i++)
          for (final code in Motif.drillDownCodes(pattern[i]))
            '${pattern.substring(0, i)}$code${pattern.substring(i + 1)}',
      ];
    } else {
      testPatterns = [
        ...motif.definitions,
        ...motif.reverseDefinitions,
      ];
    }
    Map<String, int> counts = {};
    for (final testPattern in testPatterns) {
      counts[testPattern] =
          filteredResult.where((e) => Motif.toRegExp(testPattern, true).hasMatch(e.matchedSequence)).length;
    }
    final List<DrillDownResult> drillDownResults = [
      for (final testPattern in counts.keys)
        DrillDownResult(
          testPattern,
          counts[testPattern]!,
          counts[testPattern]! / filteredResult.length,
          counts[testPattern]! / result!.length,
        ),
    ];
    drillDownResults.sort((a, b) => b.count.compareTo(a.count));
    return drillDownResults;
  }
}

class DrillDownResult {
  final String pattern;
  final int count;
  final double share;
  final double shareOfAll;

  DrillDownResult(this.pattern, this.count, this.share, this.shareOfAll);
}
