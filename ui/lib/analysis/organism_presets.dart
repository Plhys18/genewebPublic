import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:geneweb/genes/gene_list.dart';

class OrganismPresets {
  static final _arabidopsisStages = [
    // StageAndColor('tapetum_C', const Color(0xff993300)),
    // StageAndColor('EarlyPollen_C', const Color(0xffB71C1C), stroke: 4),
    // StageAndColor('UNM_C', const Color(0xffFF6D6D)),
    // StageAndColor('BCP_C', const Color(0xffC80002)),
    // StageAndColor('LatePollen_C', const Color(0xff0D47A1), stroke: 4),
    // StageAndColor('TCP_C', const Color(0xff21C5FF)),
    // StageAndColor('MPG_C', const Color(0xff305496)),
    // StageAndColor('SIV_C', const Color(0xffFF6600)),
    // StageAndColor('sperm_C', const Color(0xffFFC002)),
    // StageAndColor('leaves_C', const Color(0xff92D050)),
    // StageAndColor('seedling_C', const Color(0xffC6E0B4)),
    // StageAndColor('egg_C', const Color(0xff607D8B)),
    // StageAndColor('EarlyPollen_L', const Color(0xffB71C1C), stroke: 4),
    // StageAndColor('UNM_L', const Color(0xffFF6D6D)),
    // StageAndColor('BCP_L', const Color(0xffC80002)),
    // StageAndColor('LatePollen_L', const Color(0xff0D47A1), stroke: 4),
    // StageAndColor('TCP_L', const Color(0xff21C5FF)),
    // StageAndColor('MPG_L', const Color(0xff305496)),

    StageAndColor('col_tapetum', const Color(0xff993300)),
    StageAndColor('col_EarlyPollen', const Color(0xffB71C1C)),
    StageAndColor('col_UNM', const Color(0xffFF6D6D)),
    StageAndColor('col_BCP', const Color(0xffC80002)),
    StageAndColor('col_LatePollen', const Color(0xff0D47A1)),
    StageAndColor('col_TCP', const Color(0xff21C5FF)),
    StageAndColor('col_MPG', const Color(0xff305496)),
    StageAndColor('col_SIV_PT', const Color(0xffFF6600)),
    StageAndColor('col_sperm', const Color(0xffFFC002)),
    StageAndColor('col_leaves', const Color(0xff92D050)),
    StageAndColor('col_Seedlings', const Color(0xffC6E0B4)),
    StageAndColor('col_Egg', const Color(0xff607D8B)),

    StageAndColor('ler_EarlyPollen', const Color(0xffB71C1C)),
    StageAndColor('ler_UNM', const Color(0xffFF6D6D)),
    StageAndColor('ler_BCP', const Color(0xffC80002)),
    StageAndColor('ler_LatePollen', const Color(0xff0D47A1)),
    StageAndColor('ler_TCP', const Color(0xff21C5FF)),
    StageAndColor('ler_MPG', const Color(0xff305496)),

    // Chloroplast & Mitochondrion
    StageAndColor('Tapetum', const Color(0xff993300)),
    StageAndColor('EarlyPollen', const Color(0xffB71C1C)),
    StageAndColor('UNM', const Color(0xffFF6D6D)),
    StageAndColor('lerUNM', const Color(0xffFF6D6D)),
    StageAndColor('BCP', const Color(0xffC80002)),
    StageAndColor('lerBCP', const Color(0xffC80002)),
    StageAndColor('LatePollen', const Color(0xff0D47A1)),
    StageAndColor('TCP', const Color(0xff21C5FF)),
    StageAndColor('lerTCP', const Color(0xff21C5FF)),
    StageAndColor('MPG', const Color(0xff305496)),
    StageAndColor('lerMPG', const Color(0xff305496)),
    StageAndColor('SIV_PT', const Color(0xffFF6600)),
    StageAndColor('Sperm', const Color(0xffFFC002)),
    StageAndColor('Leaves', const Color(0xff92D050)),
    StageAndColor('Seedlings', const Color(0xffC6E0B4)),
    StageAndColor('Egg', const Color(0xff607D8B)),
  ];

  static Organism organismByFileName(String filename) {
    final preset = kOrganisms.firstWhereOrNull((element) => element.filename?.startsWith(filename) == true);
    if (preset != null) {
      return preset;
    }
    final name =
        RegExp(r'([A-Za-z0-9_]+).*').firstMatch(filename)?.group(1)?.replaceAll('_', ' ') ?? 'Unknown organism';
    return Organism(name: name, filename: filename);
  }

  static final List<Organism> kOrganisms = [
    Organism(
      name: 'Marchantia polymorpha',
      filename: 'Marchantia_polymorpha.fasta.zip',
      description: 'ATG',
      stages: [
        StageAndColor('Antheridium', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Thallus', const Color(0xff548236)),
      ],
    ),
    Organism(
      public: true,
      name: 'Marchantia polymorpha',
      filename: 'Marchantia_polymorpha-with-tss.fasta.zip',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Antheridium', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Thallus', const Color(0xff548236)),
      ],
    ),
    Organism(
      name: 'Physcomitrella patens',
      filename: 'Physcomitrella_patens.fasta.zip',
      description: 'ATG',
      stages: [
        StageAndColor('Antheridia_9DAI', const Color(0xff21C5FF)),
        StageAndColor('Antheridia_11DAI', const Color(0xff009ED6)),
        StageAndColor('14-15DAI_(mature)', const Color(0xff009AD0)),
        StageAndColor('Antheridia', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell_packages', const Color(0xffFFDB69)),
        StageAndColor('Leaflets', const Color(0xff548236)),
      ],
    ),
    Organism(
      public: true,
      name: 'Physcomitrella patens',
      filename: 'Physcomitrella_patens-with-tss.fasta.zip',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Antheridia_9DAI', const Color(0xff21C5FF)),
        StageAndColor('Antheridia_11DAI', const Color(0xff009ED6)),
        StageAndColor('14-15DAI_(mature)', const Color(0xff009AD0)),
        StageAndColor('Antheridia', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell_packages', const Color(0xffFFDB69)),
        StageAndColor('Leaflets', const Color(0xff548236)),
      ],
    ),
    Organism(
        public: true,
        name: 'Amborella trichopoda',
        filename: 'Amborella_trichopoda.fasta.zip',
        description: 'ATG',
        takeFirstTranscriptOnly: false,
        stages: [
          StageAndColor('UNM', const Color(0xffFF6D6D)),
          StageAndColor('Pollen', const Color(0xff0085B4)),
          StageAndColor('PT_bicellular', const Color(0xffE9A5D2)),
          StageAndColor('PT_tricellular', const Color(0xff77175C)),
          StageAndColor('Generative_cell', const Color(0xffB48502)),
          StageAndColor('Sperm_cell', const Color(0xffFFC002)),
          StageAndColor('Leaves', const Color(0xff92D050)),
        ]),
    Organism(
      public: true,
      name: 'Oryza sativa',
      filename: 'Oryza_sativa.fasta.zip',
      description: 'ATG',
      stages: [
        StageAndColor('TCP', const Color(0xff21C5FF)),
        StageAndColor('Pollen', const Color(0xff0085B4)),
        StageAndColor('Sperm', const Color(0xffFFC002)),
        StageAndColor('Leaves', const Color(0xff92D050)),
      ],
    ),
    Organism(
      name: 'Zea mays',
      filename: 'Zea_mays.fasta.zip',
      description: 'ATG',
      stages: [
        StageAndColor('Microspore', const Color(0xffFF6D6D)),
        //BCP missing
        StageAndColor('Pollen', const Color(0xff0085B4)),
        StageAndColor('PT', const Color(0xffE9A5D2)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Leaves', const Color(0xff92D050)),
      ],
    ),
    Organism(
      public: true,
      name: 'Zea mays',
      filename: 'Zea_mays-with-tss.fasta.zip',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Microspore', const Color(0xffFF6D6D)),
        //BCP missing
        StageAndColor('Pollen', const Color(0xff0085B4)),
        StageAndColor('PT', const Color(0xffE9A5D2)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Leaves', const Color(0xff92D050)),
      ],
    ),
    Organism(
      name: 'Solanum lycopersicum',
      filename: 'Solanum_lycopersicum.fasta.zip',
      description: 'ATG',
      stages: [
        StageAndColor('Microspore', const Color(0xffFF6D6D)),
        StageAndColor('Pollen', const Color(0xff0085B4)),
        StageAndColor('Pollen_grain', const Color(0xff305496)),
        StageAndColor('PT', const Color(0xffE9A5D2)),
        StageAndColor('PT_1,5h', const Color(0xffD75BAE)),
        StageAndColor('PT_3h', const Color(0xffAC2A81)),
        StageAndColor('PT_9h', const Color(0xff471234)),
        StageAndColor('Generative_cell', const Color(0xffB48502)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Leaves', const Color(0xff92D050)),
      ],
    ),
    Organism(
      public: true,
      name: 'Solanum lycopersicum',
      filename: 'Solanum_lycopersicum-with-tss.fasta.zip',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Microspore', const Color(0xffFF6D6D)),
        StageAndColor('Pollen', const Color(0xff0085B4)),
        StageAndColor('Pollen_grain', const Color(0xff305496)),
        StageAndColor('PT', const Color(0xffE9A5D2)),
        StageAndColor('PT_1,5h', const Color(0xffD75BAE)),
        StageAndColor('PT_3h', const Color(0xffAC2A81)),
        StageAndColor('PT_9h', const Color(0xff471234)),
        StageAndColor('Generative_cell', const Color(0xffB48502)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Leaves', const Color(0xff92D050)),
      ],
    ),
    Organism(
      name: 'Arabidopsis thaliana (ATG)',
      filename: 'Arabidopsis_thaliana.fasta.zip',
      description: 'ATG',
      stages: _arabidopsisStages,
    ),
    Organism(
      public: true,
      name: 'Arabidopsis thaliana (TSS)',
      filename: 'Arabidopsis_thaliana-with-tss.fasta.zip',
      description: 'ATG, TSS',
      stages: _arabidopsisStages,
    ),
    Organism(
      name: 'Arabidopsis thaliana',
      filename: 'Arabidopsis-variants.fasta.zip',
      description: 'TSS, ATG, all splicing variants',
      stages: _arabidopsisStages,
    ),
    Organism(
      name: 'Arabidopsis thaliana',
      filename: 'Arabidopsis_thaliana_mitochondrion.fasta.zip',
      description: 'Mitochondrion dataset',
      stages: _arabidopsisStages,
    ),
    Organism(
      name: 'Arabidopsis thaliana',
      filename: 'Arabidopsis_thaliana_chloroplast.fasta.zip',
      description: 'Chloroplast dataset',
      stages: _arabidopsisStages,
    ),
    Organism(
      name: 'Arabidopsis thaliana',
      filename: 'Arabidopsis_thaliana_small_rna.fasta.zip',
      description: 'Small RNA dataset',
      stages: [],
    ),
  ];
}

class Organism {
  final String name;
  final String? filename;
  final String? description;
  final bool public;
  final bool takeFirstTranscriptOnly;

  final List<StageAndColor> stages;

  Organism({
    required this.name,
    this.filename,
    this.description,
    this.public = false,
    this.takeFirstTranscriptOnly = true,
    this.stages = const [],
  });
}
