from typing import Optional, List, Dict, Set
from dataclasses import dataclass

from my_analysis_project.lib.analysis.analysis_result import AnalysisResult


class Distribution:
    """
    Holds the result of series distribution
    """

    def __init__(self,
                 min: int,
                 max: int,
                 bucket_size: int,
                 name: str,
                 color: Optional[str],
                 align_marker: Optional[str] = None):
        """
        :param min: The minimum position to include in the distribution
        :param max: The maximum position to include in the distribution
        :param bucket_size: The bucket size to use for the distribution
        :param name: The name of the series
        :param color: The color of the series (optional)
        :param align_marker: The marker to which data is aligned (usually ATG or TSS)
        """
        self.min = min
        self.max = max
        self.bucket_size = bucket_size
        self.align_marker = align_marker
        self.name = name
        self.color = color

        self._counts: Optional[Dict[int, int]] = None
        self._genes: Optional[Dict[int, Set[str]]] = None
        self._totalCount: int = 0
        self._totalGenesCount: int = 0
        self._totalGenesWithMotifCount: int = 0

    @property
    def totalCount(self) -> int:
        """Total count of motifs"""
        return self._totalCount

    @property
    def totalGenesCount(self) -> int:
        """Total count of genes"""
        return self._totalGenesCount

    @property
    def totalGenesWithMotifCount(self) -> int:
        """Total count of genes with motif"""
        return self._totalGenesWithMotifCount

    @property
    def dataPoints(self) -> Optional[List["DistributionDataPoint"]]:
        """
        Returns the distribution as a list of DistributionDataPoint
        """
        if self._counts is None or self._genes is None:
            return None

        data_points = []
        num_buckets = (self.max - self.min) // self.bucket_size
        for i in range(num_buckets):
            dp_min = self.min + i * self.bucket_size
            dp_max = self.min + (i + 1) * self.bucket_size
            count_value = self._counts.get(i, 0)
            genes_set = self._genes.get(i, set())

            data_points.append(
                DistributionDataPoint(
                    min=dp_min,
                    max=dp_max,
                    count=count_value,
                    percent=(count_value / self._totalCount) if self._totalCount > 0 else 0.0,
                    genes=genes_set,
                    genes_percent=(len(genes_set) / self._totalGenesCount) if self._totalGenesCount > 0 else 0.0
                )
            )
        return data_points

    def run(self, results: List["AnalysisResult"], total_genes_count: int) -> None:
        """
        Calculates the distribution from the list of results.
        :param results: List of AnalysisResult
        :param total_genes_count: total number of genes
        """
        counts: Dict[int, int] = {}
        gene_counts: Dict[int, Set[str]] = {}

        for result in results:
            # Subtract align_marker offset if provided
            offset = 0
            if self.align_marker is not None and self.align_marker in result.gene.markers:
                offset = result.gene.markers[self.align_marker]

            position = result.position - offset
            if position < self.min or position > self.max:
                continue

            interval_index = int((position - self.min) // self.bucket_size)

            counts[interval_index] = counts.get(interval_index, 0) + 1

            if interval_index not in gene_counts:
                gene_counts[interval_index] = set()
            gene_counts[interval_index].add(result.gene.geneId)

        self._counts = counts
        self._genes = {k: v for k, v in gene_counts.items()}

        self._totalCount = len(results)
        self._totalGenesCount = total_genes_count
        self._totalGenesWithMotifCount = len({r.gene.geneId for r in results})



    def to_dict(self) -> dict:
        """Serializes the Distribution object to a dictionary."""
        return {
            "min": self.min,
            "max": self.max,
            "bucket_size": self.bucket_size,
            "name": self.name,
            "color": self.color,
            "align_marker": self.align_marker,
            "total_count": self._totalCount,
            "total_genes_count": self._totalGenesCount,
            "total_genes_with_motif_count": self._totalGenesWithMotifCount
        }

    @classmethod
    def from_dict(cls, data: dict) -> "Distribution":
        """Deserializes a dictionary into a Distribution object."""
        return cls(
            min=data["min"],
            max=data["max"],
            bucket_size=data["bucket_size"],
            name=data["name"],
            color=data.get("color"),
            align_marker=data.get("align_marker")
        )

@dataclass
class DistributionDataPoint:
    """
    Holds a datapoint of the distribution
    """
    min: int
    max: int
    count: int
    percent: float
    genes: Set[str]
    genes_percent: float

    @property
    def genesCount(self) -> int:
        """Number of genes in the set"""
        return len(self.genes)

    @property
    def label(self) -> str:
        """Interval label, e.g. '<0; 30)'"""
        return f"<{self.min}; {self.max})"
