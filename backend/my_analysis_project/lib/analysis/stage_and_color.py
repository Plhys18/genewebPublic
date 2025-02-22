class StageAndColor:
    """
    Visual representation of an individual stage
    """

    def __init__(
            self,
            stage: str,
            color: str,
            stroke: int = 4,
            is_checked_by_default: bool = True
    ):
        """
        :param stage: The name of the stage
        :param color: The color of the stage. Here we'll store it as a string
                      (e.g. "#993300" or "orange"). In Dart it was a `Color`.
        :param stroke: The stroke width of the stage
        :param is_checked_by_default: Whether the stage is checked by default
        """
        self.stage = stage
        self.color = color
        self.stroke = stroke
        self.is_checked_by_default = is_checked_by_default
