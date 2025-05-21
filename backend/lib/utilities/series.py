class Series:
    """
    A series of data points and some basic statistics on the series
    """

    def __init__(self, data: list):
        """
        :param data: A list of numeric values (ints or floats)
        :raises Exception: if data is empty
        """
        if not data:
            raise Exception("Empty data")

        self.data = sorted(data)  # sort ascending
        self.sum = self._sum(data)
        self.length = len(data)

    @property
    def min(self):
        """Returns the smallest value in the data."""
        return self.data[0]

    @property
    def max(self):
        """Returns the largest value in the data."""
        return self.data[-1]

    @property
    def mean(self) -> float:
        """Returns the average (sum / length)."""
        return float(self.sum) / self.length

    @staticmethod
    def _sum(values: list) -> float:
        """
        Sums numeric values in a list (replicating the private _sum function in Dart).
        """
        total = 0.0
        for v in values:
            total += v
        return total
