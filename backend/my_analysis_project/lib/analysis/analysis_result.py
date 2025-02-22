from typing import Any
from genes.gene import Gene
from analysis.motif import Motif

class AnalysisResult:
    """Holds the result of a single motif position in the gene"""

    def __init__(self, gene: Gene, motif: Motif, raw_position: float, position: float, match: str, matched_sequence: str):
        """
        :param gene: The gene the motif was found in
        :param motif: The motif that was found
        :param raw_position: The raw position of the motif (in the string, starting from 0)
        :param position: The position of the motif midpoint (in the string, starting from 0)
        :param match: The concrete motif definition that matched (e.g. 'ACTN')
        :param matched_sequence: The actual sequence that matched (e.g. 'ACTA')
        """
        self.gene = gene
        self.motif = motif
        self.raw_position = raw_position
        self.position = position
        self.match = match
        self.matched_sequence = matched_sequence

    @property
    def broad_match(self) -> str:
        """Returns a broader matched sequence"""
        safe_sequence = " " * 10 + self.gene.data + " " * 10
        return safe_sequence[int(self.raw_position) + 2 : int(self.raw_position) + len(self.match) + 18]
