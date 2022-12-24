import 'package:equatable/equatable.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene.dart';
import 'package:geneweb/statistics/series.dart';

class GeneList extends Equatable {
  List<Gene> get genes => _genes;
  final List<Gene> _genes;
  final Map<String, Series> transcriptionRates;
  final List<dynamic> errors;
  final bool mergeTranscripts;

  const GeneList._({
    required List<Gene> genes,
    required this.transcriptionRates,
    required this.errors,
    required this.mergeTranscripts,
  }) : _genes = genes;

  factory GeneList.fromFasta(String data, bool mergeTranscripts) {
    final chunks = data.split('>');
    final genes = <Gene>[];
    final errors = <dynamic>[];
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
        transcriptionRates: _transcriptionRates(genes),
        errors: errors,
        mergeTranscripts: mergeTranscripts,
      );
    }

    return GeneList._(
      genes: genes,
      transcriptionRates: _transcriptionRates(genes),
      errors: errors,
      mergeTranscripts: mergeTranscripts,
    );
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

  factory GeneList.fromList(List<Gene> source, bool merged) {
    return GeneList._(
        genes: source, transcriptionRates: _transcriptionRates(source), errors: const [], mergeTranscripts: merged);
  }

  GeneList filter(StageSelection filter, String stage) {
    assert(filter.stages.contains(stage));
    genes.sort((a, b) => a.transcriptionRates[stage]!.compareTo(b.transcriptionRates[stage]!));
    if (filter.selection == FilterSelection.percentile) {
      if (filter.strategy == FilterStrategy.top) {
        return GeneList.fromList(_topPercentile(filter.percentile, stage), mergeTranscripts);
      } else {
        return GeneList.fromList(_bottomPercentile(filter.percentile, stage), mergeTranscripts);
      }
    } else {
      if (filter.strategy == FilterStrategy.top) {
        return GeneList.fromList(_top(filter.count), mergeTranscripts);
      } else {
        return GeneList.fromList(_bottom(filter.count), mergeTranscripts);
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
