import 'package:pipeline/organisms/base_organism.dart';

class Silene extends BaseOrganism {
  Silene() : super(name: 'Silene vulgaris');

  @override
  String? transcriptParser(Map<String, String> attributes) {
    // We use transcript_id instead of Name
    return attributes['ID'];
  }

  @override
  String? stageNameFromTpmFilePath(String path) => path;
}
