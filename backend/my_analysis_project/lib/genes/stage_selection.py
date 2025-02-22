from enum import Enum
from typing import List, Optional

class FilterStrategy(Enum):
    top = "top"
    bottom = "bottom"

class FilterSelection(Enum):
    fixed = "fixed"
    percentile = "percentile"

class StageSelection:
    """
    Holds data for selected stages and TPM filtering to use (optional)
    """

    def __init__(
            self,
            selectedStages: Optional[List[str]] = None,
            strategy: Optional[FilterStrategy] = FilterStrategy.top,
            selection: Optional[FilterSelection] = FilterSelection.percentile,
            percentile: Optional[float] = 0.9,
            count: Optional[int] = 3200
    ):
        """
        :param selectedStages: List of selected stage names
        :param strategy: top or bottom
        :param selection: fixed or percentile
        :param percentile: used if selection == percentile
        :param count: used if selection == fixed
        """
        if selectedStages is None:
            selectedStages = []
        self.selectedStages = selectedStages
        self.strategy = strategy
        self.selection = selection
        self.percentile = percentile
        self.count = count

    def __str__(self) -> str:
        if self.strategy is None or self.selection is None:
            return f"{len(self.selectedStages)} stages"
        if self.selection == FilterSelection.fixed:
            return f"{len(self.selectedStages)} stages: {self.strategy.value} {self.count}"
        else:
            # percentile
            return f"{len(self.selectedStages)} stages: {self.strategy.value} {(self.percentile * 100):.0f}th"
