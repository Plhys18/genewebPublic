import 'package:pipeline/organisms/base_organism.dart';

class Azolla extends BaseOrganism {
  Azolla() : super(name: 'Azolla filiculoides');

  @override
  String? transcriptParser(Map<String, String> attributes) {
    // We use transcript_id instead of Name
    return attributes['ID'];
  }
}
