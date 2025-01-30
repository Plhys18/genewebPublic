import csv
import re
from io import StringIO
from typing import Dict, Optional, List

class TPMData:
    """
    Parses a CSV file with the format:
      geneId,  stage1,  stage2,  stage3, ...
      (ignored),#RRGGBB,#RRGGBB, #RRGGBB, ...
      gene1,   0.1,     14.5,    0.04, ...
      gene2,   2.1,             3.14, ...
      gene4,   26.2,    19.79,   99.66, ...
    The second row with colors is optional, but if present must be at row 2.
    """

    def __init__(
            self,
            stages: Dict[str, Dict[str, float]],
            colors: Dict[str, str]
    ):
        """
        :param stages: A dict of stage -> (dict of geneId -> TPM float)
        :param colors: A dict of stage -> color string (e.g. "#FF0000")
        """
        self.stages = stages
        self.colors = colors

    @classmethod
    def from_csv(cls, csv_data: str) -> "TPMData":
        """
        Factory method that reads a CSV string and returns TPMData.
        """
        table = []
        csv_reader = csv.reader(StringIO(csv_data))
        for row in csv_reader:
            table.append(row)

        if len(table) < 2:
            raise ValueError("CSV must have at least 2 rows")

        # The first row are columns: [geneId, stage1, stage2, stage3, ...]
        stage_names = [x.strip() for x in table[0]]
        if len(stage_names) <= 1:
            raise ValueError("CSV must have at least 2 columns (geneId + at least 1 stage)")

        # We store stage->(gene->TPM)
        stages: Dict[str, Dict[str, float]] = {}
        colors: Dict[str, str] = {}

        for row_index in range(1, len(table)):
            row = table[row_index]
            # If this is the second row, try parse a color row (excluding first cell which is geneId)
            if row_index == 1:
                parsed_color_row = ColorRowParser.try_parse(row)
                if parsed_color_row is not None:
                    # We found a color row for columns 1..N
                    for i in range(1, len(parsed_color_row)):
                        color_str = parsed_color_row[i]
                        if i < len(stage_names):
                            stage = stage_names[i]
                            if color_str:
                                colors[stage] = color_str
                    continue

            if not row:
                continue

            # The first cell is the geneId
            gene_id = row[0].strip()
            if not gene_id:
                continue

            # The rest are stage values
            for i in range(1, len(row)):
                # stage_names[i] is the stage label
                if i >= len(stage_names):
                    break
                stage = stage_names[i]
                cell_str = row[i].strip()
                if not cell_str:
                    continue
                try:
                    tpm_val = float(cell_str)
                except ValueError:
                    # Not a valid float => skip
                    continue

                if stage not in stages:
                    stages[stage] = {}
                stages[stage][gene_id] = tpm_val

        return cls(stages, colors)

# ---- ColorRowParser (same as above) ----

class ColorRowParser:
    COLOR_REGEX = re.compile(r"^#[0-9A-Fa-f]{6}$")

    @staticmethod
    def try_parse(row: List[str]) -> Optional[List[Optional[str]]]:
        parsed = []
        found_any_color = False

        for cell in row:
            cell_str = cell.strip()
            if ColorRowParser.COLOR_REGEX.match(cell_str):
                parsed.append(cell_str.upper())
                found_any_color = True
            else:
                parsed.append(None)

        if not found_any_color:
            return None
        return parsed
