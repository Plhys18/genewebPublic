import 'dart:io';

class Fasta {
  final Map<String, String> sequences;

  Fasta({required this.sequences});

  static Future<Fasta> fromFile(FileSystemEntity entity) async {
    final file = File(entity.path);
    final lines = await file.readAsLines();
    String? seqId;
    Map<String, String> sequences = {};
    List<String> current = [];
    for (final line in lines) {
      if (line.startsWith('>')) {
        if (current.isNotEmpty && seqId != null) {
          sequences[seqId] = current.join().toUpperCase();
        }
        current = [];
        seqId = line.substring(1).split(' ').first;
      } else {
        if (seqId == null) {
          throw StateError('Unknown sequence ID for line $line.');
        }
        current.add(line.trim());
      }
    }
    if (current.isNotEmpty && seqId != null) {
      sequences[seqId] = current.join().toUpperCase();
    }
    return Fasta(sequences: sequences);
  }
}
