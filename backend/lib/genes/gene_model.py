import asyncio
from typing import List, Optional, Dict, Any

import aiofiles

from analysis.fasta_cache import FastaCache
from lib.analysis.analysis_series import AnalysisSeries
from lib.analysis.motif import Motif
from lib.analysis.organism import Organism
from lib.genes.gene_list import GeneList
from lib.genes.stage_selection import StageSelection

class AnalysisOptions:
    def __init__(
            self,
            min_val: int = 0,
            max_val: int = 10000,
            bucket_size: int = 30,
            align_marker: Optional[str] = None,
    ):
        self.min = min_val
        self.max = max_val
        self.bucketSize = bucket_size
        self.alignMarker = align_marker

    @classmethod
    def fromJson(cls, params):
        return cls(
            min_val=params.get("minimal", 0),
            max_val=params.get("maximal", 10000),
            bucket_size=params.get("bucket_size", 30),
            align_marker=params.get("align_marker", None)
        )

class GeneModel:
    """
    GeneModel is responsible for storing motifs, stages, and organism data
    for analysis. It does NOT handle UI logic.
    """

    def __init__(self):
        self.name: Optional[str] = None
        self._motifs: List["Motif"] = []
        self._stageSelection: Optional["StageSelection"] = None
        self.sourceGenes: Optional["GeneList"] = None
        self.analyses: List["AnalysisSeries"] = []
        self.analysisProgress: Optional[float] = None
        self.analysesHistory: List["AnalysisSeries"] = []
        self.analysisOptions: Optional["AnalysisOptions"] = None

    def setMotifs(self, newMotifs: List["Motif"]):
        self._motifs = newMotifs

    def setStageSelection(self, selection: Optional["StageSelection"]):
        print(f"✅ DEBUG: Setting stage selection inside of gene_model: {selection}")
        self._stageSelection = selection

    def getMotifs(self) -> List["Motif"]:
        return [name for name in self._motifs]
    def getSelectedStages(self) -> Optional["StageSelection"]:
        return self._stageSelection
    def getOptions(self) -> Optional["AnalysisOptions"]:
        return self.analysisOptions

    async def loadFastaFromFile(self, path: str, organism: Optional["Organism"]):
        cache = FastaCache.get_instance()
        gene_list = await cache.get_gene_list(path)

        if organism and organism.take_first_transcript_only:
            genes, errors = await GeneList.take_single_transcript(gene_list.genes, gene_list.errors)
            self.sourceGenes = GeneList.from_list(genes=genes, errors=errors, organism=organism)
        else:
            self.sourceGenes = gene_list.copy_with(organism=organism)

        self.name = organism.name if organism else None

    async def _loadFastaFromString(
            self,
            data: str,
            organism: Optional["Organism"]
    ):
        """
        Loads genes and transcript rates from FASTA data.
        """
        self.name = organism.name if organism else None
        takeSingleTranscript = organism.take_first_transcript_only if organism else True
        print(f"✅ DEBUG: Loading FASTA data for organism: {self.name}")
        print(f"✅ DEBUG: takeSingleTranscript is set to: {takeSingleTranscript}")
        genes, errors = await GeneList.parse_fasta(data)

        if takeSingleTranscript:
            genes, errors = await GeneList.take_single_transcript(genes, errors)

        self.sourceGenes = GeneList.from_list(genes=genes, errors=errors, organism=organism)

    @staticmethod
    def randomColorOf(text: str):
        hash_val = 0
        for ch in text:
            hash_val = ord(ch) + ((hash_val << 5) - hash_val)
        final_hash = abs(hash_val) % (256 * 256 * 256)
        red = (final_hash & 0xFF0000) >> 16
        green = (final_hash & 0xFF00) >> 8
        blue = (final_hash & 0xFF)
        return f"#{red:02X}{green:02X}{blue:02X}"

    async def _run_single_analysis(self, params):
        return await AnalysisSeries.run_async(
            gene_list=params['genes'],
            motif=params['motif'],
            name=params['name'],
            color=params['color'],
            minimal=params['min'],
            maximal=params['max'],
            bucket_size=params['interval'],
            align_marker=params['alignMarker'],
            no_overlaps=params.get('no_overlaps', True)
        )

    async def analyze(self) -> bool:
        try:
            if not self._stageSelection or not self._stageSelection.selectedStages:
                raise ValueError("No selected stages")

            if not self._motifs:
                raise ValueError("No motifs to analyze")

            if not self.sourceGenes:
                raise ValueError("No gene data available")

            if not self.analysisOptions:
                raise ValueError("Analysis options not configured")

            total_tasks = len(self._stageSelection.selectedStages) * len(self._motifs)
            completed_tasks = 0
            color_preferences = {}

            import multiprocessing
            cpu_count = multiprocessing.cpu_count()
            analysis_params = []

            for motif in self._motifs:
                for stage_key in self._stageSelection.selectedStages:
                    filteredGenes = (
                        self.sourceGenes if stage_key == "__ALL__"
                        else self.sourceGenes.filter(stage=stage_key, stageSelection=self._stageSelection)
                    )

                    if not filteredGenes or not filteredGenes.genes:
                        completed_tasks += 1
                        self.analysisProgress = completed_tasks / total_tasks
                        continue

                    name = f"{'all' if stage_key == '__ALL__' else stage_key} - {motif.name}"
                    color = color_preferences.get(f"{stage_key}_{motif.name}") or self.randomColorOf(name)

                    analysis_params.append({
                        'genes': filteredGenes,
                        'motif': motif,
                        'name': name,
                        'color': color,
                        'min': self.analysisOptions.min,
                        'max': self.analysisOptions.max,
                        'interval': self.analysisOptions.bucketSize,
                        'alignMarker': self.analysisOptions.alignMarker,
                        'no_overlaps': True,
                    })

            results = []

            batch_size = min(len(analysis_params), 2)

            for i in range(0, len(analysis_params), batch_size):
                batch = analysis_params[i:i + batch_size]

                batch_tasks = []
                for params in batch:
                    task = self._run_single_analysis(params)
                    batch_tasks.append(task)

                batch_results = await asyncio.gather(*batch_tasks)
                results.extend(batch_results)

                completed_tasks += len(batch)
                self.analysisProgress = completed_tasks / total_tasks

            self.analyses.extend(results)
            self.analysisProgress = 1.0
            return True
        except:
            return False


    def addAnalysisToHistory(self):
        self.analysesHistory.extend(self.analyses)


async def runAnalysis(params: Dict[str, Any]) -> "AnalysisSeries":
    """
    Runs a single motif analysis on a gene list.
    """
    return AnalysisSeries.run(
        gene_list=params['genes'],
        no_overlaps=True,
        minimal=params['min'],
        maximal=params['max'],
        bucket_size=params['interval'],
        align_marker=params['alignMarker'],
        motif=params['motif'],
        color=params['color'] if 'color' in params else GeneModel.randomColorOf(params['name']),
        name=params['name']
    )
