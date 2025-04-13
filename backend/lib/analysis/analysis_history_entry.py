from datetime import datetime
from typing import Dict, Any
from analysis_series import AnalysisSeries

class AnalysisHistoryEntry:
    """Represents a historical record of an analysis"""

    def __init__(self, id: str, timestamp: datetime, analysis_series: AnalysisSeries):
        """
        :param id: The unique identifier for the history entry
        :param timestamp: The timestamp when the analysis was run
        :param analysis_series: The AnalysisSeries that was run
        """
        self.id = id
        self.timestamp = timestamp
        self.analysis_series = analysis_series

    def to_json(self) -> Dict[str, Any]:
        """Convert to a JSON-compatible dictionary"""
        return {
            "id": self.id,
            "timestamp": self.timestamp.isoformat(),
            "analysisSeries": self.analysis_series.to_dict(),
        }

    @classmethod
    def from_json(cls, json_data: Dict[str, Any]) -> "AnalysisHistoryEntry":
        """Create an instance from a JSON-compatible dictionary"""
        return cls(
            id=json_data["id"],
            timestamp=datetime.fromisoformat(json_data["timestamp"]),
            analysis_series=AnalysisSeries.from_dict(json_data["analysisSeries"]),
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "timestamp": self.timestamp.isoformat(),
            "analysisSeries": self.analysis_series.to_dict(),
        }

    @classmethod
    def from_dict(cls, json_data: Dict[str, Any]) -> "AnalysisHistoryEntry":
        return cls(
            id=json_data["id"],
            timestamp=datetime.fromisoformat(json_data["timestamp"]),
            analysis_series=AnalysisSeries.from_dict(json_data["analysisSeries"]),
        )