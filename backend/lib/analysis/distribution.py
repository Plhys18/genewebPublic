from typing import Optional, List, Dict, Set
from dataclasses import dataclass

from lib.analysis.analysis_result import AnalysisResult


class Distribution:
    def __init__(self,
                 min: int,
                 max: int,
                 bucket_size: int,
                 name: str,
                 color: Optional[str],
                 align_marker: Optional[str] = None):
        self.min = min
        self.max = max
        self.bucket_size = bucket_size
        self.align_marker = align_marker
        self.name = name
        self.color = color

        self._counts: Dict[int, int] = {}
        self._genes: Dict[int, Set[str]] = {}
        self._totalCount: int = 0
        self._totalGenesCount: int = 0
        self._totalGenesWithMotifCount: int = 0

    @property
    def totalCount(self) -> int:
        return self._totalCount

    @property
    def totalGenesCount(self) -> int:
        return self._totalGenesCount

    @property
    def totalGenesWithMotifCount(self) -> int:
        return self._totalGenesWithMotifCount

    @property
    def dataPoints(self) -> List["DistributionDataPoint"]:
        if not self._counts or not self._genes:
            return []

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
        counts: Dict[int, int] = {}
        gene_counts: Dict[int, Set[str]] = {}

        for result in results:
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
        return {
            "min": self.min,
            "max": self.max,
            "bucket_size": self.bucket_size,
            "name": self.name,
            "color": self.color,
            "align_marker": self.align_marker,
            "total_count": self._totalCount,
            "total_genes_count": self._totalGenesCount,
            "total_genes_with_motif_count": self._totalGenesWithMotifCount,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "Distribution":
        return cls(
            min=data["min"],
            max=data["max"],
            bucket_size=data["bucket_size"],
            name=data["name"],
            color=data.get("color"),
            align_marker=data.get("align_marker"),
        )


@dataclass
class DistributionDataPoint:
    min: int
    max: int
    count: int
    percent: float
    genes: Set[str]
    genes_percent: float

    @property
    def genesCount(self) -> int:
        return len(self.genes)

    @property
    def label(self) -> str:
        return f"<{self.min}; {self.max})"
