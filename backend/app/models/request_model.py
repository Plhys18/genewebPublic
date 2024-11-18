from pydantic import BaseModel
from typing import List, Optional
from enum import Enum


class StartType(str, Enum):
    SEQUENCE_START = "SequenceStart"
    ATG = "ATG"


class TranscriptionType(str, Enum):
    MOST_TRANSCRIBED = "mostTranscribed"
    LEAST_TRANSCRIBED = "leastTranscribed"


class Species(BaseModel):
    id: Optional[str]
    name: Optional[str]


class GenomicInterval(BaseModel):
    startType: StartType
    genomicIntervalMin: int
    genomicIntervalMax: int
    bucketSize: int


class AnalyzedMotifs(BaseModel):
    ids: List[str]


class Genome(BaseModel):
    developmentStages: List[str]
    transcriptionType: TranscriptionType
    useGenesCount: bool
    genesCount: Optional[int]
    percentile: Optional[int]


class AnalysisRequest(BaseModel):
    species: Species
    genomicInterval: GenomicInterval
    analyzedMotifs: AnalyzedMotifs
    genome: Genome

