import asyncio
from typing import List, Optional, Dict, Any

import aiofiles

from my_analysis_project.lib.analysis.analysis_series import AnalysisSeries
from my_analysis_project.lib.analysis.motif import Motif
from my_analysis_project.lib.analysis.organism import Organism
from my_analysis_project.lib.genes.gene_list import GeneList
from my_analysis_project.lib.genes.stage_selection import StageSelection


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

class GeneModel:
    """
    GeneModel is responsible for storing motifs, stages, and organism data
    for analysis. It does NOT handle UI logic.
    """

    def __init__(self):
        # ✅ Store the organism being analyzed
        self.name: Optional[str] = None

        # ✅ Store the motifs & stages
        self._motifs: List["Motif"] = []
        self._stageSelection: Optional["StageSelection"] = None

        # ✅ Store the FASTA file data (genes)
        self.sourceGenes: Optional["GeneList"] = None

        # ✅ Store analysis results
        self.analyses: List["AnalysisSeries"] = []
        self.analysisProgress: Optional[float] = None
        self.analysesHistory: List["AnalysisSeries"] = []
        self.analysisOptions = AnalysisOptions()
        # ✅ Store analysis options (params)
        self.analysisOptions = {
            "min": -1000,
            "max": 1000,
            "bucket_size": 30,
            "alignMarker": None
        }

    # ✅ Set motifs (must be actual Motif objects)
    def setMotifs(self, newMotifs: List["Motif"]):
        self._motifs = newMotifs

    # ✅ Set selected stages (must be a StageSelection object)
    def setStageSelection(self, selection: Optional["StageSelection"]):
        print(f"✅ DEBUG: Setting stage selection inside of gene_model: {selection}")
        self._stageSelection = selection

    # ✅ Load FASTA file data
    async def loadFastaFromFile(
            self,
            path: str,
            organism: Optional["Organism"]
    ):
        async with aiofiles.open(path, 'r') as f:
            data = await f.read()
        await self._loadFastaFromString(data, organism)

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

        genes, errors = await GeneList.parse_fasta(data)

        if takeSingleTranscript:
            genes, errors = await GeneList.take_single_transcript(genes, errors)

        self.sourceGenes = GeneList.from_list(genes=genes, errors=errors, organism=organism)

    async def analyze(self) -> bool:
        """
        Runs analysis using the set motifs, stages, and organism.
        """
        print("✅ DEBUG: Running analysis")
        print(f"✅ DEBUG: Stages: {self._stageSelection.selectedStages}")
        print(f"✅ DEBUG: Stageslen: {len(self._stageSelection.selectedStages)}")
        assert len(self._stageSelection.selectedStages) > 0, "No selected stages"
        assert len(self._motifs) > 0, "No motifs to analyze"
        print("✅ DEBUG: Stages and motifs are set starting analysis")
        totalIterations = len(self._stageSelection.selectedStages) * len(self._motifs)
        assert totalIterations > 0

        iterations = 0

        for motif in self._motifs:
            for key in self._stageSelection.selectedStages:
                filteredGenes = (
                    self.sourceGenes if key == "__ALL__"
                    else self.sourceGenes.filter(stage=key, stageSelection=self._stageSelection)
                )

                name = f"{'all' if key == '__ALL__' else key} - {motif.name}"

                analysis = await runAnalysis({
                    'genes': filteredGenes,
                    'motif': motif,
                    'name': name,
                    'min': self.analysisOptions["min"],
                    'max': self.analysisOptions["max"],
                    'interval': self.analysisOptions["bucket_size"],
                    'alignMarker': self.analysisOptions["alignMarker"]
                })

                self.analyses.append(analysis)
                iterations += 1
                print(f"✅ DEBUG: Completed {iterations}/{totalIterations} iterations")
        return True

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
