import 'package:geneweb/analysis/motif.dart';

class MotifPresets {
  static List<Motif> presets = [
    Motif(name: 'ABRE', definitions: ['ACGTG']),
    Motif(name: 'ARR10_core', definitions: ['GATY']),
    Motif(name: 'BR_response element', definitions: ['CGTGYG']),
    Motif(name: 'CAAT-box', definitions: ['CCAATT']),
    Motif(name: 'DOF_core motif', definitions: ['AAAG']),
    Motif(name: 'DRE/CRT element', definitions: ['CCGAC']),
    Motif(name: 'E-box', definitions: ['CANNTG']),
    Motif(name: 'G-box', definitions: ['CACGTG']),
    Motif(name: 'GCC-box', definitions: ['GCCGCC']),
    Motif(name: 'GTGA motif', definitions: ['GTGA']),
    Motif(name: 'I-box', definitions: ['GATAAG']),
    Motif(name: 'pollen Q-element', definitions: ['AGGTCA']),
    Motif(name: 'POLLEN1_LeLAT52', definitions: ['AGAAA']),
    Motif(name: 'TATA-box', definitions: ['TATAWA']),
    Motif(
      name: 'Arabidopsis.telobox',
      isPublic: false,
      definitions: ['CCCTAAAC', 'CCTAAACC', 'CTAAACCC', 'TAAACCCT', 'AAACCCTA', 'AACCCTAA', 'ACCCTAAA'],
    ),
    Motif(
      name: 'Arabidopsis.telobox.generic',
      isPublic: false,
      definitions: ['NGGNNTN', 'NGGNTN'],
    ),
    Motif(
      name: 'Arabidopsis.siteII',
      isPublic: false,
      definitions: ['TGGGCC', 'TGGGCT', 'GGNCCCAC', 'GTGGNCCC'],
    ),
    Motif(
      name: 'Allium.Cepa.telobox',
      isPublic: false,
      definitions: [
        'CTCGGTTATGGGC',
        'TCGGTTATGGGCT',
        'CGGTTATGGGCTC',
        'GGTTATGGGCTCG',
        'GTTATGGGCTCGG',
        'TTATGGGCTCGGT',
        'TATGGGCTCGGTT',
        'ATGGGCTCGGTTA',
        'TGGGCTCGGTTAT',
        'GGGCTCGGTTATG',
        'GGCTCGGTTATGG',
        'GCTCGGTTATGGG'
      ],
    ),
    Motif(
      name: 'Allium.Cepa.7Nt',
      isPublic: false,
      definitions: [
        'TATGGGC',
        'ATGGGCT',
        'TGGGCTC',
        'GGGCTCG',
        'GGCTCGG',
        'GCTCGGT',
        'CTCGGTT',
        'TCGGTTA',
        'CGGTTAT',
        'GGTTATG',
        'GTTATGG',
        'TTATGGG'
      ],
    ),
  ]..sort(((a, b) => a.name.compareTo(b.name)));
}
