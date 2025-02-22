import 'package:geneweb/analysis/stage_and_color.dart';

/// Class that holds information about an organism
class Organism {
  /// The name of the organism
  final String name;

  /// The URL of the organism fasta file
  final String? filename;

  /// The description of the organism
  final String? description;

  /// Whether the organism is public
  /// TODO private
  final bool public;

  /// Whether to take only the first transcript of each gene
  final bool takeFirstTranscriptOnly;

  /// Definition of how stages should be presented
  final List<StageAndColor> stages;

  Organism({
    required this.name,
    this.filename,
    this.description,
    this.public = true,
    this.takeFirstTranscriptOnly = true,
    this.stages = const [],
  });
}
