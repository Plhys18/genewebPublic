import asyncio
import time
from typing import List, Dict, Set, Any, Optional, Tuple

import aiofiles

from my_analysis_project.lib.analysis.organism import Organism
from my_analysis_project.lib.genes.genes import Gene
from my_analysis_project.lib.genes.stage_selection import StageSelection, FilterSelection, FilterStrategy


class Series:
    """
    Minimal stand-in for the Series class (not shown here).
    In Dart, it holds a list of numeric values and can compute sum, etc.
    We replicate that logic.
    """
    def __init__(self, values: List[float]):
        self.values = values

    @property
    def sum(self) -> float:
        return sum(self.values)

    def to_dict(self) -> dict:
        return {
            "values": self.values,
            "sum": self.sum
        }

class GeneList:
    """
    Holds a list of genes
    """

    def __init__(
            self,
            organism: Optional["Organism"],
            genes: List["Gene"],
            stages: Optional[Dict[str, Set[str]]],
            colors: Optional[Dict[str, Any]],
            errors: List[Any]
    ):
        self.organism = organism
        self._genes = genes
        self.stages = stages
        self._colors = colors
        self.errors = errors
        self.transcriptionRates = self._transcription_rates(self._genes)

    def __eq__(self, other: object) -> bool:
        """
        Equatable-like comparison:
        List<Object?> get props => [genes, transcriptionRates];
        """
        if not isinstance(other, GeneList):
            return False
        return (
                self._genes == other._genes
                and self.transcriptionRates == other.transcriptionRates
        )

    def __hash__(self) -> int:
        """
        Not strictly needed, but to mimic Equatable we can do a simple hash:
        """
        return hash((tuple(self._genes), tuple(self.transcriptionRates.items())))

    @property
    def genes(self) -> List["Gene"]:
        """
        Exposes the internal list of genes
        """
        return self._genes

    @property
    def colors(self) -> Dict[str, Any]:
        """
        Map of stage->color
        """
        if self._colors is not None:
            return self._colors
        return self._colors_from_stages()

    @property
    def stroke(self) -> Dict[str, int]:
        """
        Stroke widths for each stage
        """
        return self._stroke_from_stages()

    @classmethod
    async def parse_fasta(
            cls,
            data: str,
    ) -> Tuple[List["Gene"], List[Any]]:
        """
        Parse fasta file into list of genes.
        Returns (genes, errors).
        """
        chunks = data.split('>')
        genes: List["Gene"] = []
        errors: List[Any] = []
        for i, chunk in enumerate(chunks):

            if not chunk.strip():
                continue

            lines = ('>' + chunk).split('\n')
            try:
                gene = Gene.from_fasta(lines)
                genes.append(gene)
            except Exception as e:
                errors.append(e)

        print(f".fasta parsing completed with {len(genes)} genes and {len(errors)} errors")
        return genes, errors

    @classmethod
    async def take_single_transcript(
            cls,
            genes: List["Gene"],
            errors: List[Any]
    ) -> Tuple[List["Gene"], List[Any]]:
        """
        Takes the first transcript from each gene only
        """
        from collections import defaultdict
        keys = defaultdict(list)

        for gene in genes:
            code = gene.geneCode
            keys[code].append(gene.geneId)

        merged: List["Gene"] = []
        cnt = 0
        key_list = list(keys.keys())

        for i, key in enumerate(key_list):

            keys[key].sort()
            first = keys[key][0]
            merged.append(next(g for g in genes if g.geneId == first))

        print(
            f".fasta transcript filtering completed with {len(merged)} genes "
            f"and {len(errors)} errors"
        )
        return merged, errors

    @classmethod
    def from_list(
            cls,
            genes: List["Gene"],
            errors: List[Any],
            organism: Optional["Organism"] = None
    ) -> "GeneList":
        """
        Create a new GeneList from a list of genes.
        """
        result = cls(
            organism=organism,
            genes=genes,
            stages=None,
            colors=None,
            errors=errors
        )
        print(
            f".fasta analysis completed with {len(result.genes)} genes "
            f"and {len(result.errors)} errors"
        )
        return result


    def to_dict(self) -> dict:
        return {
            "organism": self.organism.name if self.organism else None,
            "genes": [gene.to_dict() for gene in self._genes],
            "stages": {key: list(value) for key, value in self.stages.items()} if self.stages else None,
            "colors": self._colors if self._colors else None,
            "errors": self.errors
        }

    @classmethod
    def from_dict(cls, data: dict) -> "GeneList":
        organism = Organism(name=data["organism"]) if data["organism"] else None
        genes = [Gene.from_dict(g) for g in data["genes"]]
        return cls(
            organism=organism,
            genes=genes,
            stages={key: set(value) for key, value in data["stages"].items()} if data.get("stages") else None,
            colors=data.get("colors"),
            errors=data.get("errors", [])
        )

    def copy_with(
            self,
            organism: Optional["Organism"] = None,
            genes: Optional[List["Gene"]] = None,
            stages: Optional[Dict[str, Set[str]]] = None,
            colors: Optional[Dict[str, Any]] = None,
            errors: Optional[List[Any]] = None
    ) -> "GeneList":
        """
        Returns a new GeneList with some fields replaced.
        """
        return GeneList(
            organism=organism if organism is not None else self.organism,
            genes=genes if genes is not None else self._genes,
            stages=stages if stages is not None else self.stages,
            colors=colors if colors is not None else self._colors,
            errors=errors if errors is not None else self.errors,
        )

    @property
    def stageKeys(self) -> List[str]:
        """
        Get keys for all stages.
        This either uses self.stages or self.transcriptionRates.
        Returns stages in an order defined by organism's known stages (if any).
        """
        if self.stages is not None:
            detected = list(self.stages.keys())
        else:
            detected = list(self.transcriptionRates.keys())

        result = []
        if self.organism and len(self.organism.stages) > 0:
            # Use organism's stage order
            for stg in self.organism.stages:
                if stg.stage in detected:
                    result.append(stg.stage)
            for stage in detected:
                if stage not in result:
                    result.append(stage)
        else:
            result.extend(detected)
        return result

    @property
    def defaultSelectedStageKeys(self) -> List[str]:
        """
        Get keys for stages that should be selected by default
        """
        keys = self.stageKeys
        if self.organism and len(self.organism.stages) > 0:
            return [
                s.stage for s in self.organism.stages
                if s.is_checked_by_default and s.stage in keys
            ]
        return keys

    def filter(self, stage: str, stageSelection: "StageSelection") -> "GeneList":
        """
        Filters GeneList for a given stage, using either self.stages
        or applying the StageSelection logic for transcriptionRates.
        """
        assert stage in self.stageKeys, f"Unknown stage {stage}"
        if self.stages is not None:
            assert stage in self.stages and len(self.stages[stage]) > 0, f"No genes for stage {stage}"
            ids = self.stages[stage]
            return self.copy_with(genes=[g for g in self.genes if g.geneId in ids])
        else:
            assert stage in stageSelection.selectedStages
            self.genes.sort(
                key=lambda g: g.transcriptionRates[stage]
                if stage in g.transcriptionRates else 0.0
            )

            if stageSelection.selection == FilterSelection.percentile:
                if stageSelection.strategy == FilterStrategy.top:
                    return self.copy_with(genes=self._topPercentile(stageSelection.percentile, stage))
                else:
                    return self.copy_with(genes=self._bottomPercentile(stageSelection.percentile, stage))
            else:
                # FilterSelection.fixed
                if stageSelection.strategy == FilterStrategy.top:
                    return self.copy_with(genes=self._top(stageSelection.count))
                else:
                    return self.copy_with(genes=self._bottom(stageSelection.count))

    @staticmethod
    def _transcription_rates(genes: List["Gene"]) -> Dict[str, Series]:
        """
        Aggregates transcription rates across all genes for each stage
        """
        result: Dict[str, List[float]] = {}
        for gene in genes:
            for key, val in gene.transcriptionRates.items():
                if key not in result:
                    result[key] = []
                result[key].append(val)

        return {k: Series(v) for k, v in result.items()}

    def _top(self, count: int) -> List["Gene"]:
        """
        Return top N genes by expression (already sorted in ascending order),
        so we take from the end.
        """
        c = max(min(count, len(self.genes)), 0)
        return self.genes[-c:]

    def _bottom(self, count: int) -> List["Gene"]:
        """
        Return bottom N genes by expression (already sorted in ascending order).
        """
        c = max(min(count, len(self.genes)), 0)
        return self.genes[:c]

    def _topPercentile(self, percentile: float, transcriptionKey: str) -> List["Gene"]:
        """
        Return all genes whose total expression accumulates up to the given percentile
        from the top (descending).
        """
        series = self.transcriptionRates[transcriptionKey]
        total_rate = series.sum + 0.0001  # correction for floating point error
        reversed_genes = list(reversed(self.genes))
        rate_sum = 0.0
        i = 0
        result: List["Gene"] = []
        while rate_sum < total_rate * percentile and i < len(reversed_genes):
            g = reversed_genes[i]
            val = g.transcriptionRates.get(transcriptionKey, 0.0)
            result.append(g)
            rate_sum += val
            i += 1
        return result

    def _bottomPercentile(self, percentile: float, transcriptionKey: str) -> List["Gene"]:
        """
        Return all genes whose total expression accumulates up to the given percentile
        from the bottom (ascending).
        """
        series = self.transcriptionRates[transcriptionKey]
        total_rate = series.sum + 0.0001
        normal_genes = self.genes
        rate_sum = 0.0
        i = 0
        result: List["Gene"] = []
        while rate_sum < total_rate * percentile and i < len(normal_genes):
            g = normal_genes[i]
            val = g.transcriptionRates.get(transcriptionKey, 0.0)
            result.append(g)
            rate_sum += val
            i += 1
        return result

    def _colors_from_stages(self) -> Dict[str, Any]:
        """
        If the organism has known stages, build stage->color map
        """
        if self.organism and len(self.organism.stages) > 0:
            d = {}
            for s in self.organism.stages:
                d[s.stage] = s.color
            return d
        return {}

    def _stroke_from_stages(self) -> Dict[str, int]:
        """
        If the organism has known stages, build stage->stroke map
        """
        if self.organism and len(self.organism.stages) > 0:
            d = {}
            for s in self.organism.stages:
                d[s.stage] = s.stroke
            return d
        return {}

    @classmethod
    def load_from_file(cls, file_path: str) -> "GeneList":
        print(f"[DEBUG] Starting load_from_file with file_path: {file_path}")

        async def _load():
            print(f"[DEBUG] Opening file: {file_path}")
            async with aiofiles.open(file_path, 'r') as f:
                data = await f.read()
                print(f"[DEBUG] File read complete. Data size: {len(data)} bytes")

            last_update_time = time.time()

            print("[DEBUG] Starting FASTA parsing...")
            genes, errors = await cls.parse_fasta(data)
            print(f"[DEBUG] FASTA parsing complete. Parsed {len(genes)} genes, {len(errors)} errors.")

            print("[DEBUG] Creating GeneList instance...")
            return cls.from_list(genes=genes, errors=errors)

        print("[DEBUG] Running _load() in asyncio event loop...")
        result = asyncio.run(_load())
        print("[DEBUG] load_from_file completed successfully.")
        return result


