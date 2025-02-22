import re
from typing import List, Optional, Dict, Set

class Motif:
    """
    Stores motif to search

    Codes via https://www.genome.jp/kegg/catalog/codes1.html
    """

    supported_nucleotides: Set[str] = {
        'A', 'G', 'C', 'T', 'U',
        'R', 'Y', 'N', 'W', 'S',
        'M', 'K', 'B', 'H', 'D',
        'V'
    }

    reverse_complements: Dict[str, str] = {
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

    def __init__(self,
                 name: str,
                 definitions: List[str],
                 is_custom: bool = False,
                 is_public: bool = True):
        """
        :param name: Motif name
        :param definitions: One or more motif definitions (e.g. 'ACGTG')
        :param is_custom: True if the motif was user-defined
        :param is_public: True if the motif is a public/preset motif
        """
        self.name = name
        self.definitions = definitions
        self.is_custom = is_custom
        self.is_public = is_public

    @property
    def id(self) -> str:
        """Returns an ID for the motif, e.g. joining definitions by comma."""
        return ",".join(self.definitions)

    @staticmethod
    def validate(definitions: List[str]) -> Optional[str]:
        """
        Validate a list of definitions.
        :return: None if valid, or an error message.
        """
        if len(definitions) == 0:
            return "Definition cannot be empty"

        # Check invalid characters
        for definition in definitions:
            if not re.match(r"^[AGCTURYNWSMKBHDV]+$", definition):
                return "Motif definition contains invalid characters"
        return None

    @property
    def reg_exp(self) -> Dict[str, re.Pattern]:
        """
        :return: A dict of { 'ACTG': compiled_regex, ... } for all forward definitions
        """
        return {
            definition: self.to_reg_exp(definition)
            for definition in self.definitions
        }

    @property
    def reverse_complement_reg_exp(self) -> Dict[str, re.Pattern]:
        """
        :return: A dict of { 'GCAT': compiled_regex, ... } for all reverse-complement definitions
        """
        return {
            definition: self.to_reg_exp(definition)
            for definition in self.reverse_definitions
        }

    @property
    def reverse_definitions(self) -> List[str]:
        """
        :return: List of reverse-complement definitions
        """
        complements = []
        for definition in self.definitions:
            # Convert each code to its reverse complement
            complement_chars = []
            for char in definition:
                if char not in self.reverse_complements:
                    raise ValueError(f"Unsupported code `{char}`")
                complement_chars.append(self.reverse_complements[char])
            # Reverse and join
            complements.append("".join(reversed(complement_chars)))
        return complements

    @staticmethod
    def to_reg_exp(definition: str, strict: bool = False) -> re.Pattern:
        """
        Convert an IUPAC-like definition into a Python regex.
        :param definition: e.g. 'ACGT'
        :param strict: if True, anchors ^ and $ are added
        """
        pattern_parts = []
        if strict:
            pattern_parts.append('^')

        for char in definition:
            pattern_parts.append(Motif._nucleotide_code_to_reg_exp_part(char))

        if strict:
            pattern_parts.append('$')

        return re.compile("".join(pattern_parts))

    @staticmethod
    def _nucleotide_code_to_reg_exp_part(code: str) -> str:
        """
        Maps a single IUPAC character to a part of a regex.
        """
        if code == 'A':
            return 'A'
        elif code == 'G':
            return 'G'
        elif code == 'C':
            return 'C'
        elif code == 'T':
            return 'T'
        elif code == 'U':
            return 'U'
        elif code == 'R':
            return '[RAG]'
        elif code == 'Y':
            return '[YCT]'
        elif code == 'N':
            return '.'  # Matches any single character
        elif code == 'W':
            return '[WAT]'
        elif code == 'S':
            return '[SGC]'
        elif code == 'M':
            return '[MAC]'
        elif code == 'K':
            return '[KGT]'
        elif code == 'B':
            return '[BSYKGCT]'
        elif code == 'H':
            return '[HMYWACT]'
        elif code == 'D':
            return '[DRKWAGT]'
        elif code == 'V':
            return '[VRSMAGC]'
        else:
            raise ValueError(f"Unsupported code `{code}`")

    @staticmethod
    def drill_down_codes(code: str) -> Set[str]:
        """
        Returns possible single-nucleotide expansions for degenerate codes.
        """
        if code in ['A', 'G', 'C', 'T', 'U']:
            return set()
        elif code == 'R':
            return {'A', 'G'}
        elif code == 'Y':
            return {'C', 'T'}
        elif code == 'N':
            return Motif.supported_nucleotides
        elif code == 'W':
            return {'A', 'T'}
        elif code == 'S':
            return {'G', 'C'}
        elif code == 'M':
            return {'A', 'C'}
        elif code == 'K':
            return {'G', 'T'}
        elif code == 'B':
            return {'S', 'Y', 'K', 'G', 'C', 'T'}
        elif code == 'H':
            return {'M', 'Y', 'W', 'A', 'C', 'T'}
        elif code == 'D':
            return {'R', 'K', 'W', 'A', 'G', 'T'}
        elif code == 'V':
            return {'R', 'S', 'M', 'A', 'G', 'C'}
        else:
            raise ValueError(f"Unsupported code `{code}`")

    @classmethod
    def fromJson(cls, motif_json):
        """
        :param motif_json:
        :return:
        """
        name = motif_json.get('name')
        definitions = motif_json.get('definitions')
        is_custom = motif_json.get('is_custom', False)
        is_public = motif_json.get('is_public', True)
        return cls(name, definitions, is_custom, is_public)
