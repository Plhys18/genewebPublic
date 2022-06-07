import 'package:equatable/equatable.dart';
import 'package:geneweb/genes/filter_definition.dart';
import 'package:geneweb/genes/gene.dart';
import 'package:geneweb/statistics/series.dart';

class GeneList extends Equatable {
  final List<Gene> genes;
  final Map<String, Series> transcriptionRates;

  const GeneList._(
    this.genes,
    this.transcriptionRates,
  );

  factory GeneList.fromFasta(String data) {
    final chunks = data.split('>');
    final genes = <Gene>[];
    for (final chunk in chunks) {
      if (chunk.isEmpty) {
        continue;
      }
      final lines = '>$chunk'.split('\n');
      try {
        final gene = Gene.fromFasta(lines);
        genes.add(gene);
      } catch (error) {
        rethrow;
      }
    }
    return GeneList._(genes, _transcriptionRates(genes));
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

  factory GeneList.fromList(List<Gene> source) {
    return GeneList._(source, _transcriptionRates(source));
  }

  GeneList filter(FilterDefinition filter) {
    genes.sort((a, b) => a.transcriptionRates[filter.key]!.compareTo(b.transcriptionRates[filter.key]!));
    if (filter.selection == FilterSelection.percentile) {
      if (filter.strategy == FilterStrategy.top) {
        return GeneList.fromList(_topPercentile(filter.percentile!, filter.key));
      } else {
        return GeneList.fromList(_bottomPercentile(filter.percentile!, filter.key));
      }
    } else {
      if (filter.strategy == FilterStrategy.top) {
        return GeneList.fromList(_top(filter.count!));
      } else {
        return GeneList.fromList(_bottom(filter.count!));
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
    final totalRate = transcriptionRates[transcriptionKey]!.sum;
    final list = genes.reversed.toList();
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

  List<Gene> _bottomPercentile(double percentile, String transcriptionKey) {
    final totalRate = transcriptionRates[transcriptionKey]!.sum;
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
