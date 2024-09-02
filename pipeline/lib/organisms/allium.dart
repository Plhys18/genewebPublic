import 'package:pipeline/organisms/base_organism.dart';

class Allium extends BaseOrganism {
  Allium() : super(name: 'Allium cepa');

  @override
  String? transcriptParser(Map<String, String> attributes) {
    // We use transcript_id instead of Name
    return attributes['ID'];
  }

  @override
  String? stageNameFromTpmFilePath(String path) => path;
}
