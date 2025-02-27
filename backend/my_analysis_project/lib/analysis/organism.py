from typing import Optional, List

from my_analysis_project.lib.analysis.stage_and_color import StageAndColor

class Organism:
    """
    Class that holds information about an organism
    """

    def __init__(
            self,
            name: str,
            filename: Optional[str] = None,
            description: Optional[str] = None,
            public: bool = False,
            take_first_transcript_only: bool = True,
            stages: Optional[List["StageAndColor"]] = None,
    ):
        """
        :param name: The name of the organism
        :param filename: The URL (or local file path) of the organism fasta file
        :param description: A short description of the organism
        :param public: Whether the organism is public
        :param take_first_transcript_only: Whether to take only the first transcript of each gene
        :param stages: Definition of how stages should be presented
        """
        self.name = name
        self.filename = filename
        self.description = description
        self.public = public
        self.take_first_transcript_only = take_first_transcript_only
        self.stages = stages if stages is not None else []
