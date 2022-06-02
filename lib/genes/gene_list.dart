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
    if (filter.transcriptionKey == null) return this;
    genes.sort((a, b) =>
        a.transcriptionRates[filter.transcriptionKey]!.compareTo(b.transcriptionRates[filter.transcriptionKey]!));
    switch (filter.strategy) {
      case null:
        return this;
      case FilterStrategy.top3200:
        return GeneList.fromList(_top(3200));
      case FilterStrategy.bottom3200:
        return GeneList.fromList(_bottom(3200));
      case FilterStrategy.top95th:
        return GeneList.fromList(_topPercentile(0.95, filter.transcriptionKey!));
      case FilterStrategy.bottom5th:
        return GeneList.fromList(_bottomPercentile(0.05, filter.transcriptionKey!));
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
