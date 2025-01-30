import io
import asyncio
import xlsxwriter

class DistributionsExport:
    """
    Responsible for exporting multiple Distribution objects to Excel.
    """

    def __init__(self, distributions: list["Distribution"]):
        """
        :param distributions: a list of Distribution objects
        """
        self.distributions = distributions

    async def to_excel(
            self,
            file_name: str,
            progress_callback
    ) -> bytes:
        """
        Exports the distributions to Excel in memory.
        Returns the raw bytes of the generated Excel file.
        :param file_name: The desired file name (not strictly needed for in-memory generation).
        :param progress_callback: a function(progress: float) to be called with progress [0..1].
        """
        if not self.distributions:
            # If no distributions, return empty workbook
            return b""

        # Create an in-memory workbook
        output = io.BytesIO()
        workbook = xlsxwriter.Workbook(output, {"in_memory": True})

        header_format = workbook.add_format({
            "bold": True,
            "bg_color": "#DDFFDD"
        })

        # We gather the dataPoints from each distribution
        data_points_list = []
        for dist in self.distributions:
            if dist.dataPoints:
                data_points_list.append(dist.dataPoints)
            else:
                data_points_list.append([])

        # We'll assume all distributions have the same number of dataPoints
        # because in Dart code we reference `first.length` in the loops.
        # If they differ, we can handle it gracefully below.
        first_data_points = data_points_list[0] if data_points_list else []

        # 1) motifs sheet
        motifs_sheet = workbook.add_worksheet("motifs")

        # Write header row: 'Interval', 'Min', each distribution.name, '', each distribution.name + ' [%]'
        header_row = (
                ["Interval", "Min"]
                + [dist.name for dist in self.distributions]
                + [""]
                + [f"{dist.name} [%]" for dist in self.distributions]
        )
        for col_idx, cell_value in enumerate(header_row):
            motifs_sheet.write(0, col_idx, cell_value, header_format)

        # Write data rows
        for i, dp in enumerate(first_data_points):
            # partial progress ~ 0..0.5
            if i % 1000 == 0:
                progress = (i / max(len(first_data_points), 1)) * 0.5
                progress_callback(progress)
                await asyncio.sleep(0.02)

            row_idx = i + 1
            # Interval label
            motifs_sheet.write(row_idx, 0, dp.label, header_format)
            # Min
            motifs_sheet.write(row_idx, 1, dp.min, header_format)

            # Then each distribution's count
            col_idx = 2
            for dp_list in data_points_list:
                if i < len(dp_list):
                    motifs_sheet.write(row_idx, col_idx, dp_list[i].count)
                else:
                    motifs_sheet.write(row_idx, col_idx, "")
                col_idx += 1

            # Blank column
            motifs_sheet.write(row_idx, col_idx, "")
            col_idx += 1

            # Then each distribution's percent
            for dp_list in data_points_list:
                if i < len(dp_list):
                    motifs_sheet.write_number(row_idx, col_idx, dp_list[i].percent)
                else:
                    motifs_sheet.write(row_idx, col_idx, "")
                col_idx += 1

        # 2) genes sheet
        genes_sheet = workbook.add_worksheet("genes")

        # header row
        header_row_2 = (
                ["Interval", "Min"]
                + [dist.name for dist in self.distributions]
                + [""]
                + [f"{dist.name} [%]" for dist in self.distributions]
        )
        for col_idx, cell_value in enumerate(header_row_2):
            genes_sheet.write(0, col_idx, cell_value, header_format)

        # data rows
        for i, dp in enumerate(first_data_points):
            # partial progress ~ 0.5..1
            if i % 1000 == 0:
                progress = 0.5 + (i / max(len(first_data_points), 1)) * 0.5
                progress_callback(progress)
                await asyncio.sleep(0.02)

            row_idx = i + 1
            # Interval label
            genes_sheet.write(row_idx, 0, dp.label, header_format)
            # Min
            genes_sheet.write(row_idx, 1, dp.min, header_format)

            # Then each distribution's genesCount
            col_idx = 2
            for dp_list in data_points_list:
                if i < len(dp_list):
                    genes_sheet.write(row_idx, col_idx, dp_list[i].genesCount)
                else:
                    genes_sheet.write(row_idx, col_idx, "")
                col_idx += 1

            # Blank column
            genes_sheet.write(row_idx, col_idx, "")
            col_idx += 1

            # Then each distribution's genesPercent
            for dp_list in data_points_list:
                if i < len(dp_list):
                    genes_sheet.write_number(row_idx, col_idx, dp_list[i].genesPercent)
                else:
                    genes_sheet.write(row_idx, col_idx, "")
                col_idx += 1

        # Close out workbook
        workbook.close()
        output.seek(0)
        return output.getvalue()
