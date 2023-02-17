import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene.dart';
import 'package:geneweb/statistics/series.dart';

/// Holds a list of genes
class GeneList extends Equatable {
  List<Gene> get genes => _genes;
  final List<Gene> _genes;

  /// TODO what is this
  final Map<String, Series> transcriptionRates;

  /// List of stages. Key is stage name, value is a list of Gene.ids for that stage (unvalidated) This can be `null` if not supplied
  final Map<String, Set<String>>? stages;

  /// Map of colors to be applied for given stage
  final Map<String, Color> colors;
  final List<dynamic> errors;
  final bool mergeTranscripts;

  GeneList._({
    required List<Gene> genes,
    required this.stages,
    required this.colors,
    required this.errors,
    required this.mergeTranscripts,
  })  : _genes = genes,
        transcriptionRates = _transcriptionRates(genes);

  factory GeneList.fromFasta(String data, bool mergeTranscripts) {
    final chunks = data.split('>');
    final genes = <Gene>[];
    final errors = <dynamic>[];
    final Map<String, Color> colors = {};
    for (final chunk in chunks) {
      if (chunk.isEmpty) {
        continue;
      }
      final lines = '>$chunk'.split('\n');
      try {
        final gene = Gene.fromFasta(lines);
        genes.add(gene);
      } catch (error) {
        errors.add(error);
      }
    }

    if (mergeTranscripts) {
      Map<String, List<String>> keys = {};

      for (final gene in genes) {
        final geneCode = gene.geneCode;
        keys[geneCode] = [...(keys[geneCode] ?? []), gene.geneId];
      }

      List<Gene> merged = [];
      for (final key in keys.keys) {
        keys[key]!.sort();
        final first = keys[key]!.first;
        merged.add(genes.where((gene) => gene.geneId == first).first);
      }
      return GeneList._(
        genes: merged,
        errors: errors,
        mergeTranscripts: mergeTranscripts,
        stages: null,
        colors: colors,
      );
    }

    return GeneList._(
      genes: genes,
      errors: errors,
      mergeTranscripts: mergeTranscripts,
      stages: null,
      colors: colors,
    );
  }

  GeneList copyWith({
    List<Gene>? genes,
    Map<String, Set<String>>? stages,
    Map<String, Color>? colors,
  }) {
    return GeneList._(
      genes: genes ?? _genes,
      stages: stages ?? this.stages,
      colors: colors ?? this.colors,
      errors: errors,
      mergeTranscripts: mergeTranscripts,
    );
  }

  List<String> get stageKeys {
    if (stages != null) {
      return stages!.keys.toList();
    }
    return transcriptionRates.keys.toList();
  }

  static Map<String, Series> _transcriptionRates(List<Gene> genes) {
    final result = <String, List<num>>{};
    for (final gene in genes) {
      for (final key in gene.transcriptionRates.keys) {
        if (result.containsKey(key)) {
          result[key]!.add(gene.transcriptionRates[key]!);
        } else {
          result[key] = [gene.transcriptionRates[key]!];
        }
      }
    }
    return {
      for (final key in result.keys) key: Series(result[key]!),
    };
  }

  /// Filters gene for given [stage]. Either uses [stages] or applies [stageSelection], if specified
  GeneList filter({required String stage, required StageSelection stageSelection}) {
    assert(stageKeys.contains(stage), 'Unknown stage $stage');
    if (stages != null) {
      assert(stages![stage] != null && stages![stage]!.isNotEmpty, 'No genes for stage $stage');
      final ids = stages![stage]!;
      return copyWith(genes: genes.where((gene) => ids.contains(gene.geneId)).toList());
    }

    assert(stageSelection.selectedStages.contains(stage));
    genes.sort((a, b) => a.transcriptionRates[stage]!.compareTo(b.transcriptionRates[stage]!));
    if (stageSelection.selection == FilterSelection.percentile) {
      if (stageSelection.strategy == FilterStrategy.top) {
        return copyWith(genes: _topPercentile(stageSelection.percentile!, stage));
      } else {
        return copyWith(genes: _bottomPercentile(stageSelection.percentile!, stage));
      }
    } else {
      if (stageSelection.strategy == FilterStrategy.top) {
        return copyWith(genes: _top(stageSelection.count!));
      } else {
        return copyWith(genes: _bottom(stageSelection.count!));
      }
    }
  }

  List<Gene> _top(int count) {
    final list = genes.reversed.take(count.clamp(0, genes.length));
    return list.toList();
  }

  List<Gene> _bottom(int count) {
    final list = genes.take(count.clamp(0, genes.length));
    return list.toList();
  }

  List<Gene> _topPercentile(double percentile, String transcriptionKey) {
    final totalRate =
        transcriptionRates[transcriptionKey]!.sum + 0.0001; // correction fo floating point operations error
    final list = genes.reversed.toList();
    var rate = 0.0;
    var i = 0;
    List<Gene> result = [];
    while (rate < totalRate * percentile && i < list.length) {
      result.add(list[i]);
      rate += list[i].transcriptionRates[transcriptionKey]!;
      i++;
    }
    /*
    print('$rate <= $totalRate, $i th gene');
    final sequence = list.getRange(i - 10.clamp(0, list.length), (i + 10).clamp(0, list.length));
    for (final gene in sequence) {
      print('${gene.geneId} ${gene.transcriptionRates[transcriptionKey]!}');
    }
    */
    return result.toList();
  }

  List<Gene> _bottomPercentile(double percentile, String transcriptionKey) {
    final totalRate =
        transcriptionRates[transcriptionKey]!.sum + 0.0001; // correction fo floating point operations error;
    final list = genes;
    var rate = 0.0;
    var i = 0;
    List<Gene> result = [];
    while (rate < totalRate * percentile && i < list.length) {
      result.add(list[i]);
      rate += list[i].transcriptionRates[transcriptionKey]!;
      i++;
    }
    return result.toList();
  }

  @override
  List<Object?> get props => [genes, transcriptionRates];
}
