import csv
import re
from io import StringIO
from typing import Dict, Set, Optional, List

class StagesData:
    """
    Parses a CSV file with the format:
      stage1, stage2, stage3, ...
      #RRGGBB, #RRGGBB, #RRGGBB, ...
      gene1,  gene1,   gene3, ...
      gene2,  gene3,   gene4, ...
      ...
    The second row with colors is optional, but if present must be at row 2.
    """

    def __init__(
            self,
            stages: Dict[str, Set[str]],
            colors: Dict[str, str]
    ):
        """
        :param stages: A dict of stage -> set of gene IDs
        :param colors: A dict of stage -> color string (e.g. "#FF0000")
        """
        self.stages = stages
        self.colors = colors

    @classmethod
    def from_csv(cls, csv_data: str) -> "StagesData":
        """
        Factory method that reads a CSV string and returns StagesData.
        """
        # Parse CSV
        table = []
        csv_reader = csv.reader(StringIO(csv_data))
        for row in csv_reader:
            table.append(row)

        if len(table) < 2:
            raise ValueError("CSV must have at least 2 rows")

        # The first row are stage names
        stage_names = [x.strip() for x in table[0]]
        if not stage_names:
            raise ValueError("CSV must have at least 1 column")

        stages: Dict[str, Set[str]] = {}
        colors: Dict[str, str] = {}

        # Start from the second row
        # Row index 1 might be a color row
        for row_index in range(1, len(table)):
            row = table[row_index]
            # If this is the second row (index=1), try parse colors
            if row_index == 1:
                parsed_color_row = ColorRowParser.try_parse(row)
                if parsed_color_row is not None:
                    # We have a color row; store any color found
                    for i, color_str in enumerate(parsed_color_row):
                        stage = stage_names[i] if i < len(stage_names) else None
                        if stage and color_str:
                            colors[stage] = color_str
                    continue

            # Otherwise, treat it as a row of gene IDs
            for i, cell in enumerate(row):
                # Make sure we don't go out of bounds for stage_names
                if i >= len(stage_names):
                    break
                stage = stage_names[i]
                gene = cell.strip()
                if not gene:
                    continue
                if stage not in stages:
                    stages[stage] = set()
                stages[stage].add(gene)

        return cls(stages, colors)

# ---- ColorRowParser simulation ----

class ColorRowParser:
    """
    Mimics the logic of color_row_parser in Dart.
    If the row is recognized as a 'color row', we parse each cell
    as a color or None. Otherwise, we return None.
    """

    COLOR_REGEX = re.compile(r"^#[0-9A-Fa-f]{6}$")

    @staticmethod
    def try_parse(row: List[str]) -> Optional[List[Optional[str]]]:
        """
        Attempts to parse each cell in the row as a color (#RRGGBB).
        If at least one cell can be parsed as a color, we treat all
        cells as either color or None. If no cell looks like a color,
        return None.
        """
        parsed = []
        found_any_color = False

        for cell in row:
            cell_str = cell.strip()
            if ColorRowParser.COLOR_REGEX.match(cell_str):
                parsed.append(cell_str.upper())  # e.g. "#AABBCC"
                found_any_color = True
            else:
                # Could also check for empty => None
                # or other formats if needed
                parsed.append(None)

        if not found_any_color:
            return None
        return parsed
