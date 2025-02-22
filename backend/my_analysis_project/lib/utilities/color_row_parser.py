from typing import List, Optional

class ColorRowParser:
    """
    Checks the list of strings for a color value in #RRGGBB format
    and returns the list of color integers (ARGB) or None in place of invalid.
    This mimics the Dart code's behavior:
      If e.isEmpty => null
      else parse substring(1) as hex => color + 0xFF000000
    """

    @staticmethod
    def try_parse(row: List[str]) -> List[Optional[int]]:
        """
        :param row: The row of strings (e.g. ["#FF0000", "#00FF00", ""]).
        :return: A list of optional int (ARGB).
                 If parse fails for a cell, that cell is None.
        """
        colors: List[Optional[int]] = []
        for cell in row:
            cell = cell.strip()
            if not cell:
                # If empty => null
                colors.append(None)
                continue
            if len(cell) > 0 and cell[0] == '#' and len(cell) == 7:
                # Attempt to parse substring(1) as hex
                try:
                    parsed = int(cell[1:], 16)  # parse "RRGGBB" as hex
                    if 0 <= parsed <= 0xFFFFFF:
                        # Add 0xFF000000 for alpha channel
                        argb = 0xFF000000 | parsed
                        colors.append(argb)
                        continue
                except ValueError:
                    pass
            # If anything fails or doesn't match => null
            colors.append(None)
        return colors
