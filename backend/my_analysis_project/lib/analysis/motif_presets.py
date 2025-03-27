from my_analysis_project.lib.analysis.motif import Motif


class MotifPresets:
    """
    Presets for motifs that are used in the UI

    See Motif
    """

    @staticmethod
    def get_presets():
        presets = [
            Motif(name='ABRE', definitions=['ACGTG']),
            Motif(name='ARR10_core', definitions=['GATY']),
            Motif(name='BR_response element', definitions=['CGTGYG']),
            Motif(name='CAAT-box', definitions=['CCAATT']),
            Motif(name='DOF_core motif', definitions=['AAAG']),
            Motif(name='DRE/CRT element', definitions=['CCGAC']),
            Motif(name='E-box', definitions=['CANNTG']),
            Motif(name='G-box', definitions=['CACGTG']),
            Motif(name='GCC-box', definitions=['GCCGCC']),
            Motif(name='GTGA motif', definitions=['GTGA']),
            Motif(name='I-box', definitions=['GATAAG']),
            Motif(name='pollen Q-element', definitions=['AGGTCA']),
            Motif(name='POLLEN1_LeLAT52', definitions=['AGAAA']),
            Motif(name='TATA-box', definitions=['TATAWA']),
            Motif(
                name='Arabidopsis.telobox',
                public=False,
                definitions=[
                    'CCCTAAAC', 'CCTAAACC', 'CTAAACCC', 'TAAACCCT',
                    'AAACCCTA', 'AACCCTAA', 'ACCCTAAA'
                ],
            ),
            Motif(
                name='Arabidopsis.telobox.generic',
                public=False,
                definitions=['NGGNNTN', 'NGGNTN'],
            ),
            Motif(
                name='Arabidopsis.siteII',
                public=False,
                definitions=['TGGGCC', 'TGGGCT', 'GGNCCCAC', 'GTGGNCCC'],
            ),
            Motif(
                name='Allium.Cepa.telobox',
                public=False,
                definitions=[
                    'CTCGGTTATGGGC', 'TCGGTTATGGGCT', 'CGGTTATGGGCTC',
                    'GGTTATGGGCTCG', 'GTTATGGGCTCGG', 'TTATGGGCTCGGT',
                    'TATGGGCTCGGTT', 'ATGGGCTCGGTTA', 'TGGGCTCGGTTAT',
                    'GGGCTCGGTTATG', 'GGCTCGGTTATGG', 'GCTCGGTTATGGG'
                ],
            ),
            Motif(
                name='Allium.Cepa.7Nt',
                public=False,
                definitions=[
                    'TATGGGC', 'ATGGGCT', 'TGGGCTC', 'GGGCTCG',
                    'GGCTCGG', 'GCTCGGT', 'CTCGGTT', 'TCGGTTA',
                    'CGGTTAT', 'GGTTATG', 'GTTATGG', 'TTATGGG'
                ],
            ),
        ]
        presets.sort(key=lambda m: m.name)
        return presets
