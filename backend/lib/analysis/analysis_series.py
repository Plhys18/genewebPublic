from typing import List, Dict, Optional
import re
from genes.gene_list import GeneList
from analysis.analysis_result import AnalysisResult
from analysis.motif import Motif
from analysis.distribution import Distribution
from collections import defaultdict

class AnalysisSeries:
    """Represents one series in the analysis"""

    def __init__(self, gene_list: GeneList, motif: Motif, name: str, color: str, stroke: int = 4, visible: bool = True,
                 no_overlaps: bool = True, result: Optional[List[AnalysisResult]] = None,
                 distribution: Optional[Distribution] = None):
        """
        :param gene_list: The GeneList analysis was run on
        :param motif: The Motif that was searched
        :param name: The name of the series
        :param color: The color of the series
        :param stroke: The stroke width of the series
        :param visible: Whether the series is visible
        :param no_overlaps: Whether to filter overlapping matches
        :param result: The results of the analysis
        :param distribution: The distribution of the analysis
        """
        self.gene_list = gene_list
        self.motif = motif
        self.name = name
        self.color = color
        self.stroke = stroke
        self.visible = visible
        self.no_overlaps = no_overlaps
        self.result = result or []
        self.distribution = distribution

    def copy_with(self, color: Optional[str] = None, stroke: Optional[int] = None, visible: Optional[bool] = None):
        """Returns a copy of the AnalysisSeries with optional modifications"""
        return AnalysisSeries(
            gene_list=self.gene_list,
            motif=self.motif,
            name=self.name,
            color=color if color is not None else self.color,
            stroke=stroke if stroke is not None else self.stroke,
            visible=visible if visible is not None else self.visible,
            no_overlaps=self.no_overlaps,
            result=self.result,
            distribution=self.distribution
        )

    @classmethod
    def run(cls, gene_list: GeneList, motif: Motif, name: str, color: str, min: int, max: int,
            bucket_size: int, align_marker: Optional[str] = None, no_overlaps: bool = True,
            stroke: int = 4, visible: bool = True):
        """Runs the analysis on the given GeneList"""

        # Find matches
        results = []
        for gene in gene_list.genes:
            results.extend(cls._find_matches(gene, motif, no_overlaps))

        # Calculate the distribution
        distribution = Distribution(min=min, max=max, bucket_size=bucket_size, align_marker=align_marker,
                                    name=name, color=color)
        distribution.run(results, len(gene_list.genes))

        return cls(gene_list, motif, name, color, stroke, visible, no_overlaps, results, distribution)

    @property
    def results_map(self) -> Dict[str, List[AnalysisResult]]:
        """Returns the results as a dictionary mapping gene ID to a list of AnalysisResult"""
        results_dict = defaultdict(list)
        for result in self.result:
            results_dict[result.gene.gene_id].append(result)
        return results_dict

    @staticmethod
    def _find_matches(gene, motif, no_overlaps) -> List[AnalysisResult]:
        """Finds matches for the motif in the gene"""
        results = []
        definitions = {**motif.reg_exp, **motif.reverse_complement_reg_exp}

        for definition, regex in definitions.items():
            matches = [m for m in re.finditer(regex, gene.data)]
            for match in matches:
                mid_match_delta = len(match.group(0)) // 2
                results.append(AnalysisResult(
                    gene=gene,
                    motif=motif,
                    raw_position=match.start(),
                    position=match.start() + mid_match_delta,
                    match=definition,
                    matched_sequence=match.group(0),
                ))

        return AnalysisSeries.filter_overlapping_matches(results) if no_overlaps else results

    @staticmethod
    def filter_overlapping_matches(results: List[AnalysisResult]) -> List[AnalysisResult]:
        """Filters out matches that overlap each other"""
        results.sort(key=lambda r: r.raw_position)

        excluded_results = set()
        included_results = []

        for result in results:
            if result in excluded_results:
                continue
            included_results.append(result)
            excluded_results.update(
                e for e in results
                if e != result and e.raw_position >= result.raw_position
                and e.raw_position < result.raw_position + len(result.match)
            )

        return included_results

class DrillDownResult:
    """The result of a drill-down analysis"""

    def __init__(self, pattern: str, count: int, share: Optional[float], share_of_all: Optional[float]):
        """
        :param pattern: The pattern being analyzed
        :param count: The count of occurrences
        :param share: The share of occurrences in filtered results
        :param share_of_all: The share of occurrences in all results
        """
        self.pattern = pattern
        self.count = count
        self.share = share
        self.share_of_all = share_of_all
