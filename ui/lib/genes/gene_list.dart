import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/genes/stage_selection.dart';
import 'package:geneweb/genes/gene.dart';
import 'package:geneweb/statistics/series.dart';

/// Holds a list of genes
class GeneList extends Equatable {
  static final Map<String, List<StageAndColor>> _kStages = {
    'marchantia': [
      StageAndColor('Marchantia_Antheridium', const Color(0xff0085B4)),
      StageAndColor('Marchantia_Sperm', const Color(0xffFFC002)),
      StageAndColor('Marchantia_Thallus', const Color(0xff548236)),
    ],
    'physcomitrella': [
      StageAndColor('Physcomitrella_Antheridia_9DAI', const Color(0xff21C5FF)),
      StageAndColor('Physcomitrella_Antheridia_11DAI', const Color(0xff009ED6)),
      StageAndColor('Physcomitrella_14', const Color(0xff009AD0)),
      StageAndColor('Physcomitrella_Antheridia', const Color(0xff0085B4)),
      StageAndColor('Physcomitrella_Sperm_cell_packages', const Color(0xffFFDB69)),
      StageAndColor('Physcomitrella_Leaflets', const Color(0xff548236)),
    ],
    'amborella': [
      StageAndColor('Amborella_UNM', const Color(0xffFF6D6D)),
      StageAndColor('Amborella_Polen', const Color(0xff0085B4)),
      StageAndColor('Amborella_PT_bicellular', const Color(0xffE9A5D2)),
      StageAndColor('Amborella_PT_tricellular', const Color(0xff77175C)),
      StageAndColor('Amborella_generative_cell', const Color(0xffB48502)),
      StageAndColor('Amborella_Sperm_cell', const Color(0xffFFC002)),
      StageAndColor('Amborella_Leaves', const Color(0xff92D050)),
    ],
    'oryza': [
      StageAndColor('Oryza_TCP', const Color(0xff21C5FF)),
      StageAndColor('Oryza_Pollen', const Color(0xff0085B4)),
      StageAndColor('Oryza_Sperm', const Color(0xffFFC002)),
      StageAndColor('Oryza_Leaves', const Color(0xff92D050)),
    ],
    'zea': [
      StageAndColor('Zea_Microspore', const Color(0xffFF6D6D)),
      //BCP missing
      StageAndColor('Zea_Pollen', const Color(0xff0085B4)),
      StageAndColor('Zea_PT', const Color(0xffE9A5D2)),
      StageAndColor('Zea_Sperm', const Color(0xffFFC002)),
      StageAndColor('Zea_Leaves', const Color(0xff92D050)),
    ],
    'solanum': [
      StageAndColor('Solanum_Microspore', const Color(0xffFF6D6D)),
      StageAndColor('Solanum_Pollen', const Color(0xff0085B4)),
      StageAndColor('Solanum_Pollen_grain', const Color(0xff305496)),
      StageAndColor('Solanum_PT', const Color(0xffE9A5D2)),
      StageAndColor('Solanum_PT_1', const Color(0xffD75BAE)),
      StageAndColor('Solanum_PT_3h', const Color(0xffAC2A81)),
      StageAndColor('Solanum_PT_9h', const Color(0xff471234)),
      StageAndColor('Solanum_Generative_cell', const Color(0xffB48502)),
      StageAndColor('Solanum_Sperm', const Color(0xffFFC002)),
      StageAndColor('Solanum_Leaves', const Color(0xff92D050)),
    ],
    'arabidopsis': [
      StageAndColor('tapetum_C', const Color(0xff993300)),
      StageAndColor('EarlyPollen_C', const Color(0xffB71C1C), stroke: 4),
      StageAndColor('UNM_C', const Color(0xffFF6D6D)),
      StageAndColor('BCP_C', const Color(0xffC80002)),
      StageAndColor('LatePollen_C', const Color(0xff0D47A1), stroke: 4),
      StageAndColor('TCP_C', const Color(0xff21C5FF)),
      StageAndColor('MPG_C', const Color(0xff305496)),
      StageAndColor('SIV_C', const Color(0xffFF6600)),
      StageAndColor('sperm_C', const Color(0xffFFC002)),
      StageAndColor('leaves_C', const Color(0xff92D050)),
      StageAndColor('seedling_C', const Color(0xffC6E0B4)),

      StageAndColor('egg_C', const Color(0xff607D8B)),

      StageAndColor('EarlyPollen_L', const Color(0xffB71C1C), stroke: 4),
      StageAndColor('UNM_L', const Color(0xffFF6D6D)),
      StageAndColor('BCP_L', const Color(0xffC80002)),
      StageAndColor('LatePollen_L', const Color(0xff0D47A1), stroke: 4),
      StageAndColor('TCP_L', const Color(0xff21C5FF)),
      StageAndColor('MPG_L', const Color(0xff305496)),

//      StageAndColor('PMI_C', const Color(0xff000000)),
    ],
  };

  GeneList._({
    required this.organism,
    required List<Gene> genes,
    required this.stages,
    required Map<String, Color>? colors,
    required this.errors,
    required this.mergeTranscripts,
  })  : _genes = genes,
        transcriptionRates = _transcriptionRates(genes),
        _colors = colors;

  factory GeneList.fromFasta({required String data, String? organism, bool mergeTranscripts = false}) {
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
        organism: organism,
        genes: merged,
        errors: errors,
        mergeTranscripts: mergeTranscripts,
        stages: null,
        colors: null,
      );
    }

    return GeneList._(
      organism: organism,
      genes: genes,
      errors: errors,
      mergeTranscripts: mergeTranscripts,
      stages: null,
      colors: null,
    );
  }

  /// Name of the organism. This is used for auto detecting colors and stage order
  final String? organism;
  final List<dynamic> errors;
  final bool mergeTranscripts;

  /// List of stages. Key is stage name, value is a list of Gene.ids for that stage (unvalidated) This can be `null` if not supplied
  final Map<String, Set<String>>? stages;

  /// TODO what is this
  final Map<String, Series> transcriptionRates;

  final Map<String, Color>? _colors;
  final List<Gene> _genes;

  @override
  List<Object?> get props => [genes, transcriptionRates];

  List<Gene> get genes => _genes;

  /// Map of colors to be applied for given stage
  Map<String, Color> get colors => _colors ?? _colorsFromStages();

  /// Stroke width for stages
  Map<String, int> get stroke => _strokeFromStages();

  GeneList copyWith({
    String? organism,
    List<Gene>? genes,
    Map<String, Set<String>>? stages,
    Map<String, Color>? colors,
    List<dynamic>? errors,
  }) {
    return GeneList._(
      organism: organism ?? this.organism,
      genes: genes ?? _genes,
      stages: stages ?? this.stages,
      colors: colors ?? this.colors,
      errors: errors ?? this.errors,
      mergeTranscripts: mergeTranscripts,
    );
  }

  /// Get keys for all stages
  ///
  /// Uses [stages] or [transcriptionRates]
  /// Returns stages ordered by developments stage for known organisms
  List<String> get stageKeys {
    final detected = stages != null ? stages!.keys.toList() : transcriptionRates.keys.toList();
    final List<String> result = [];
    final o = organism?.toLowerCase();
    if (_kStages.containsKey(o)) {
      for (final stage in _kStages[o]!) {
        if (detected.contains(stage.stage)) {
          result.add(stage.stage);
        }
      }
      for (final stage in detected) {
        if (!result.contains(stage)) {
          result.add(stage);
        }
      }
    } else {
      result.addAll(detected);
    }
    return result;
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

  Map<String, Color> _colorsFromStages() {
    final o = organism?.toLowerCase();

    if (_kStages.containsKey(o)) {
      final result = <String, Color>{};
      for (final stage in _kStages[o]!) {
        result[stage.stage] = stage.color;
      }
      return result;
    }
    return {};
  }

  Map<String, int> _strokeFromStages() {
    final o = organism?.toLowerCase();

    if (_kStages.containsKey(o)) {
      final result = <String, int>{};
      for (final stage in _kStages[o]!) {
        result[stage.stage] = stage.stroke;
      }
      return result;
    }
    return {};
  }
}

class StageAndColor {
  final String stage;
  final Color color;
  final int stroke;

  StageAndColor(this.stage, this.color, {this.stroke = 2});
}
