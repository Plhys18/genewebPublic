import asyncio
from typing import List, Optional, Dict, Any

# from genes.gene_list import GeneList
# from analysis.analysis_series import AnalysisSeries
# from analysis.analysis_options import AnalysisOptions
# from analysis.motif import Motif
# from analysis.organism import Organism

class DeploymentFlavor:
    """
    Mimic the enum from Dart (prod, dev, etc.) if needed.
    We'll just define 'prod' for demonstration.
    """
    prod = "prod"

class AnalysisOptions:
    """
    Minimal stand-in to match usage in GeneModel.
    """
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
    Main model for the UI app
    """

    kAllStages = "__ALL__"

    def __init__(self, deployment_flavor: Optional[str] = None):
        self.deploymentFlavor = deployment_flavor
        self._publicSite = deployment_flavor == DeploymentFlavor.prod
        self._isSignedIn = False
        self._analysisCancelled = False

        self.name: Optional[str] = None
        self.sourceGenes: Optional["GeneList"] = None
        self.analyses: List["AnalysisSeries"] = []
        self.analysesHistory: List["AnalysisSeries"] = []
        self.analysisProgress: Optional[float] = None
        self.analysisOptions = AnalysisOptions()
        self._stageSelection: Optional["StageSelection"] = None
        self._motifs: List["Motif"] = []
        self._allMotifs: List["Motif"] = []

    def notifyListeners(self):
        """
        Placeholder for Dart's ChangeNotifier behavior
        """
        pass

    @property
    def publicSite(self) -> bool:
        return self._publicSite

    @property
    def isSignedIn(self) -> bool:
        return self._isSignedIn

    @isSignedIn.setter
    def isSignedIn(self, value: bool):
        self._isSignedIn = value
        self.notifyListeners()

    @property
    def analysisCancelled(self) -> bool:
        return self._analysisCancelled

    @property
    def stageSelection(self) -> Optional["StageSelection"]:
        return self._stageSelection

    @property
    def motifs(self) -> List["Motif"]:
        return self._motifs

    @property
    def allMotifs(self) -> List["Motif"]:
        return self._allMotifs

    @allMotifs.setter
    def allMotifs(self, newMotifs: List["Motif"]):
        self._allMotifs = newMotifs

    @property
    def expectedSeriesCount(self) -> int:
        """
        Number of series the analysis will produce
        = len(motifs) * len(stageSelection.selectedStages)
        """
        if not self.stageSelection or not self.stageSelection.selectedStages:
            return 0
        return len(self.motifs) * len(self.stageSelection.selectedStages)

    def _reset(self, preserveSource: bool = False):
        if not preserveSource:
            self.name = None
            self.sourceGenes = None
        self.analyses = []
        self.analysisProgress = None
        self.analysisOptions = AnalysisOptions()
        self._stageSelection = None
        self._motifs = []

    def cancelAnalysis(self):
        self._analysisCancelled = True
        self.notifyListeners()

    def setPublicSite(self, value: bool):
        """
        TODO private
        """
        if self.deploymentFlavor is not None:
            raise Exception("Flavor is defined by deployment")
        self._publicSite = value
        self.notifyListeners()

    def setAnalyses(self, analyses: List["AnalysisSeries"]):
        self.analyses = analyses
        self.notifyListeners()

    def setMotifs(self, newMotifs: List["Motif"]):
        self._motifs = newMotifs
        self.notifyListeners()

    def setStageSelection(self, selection: Optional["StageSelection"]):
        self._stageSelection = selection
        self.notifyListeners()

    def setOptions(self, options: AnalysisOptions):
        self.analyses = []
        self.analysisProgress = None
        self.analysisOptions = options
        self.notifyListeners()

    def removeAnalysis(self, name: str):
        self.analyses = [a for a in self.analyses if a.name != name]
        self.notifyListeners()

    def removeAnalyses(self):
        self.analyses = []
        self.notifyListeners()

    async def reAnalyze(self):
        await self.analyze()

    async def analyzeNew(self):
        self._reset(preserveSource=True)
        await self.analyze()

    def resetAnalysisOptions(self):
        """
        If the first gene has markers, pick one to align on. Otherwise defaults.
        """
        if self.sourceGenes and self.sourceGenes.genes:
            gene = self.sourceGenes.genes[0]
            alignMarkers = sorted(list(gene.markers.keys()))
            if alignMarkers:
                self.analysisOptions = AnalysisOptions(
                    min_val=-1000,
                    max_val=1000,
                    bucket_size=30,
                    align_marker=alignMarkers[0]
                )
            else:
                self.analysisOptions = AnalysisOptions()
        else:
            self.analysisOptions = AnalysisOptions()

    def resetFilter(self):
        """
        Set default filter based on whether we have stage data or not
        """
        from .stage_selection import StageSelection, FilterStrategy, FilterSelection
        if self.sourceGenes:
            selectedStages = self.sourceGenes.defaultSelectedStageKeys
        else:
            selectedStages = []
        if self.sourceGenes and self.sourceGenes.stages is not None:
            # If we have stage membership, no advanced filter needed
            self._stageSelection = StageSelection(
                selectedStages=[self.kAllStages, *selectedStages],
                strategy=None,
                selection=None,
                percentile=None,
                count=None
            )
        else:
            # Use top percentile approach
            self._stageSelection = StageSelection(
                selectedStages=[self.kAllStages, *selectedStages],
                strategy=FilterStrategy.top,
                selection=FilterSelection.percentile,
                percentile=0.9,
                count=3200
            )

    async def loadFastaFromString(
            self,
            data: str,
            organism: Optional["Organism"],
            progressCallback
    ):
        """
        Loads genes and transcript rates from .fasta data
        """
        self._reset()
        self.name = organism.name if organism else None

        takeSingleTranscript = True
        if organism is not None:
            takeSingleTranscript = organism.take_first_transcript_only

        from .gene_list import GeneList

        genes, errors = await GeneList.parse_fasta(
            data,
            (lambda v: progressCallback(v / 2)) if takeSingleTranscript else progressCallback
        )
        if takeSingleTranscript:
            genes, errors = await GeneList.take_single_transcript(
                genes,
                errors,
                (lambda v: progressCallback(0.5 + v / 2))
            )

        self.sourceGenes = GeneList.from_list(
            genes=genes,
            errors=errors,
            organism=organism
        )
        self.resetAnalysisOptions()
        self.resetFilter()
        self.notifyListeners()

    async def loadFastaFromFile(
            self,
            path: str,
            filename: Optional[str],
            organism: Optional["Organism"],
            progressCallback
    ):
        """
        Reads fasta from file
        """
        import aiofiles
        async with aiofiles.open(path, 'r') as f:
            data = await f.read()
        await self.loadFastaFromString(data=data, organism=organism, progressCallback=progressCallback)

    def loadStagesFromString(self, data: str) -> bool:
        """
        Loads info about stages and colors from CSV file
        See [StagesData]
        """
        self._reset(preserveSource=True)
        assert self.sourceGenes is not None, "No sourceGenes to load stages into"

        from .stages_data import StagesData
        stages_data = StagesData.from_csv(data)
        errors: List[Any] = []
        gene_ids = set(g.geneId for g in self.sourceGenes.genes)
        for stageKey, genesInStage in stages_data.stages.items():
            diff = genesInStage - gene_ids
            if diff:
                errors.append(
                    f"Found {len(diff)} genes in stage {stageKey} that are not in the gene list: "
                    f"{', '.join(list(diff)[:3])}{'…' if len(diff) > 3 else ''}"
                )

        new_errors = None
        if errors:
            new_errors = errors + self.sourceGenes.errors

        self.sourceGenes = self.sourceGenes.copy_with(
            stages=stages_data.stages,
            colors=stages_data.colors,
            errors=new_errors
        )
        self.resetAnalysisOptions()
        self.resetFilter()
        self.notifyListeners()
        return not errors

    async def loadStagesFromFile(self, path: str) -> bool:
        import aiofiles
        async with aiofiles.open(path, 'r') as f:
            data = await f.read()
        return self.loadStagesFromString(data)

    def loadTPMFromString(self, data: str) -> bool:
        """
        Loads TPM data for individual stages from CSV file
        See [StagesData] or [TPMData]
        """
        self._reset(preserveSource=True)
        assert self.sourceGenes is not None, "No sourceGenes to load TPM into"

        from .tpm_data import TPMData
        tpm = TPMData.from_csv(data)

        errors: List[Any] = []
        new_genes = []
        for g in self.sourceGenes.genes:
            # Must have a TPM value for each stage
            missing_stage = any(tpm.stages[stage].get(g.geneId) is None for stage in tpm.stages)
            if not missing_stage:
                # Rebuild transcriptionRates
                new_rates = {}
                for stage in tpm.stages:
                    val = tpm.stages[stage][g.geneId]
                    new_rates[stage] = val
                new_genes.append(g.copy_with(transcription_rates=new_rates))

        if len(new_genes) != len(self.sourceGenes.genes):
            count_excluded = len(self.sourceGenes.genes) - len(new_genes)
            errors.append(f"{count_excluded} genes excluded due to lack of TPM data")

        new_errors = None
        if errors:
            new_errors = errors + self.sourceGenes.errors

        self.sourceGenes = self.sourceGenes.copy_with(
            genes=new_genes,
            errors=new_errors,
            colors=tpm.colors
        )
        self.resetAnalysisOptions()
        self.resetFilter()
        self.notifyListeners()
        return not errors

    async def loadTPMFromFile(self, path: str) -> bool:
        import aiofiles
        async with aiofiles.open(path, 'r') as f:
            data = await f.read()
        return self.loadTPMFromString(data)

    def reset(self):
        self._reset()
        self.notifyListeners()

    async def analyze(self) -> bool:
        """
        Runs analysis for all selected stages and motifs
        """
        assert self.stageSelection is not None, "No stageSelection"
        assert len(self.stageSelection.selectedStages) > 0, "No selected stages"
        assert len(self.motifs) > 0, "No motifs to analyze"

        totalIterations = len(self.stageSelection.selectedStages) * len(self.motifs)
        assert totalIterations > 0
        iterations = 0
        self.analysisProgress = 0.0
        self._analysisCancelled = False
        self.notifyListeners()

        from random import randint
        from .gene_list import GeneList
        for motif in self.motifs:
            for key in self.stageSelection.selectedStages:
                # small artificial delay
                await asyncio.sleep(0.05)

                if self._analysisCancelled:
                    self.analysisProgress = None
                    self.notifyListeners()
                    return False

                if key == self.kAllStages:
                    filteredGenes = self.sourceGenes
                else:
                    filteredGenes = self.sourceGenes.filter(stage=key, stageSelection=self.stageSelection)

                name = f"{'all' if key == self.kAllStages else key} - {motif.name}"
                # pick color
                if self.sourceGenes and self.sourceGenes.colors:
                    color = self.sourceGenes.colors.get(key, "#888888")  # fallback grey
                else:
                    color = self._randomColorOf(name)

                stroke = 4 if key == self.kAllStages else (self.sourceGenes.stroke.get(key) if self.sourceGenes else 4)

                self.removeAnalysis(name)

                # run analysis
                analysis = await runAnalysis({
                    'genes': filteredGenes,
                    'motif': motif,
                    'name': name,
                    'min': self.analysisOptions.min,
                    'max': self.analysisOptions.max,
                    'interval': self.analysisOptions.bucketSize,
                    'alignMarker': self.analysisOptions.alignMarker,
                    # Store the color as an integer-like if you want to replicate
                    # or keep it as a string
                    'color': color,
                    'stroke': stroke,
                })
                self.analyses.append(analysis)
                iterations += 1
                self.analysisProgress = iterations / totalIterations
                self.notifyListeners()

        self.analysisProgress = None
        self.notifyListeners()
        return True

    def _randomColorOf(self, text: str):
        """
        Mimic the Dart hashing approach for a color.
        We'll return a hex string like '#RRGGBB'
        """
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
    Runs the analysis (isolate in Dart). In Python, just a normal async function.
    """
    from analysis.analysis_series import AnalysisSeries
    from analysis.motif import Motif
    from genes.gene_list import GeneList
    # color might be a string or int. We'll unify it:
    color_param = params['color']

    # We replicate the code from AnalysisSeries.run
    analysis = AnalysisSeries.run(
        gene_list=params['genes'],
        no_overlaps=True,
        min=params['min'],
        max=params['max'],
        bucket_size=params['interval'],
        align_marker=params['alignMarker'],
        motif=params['motif'],
        name=params['name'],
        color=color_param,
        stroke=params['stroke']
    )
    return analysis
