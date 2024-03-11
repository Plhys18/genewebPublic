import 'package:pipeline/organisms/base_organism.dart';

class Ginkgo extends BaseOrganism {
  Ginkgo() : super(name: 'Ginkgo biloba');

  @override
  String? stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^([0-9]+\.)?\s*Ginkgo_([^.]*)').firstMatch(filename)?.group(2);
    return key;
  }

  @override
  String? transcriptParser(Map<String, String> attributes) {
    // We use ID instead of Name
    return attributes['ID'];
  }
}
