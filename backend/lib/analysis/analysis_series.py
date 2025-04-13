import json
from concurrent.futures import ProcessPoolExecutor
from functools import partial
from typing import List, Dict, Optional, Any
import re
from collections import defaultdict


from lib.analysis.analysis_result import AnalysisResult
from lib.analysis.distribution import Distribution
from lib.analysis.motif import Motif
from lib.genes.gene_list import GeneList


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
    def run(cls, gene_list: GeneList, motif: Motif, name: str, color: str, minimal: int, maximal: int,
            bucket_size: int, align_marker: Optional[str] = None, no_overlaps: bool = True,
            stroke: int = 4, visible: bool = True):
        if len(gene_list.genes) < 10:
            results = []
            for gene in gene_list.genes:
                results.extend(cls._find_matches(gene, motif, no_overlaps))
        else:
            import multiprocessing
            optimal_workers = min(max(1, multiprocessing.cpu_count() - 1), len(gene_list.genes))

            chunk_size = max(1, len(gene_list.genes) // (optimal_workers * 4))

            results = []
            with ProcessPoolExecutor(max_workers=optimal_workers) as executor:
                find_matches_fn = partial(cls._find_matches, motif=motif, no_overlaps=no_overlaps)

                for batch_results in executor.map(find_matches_fn, gene_list.genes, chunksize=chunk_size):
                    results.extend(batch_results)

        distribution = Distribution(min=minimal, max=maximal, bucket_size=bucket_size, align_marker=align_marker,
                                    name=name, color=color)
        distribution.run(results, len(gene_list.genes))

        return cls(gene_list, motif, name, color, stroke, visible, no_overlaps, results, distribution)

    @property
    def results_map(self) -> Dict[str, List[AnalysisResult]]:
        """Returns the results as a dictionary mapping gene ID to a list of AnalysisResult"""
        results_dict = defaultdict(list)
        for result in self.result:
            results_dict[result.gene.geneId].append(result)
        return results_dict

    @staticmethod
    def _find_matches(gene, motif, no_overlaps) -> List[AnalysisResult]:
        try:
            results = []
            definitions = {**motif.reg_exp, **motif.reverse_complement_reg_exp}

            for definition, regex in definitions.items():
                if isinstance(regex, str):
                    compiled_regex = re.compile(regex)
                else:
                    compiled_regex = regex

                matches = list(compiled_regex.finditer(gene.data))

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

            if no_overlaps and results:
                return AnalysisSeries.filter_overlapping_matches(results)
            return results
        except Exception as e:
            logger.error(f"Error finding matches in gene {gene.geneId}: {e}")
            return []

    @staticmethod
    def filter_overlapping_matches(results: List[AnalysisResult]) -> List[AnalysisResult]:
        if not results:
            return []

        results.sort(key=lambda r: r.raw_position)

        included_results = []
        last_end_pos = -1

        for result in results:
            current_start = result.raw_position
            current_end = current_start + len(result.matched_sequence)

            if current_start >= last_end_pos:
                included_results.append(result)
                last_end_pos = current_end

        return included_results

    def toJson(self) -> str:
        return json.dumps(self.to_dict())

    def to_dict(self) -> Dict[str, Any]:
        return {
            "geneList": self.gene_list.to_dict(),
            "motif": self.motif.to_dict(),
            "name": self.name,
            "color": self.color,
            "stroke": self.stroke,
            "visible": self.visible,
            "no_overlaps": self.no_overlaps,
            "result": [r.to_dict() for r in self.result] if self.result else [],
            "distribution": self.distribution.to_dict() if self.distribution else None,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "AnalysisSeries":
        gene_list = GeneList.from_dict(data["geneList"])
        motif = Motif.from_dict(data["motif"])
        result = [AnalysisResult.from_dict(r) for r in data.get("result", [])]
        distribution = (Distribution.from_dict(data["distribution"])
                        if data.get("distribution") is not None else None)
        return cls(
            gene_list=gene_list,
            motif=motif,
            name=data["name"],
            color=data["color"],
            stroke=data["stroke"],
            visible=data["visible"],
            no_overlaps=data["no_overlaps"],
            result=result,
            distribution=distribution,
        )

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


    def to_dict(self) -> Dict[str, Any]:
        return {
            "pattern": self.pattern,
            "count": self.count,
            "share": self.share,
            "shareOfAll": self.share_of_all,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "DrillDownResult":
        return cls(
            pattern=data["pattern"],
            count=data["count"],
            share=data.get("share"),
            share_of_all=data.get("shareOfAll"),
        )

