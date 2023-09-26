import 'package:pipeline/organisms/base_organism.dart';

class Amborella extends BaseOrganism {
  Amborella() : super(name: 'Amborella trichopoda');

  @override
  String? tmpKeyFromPath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^[0-9]+\.\s*Amborella_([^.]*)').firstMatch(filename)?.group(1);
    return key;
  }

  @override
  String? nameTransformer(Map<String, String> attributes) {
    // Convert `evm_27.model.AmTr_v1.0_scaffold00001.1` to `evm_27.TU.AmTr_v1.0_scaffold00001.1`
    final original = attributes['Name'];
    if (original == null) return null;
    final parts = original.split('.');
    return [parts[0], 'TU', ...parts.sublist(2)].join('.');
  }

  @override
  String sequenceIdentifier(List<String> line) {
    // It's in the Alias field
    return line[1];
  }
}
