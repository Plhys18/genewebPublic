import json
import re
from typing import List, Dict, Optional

class Gene:
    """
    Holds a single gene data
    """

    gene_id_reg_exp = re.compile(r"(?P<gene>[A-Za-z0-9+_.-]+)")
    markers_reg_exp = re.compile(r";MARKERS (?P<json>\{.*})$")
    transcription_rates_reg_exp = re.compile(r";TRANSCRIPTION_RATES (?P<json>\{.*})$")

    def __init__(
            self,
            gene_id: str,
            data: str,
            header: str,
            notes: List[str],
            transcription_rates: Optional[Dict[str, float]] = None,
            markers: Optional[Dict[str, int]] = None,
    ):
        """
        :param gene_id: Gene name, including splicing variant, e.g. 'ATG0001.1'
        :param data: Raw nucleotides data
        :param header: Header line (>GENE ID...)
        :param notes: Additional notes
        :param transcription_rates: Map of (stage -> expression level)
        :param markers: Map of marker name -> position
        """
        self.geneId = gene_id
        self.data = data
        self.header = header
        self.notes = notes
        self.transcriptionRates = transcription_rates if transcription_rates else {}
        self.markers = markers if markers else {}

        self._geneCode: Optional[str] = None

    @classmethod
    def from_fasta(cls, lines: List[str]) -> "Gene":
        header: Optional[str] = None
        gene_id: Optional[str] = None
        notes: List[str] = []
        data_lines: List[str] = []
        transcription_rates: Optional[Dict[str, float]] = None
        markers: Optional[Dict[str, int]] = None

        for line in lines:
            if not line.strip():
                continue
            if line[0] == '>':
                if header is not None:
                    raise Exception("Multiple header lines")
                header = line
                match = cls.gene_id_reg_exp.search(line)
                if match:
                    gene_id = match.group("gene")
                    # print(f"✅ DEBUG: Extracted gene_id = {gene_id} from header: {line}")
                else:
                    print(f"⚠️ WARNING: No gene_id found in header: {line}")

            elif line[0] == ';':
                t_rates_match = cls.transcription_rates_reg_exp.search(line)
                if t_rates_match:
                    transcription_rates_str = t_rates_match.group("json")
                    if transcription_rates_str and transcription_rates_str.strip():
                        transcription_rates = {
                            k: float(v) for k, v in json.loads(transcription_rates_str).items()
                        }

                markers_match = cls.markers_reg_exp.search(line)
                if markers_match:
                    markers_str = markers_match.group("json")
                    if markers_str and markers_str.strip():
                        markers = {
                            k: int(v) for k, v in json.loads(markers_str).items()
                        }

                notes.append(line)
            else:
                data_lines.append(line.strip().upper())

        if header is None or gene_id is None:
            raise Exception(f"Unable to parse: {lines}")

        sequence = "".join(data_lines)

        if markers and "atg" in markers:
            atg_pos = markers["atg"]
            codon = sequence[atg_pos - 1: atg_pos - 1 + 3]
            if codon not in ("ATG", "CAT"):
                print(f"❌ ERROR: Unexpected codon `{codon}` found at position {atg_pos}")

            if codon not in ("ATG", "CAT"):
                raise ValueError(
                    f"{gene_id}: Expected `ATG`/`CAT` at ATG position of {atg_pos}, got `{codon}` instead."
                )

        return cls(
            gene_id=gene_id,
            data=sequence,
            header=header,
            notes=notes,
            transcription_rates=transcription_rates or {},
            markers=markers or {},
        )

    def copy_with(
            self,
            gene_id: Optional[str] = None,
            data: Optional[str] = None,
            header: Optional[str] = None,
            notes: Optional[List[str]] = None,
            transcription_rates: Optional[Dict[str, float]] = None,
            markers: Optional[Dict[str, int]] = None,
    ) -> "Gene":
        """
        Returns a copy of the current Gene, optionally overriding some fields
        """
        return Gene(
            gene_id=gene_id if gene_id is not None else self.geneId,
            data=data if data is not None else self.data,
            header=header if header is not None else self.header,
            notes=notes if notes is not None else self.notes,
            transcription_rates=transcription_rates if transcription_rates is not None else self.transcriptionRates,
            markers=markers if markers is not None else self.markers,
        )

    @property
    def geneCode(self) -> str:
        """
        Returns the gene name without the splicing variant.
        E.g., if geneId = 'ATG0001.1', returns 'ATG0001'
        """
        if self._geneCode is None:
            items = self.geneId.split(".")
            cutoff = max(len(items) - 1, 1)
            self._geneCode = ".".join(items[:cutoff])
        return self._geneCode

    @property
    def geneSplicingVariant(self) -> str:
        """
        Returns the splicing variant of the gene.
        E.g., if geneId = 'ATG0001.1', returns '1'
        """
        return self.geneId.split(".")[-1]

    def __str__(self) -> str:
        """
        Replicates Dart's `toString()` => returns geneId
        """
        return self.geneId

    def to_dict(self) -> dict:
        """Serializes the Gene object to a dictionary."""
        return {
            "gene_id": self.geneId,
            "data": self.data,
            "header": self.header,
            "notes": self.notes,
            "transcription_rates": self.transcriptionRates,
            "markers": self.markers,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "Gene":
        """Deserializes a dictionary into a Gene object."""
        return cls(
            gene_id=data["gene_id"],
            data=data["data"],
            header=data["header"],
            notes=data["notes"],
            transcription_rates=data.get("transcription_rates", {}),
            markers=data.get("markers", {}),
        )