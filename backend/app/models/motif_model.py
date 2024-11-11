import re
from typing import List, Dict, Set, Optional

class Motif:
    supported_nucleotides = {
        'A', 'G', 'C', 'T', 'U',
        'R', 'Y', 'N', 'W', 'S',
        'M', 'K', 'B', 'H', 'D', 'V',
    }

    reverse_complements = {
        'A': 'T',
        'G': 'C',
        'C': 'G',
        'T': 'A',
        'U': 'A',
        'R': 'Y',
        'Y': 'R',
        'N': 'N',
        'W': 'W',
        'S': 'S',
        'M': 'K',
        'K': 'M',
        'B': 'V',
        'H': 'D',
        'D': 'H',
        'V': 'B',
    }

    def __init__(self, name: str, definitions: List[str], is_custom: bool = False):
        self.name = name
        self.definitions = definitions
        self.is_custom = is_custom

    @property
    def id(self) -> str:
        return ','.join(self.definitions)

    @staticmethod
    def validate(definitions: List[str]) -> Optional[str]:
        if not definitions:
            return 'Definition cannot be empty'
        for definition in definitions:
            if not re.match(r"^[AGCTURYNWSMKBHDV]+$", definition):
                return 'Motif definition contains invalid characters'
        return None

    @property
    def reg_exp(self) -> Dict[str, re.Pattern]:
        return {definition: self.to_reg_exp(definition) for definition in self.definitions}

    @staticmethod
    def to_reg_exp(definition: str, strict: bool = False) -> re.Pattern:
        result = []
        if strict:
            result.append('^')
        for code in definition:
            result.append(Motif.nucleotide_code_to_reg_exp_part(code))
        if strict:
            result.append('$')
        return re.compile(''.join(result))

    @property
    def reverse_definitions(self) -> List[str]:
        complements = []
        for definition in self.definitions:
            result = [self.reverse_complements[code] for code in definition]
            complements.append(''.join(reversed(result)))
        return complements

    @property
    def reverse_complement_reg_exp(self) -> Dict[str, re.Pattern]:
        return {definition: self.to_reg_exp(definition) for definition in self.reverse_definitions}

    @staticmethod
    def nucleotide_code_to_reg_exp_part(code: str) -> str:
        code_mapping = {
            'A': 'A', 'G': 'G', 'C': 'C', 'T': 'T', 'U': 'A',
            'R': '[RAG]', 'Y': '[YCT]', 'N': '.', 'W': '[WAT]',
            'S': '[SGC]', 'M': '[MAC]', 'K': '[KGT]',
            'B': '[BSYKGCT]', 'H': '[HMYWACT]', 'D': '[DRKWAGT]',
            'V': '[VRSMAGC]',
        }
        if code not in code_mapping:
            raise ValueError(f'Unsupported code `{code}`')
        return code_mapping[code]

    @staticmethod
    def drill_down_codes(code: str) -> Set[str]:
        drill_down_mapping = {
            'A': set(), 'G': set(), 'C': set(), 'T': set(), 'U': set(),
            'R': {'A', 'G'}, 'Y': {'C', 'T'}, 'N': Motif.supported_nucleotides,
            'W': {'A', 'T'}, 'S': {'G', 'C'}, 'M': {'A', 'C'},
            'K': {'G', 'T'}, 'B': {'S', 'Y', 'K', 'G', 'C', 'T'},
            'H': {'M', 'Y', 'W', 'A', 'C', 'T'}, 'D': {'R', 'K', 'W', 'A', 'G', 'T'},
            'V': {'R', 'S', 'M', 'A', 'G', 'C'},
        }
        if code not in drill_down_mapping:
            raise ValueError(f'Unsupported code `{code}`')
        return drill_down_mapping[code]

