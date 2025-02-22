import io
import asyncio
import xlsxwriter

class AnalysisSeriesExport:
    """
    Responsible for exporting a single AnalysisSeries to Excel.
    """

    def __init__(self, series: "AnalysisSeries"):
        """
        :param series: The AnalysisSeries to export
        """
        self.series = series

    async def to_excel(
            self,
            file_name: str,
            progress_callback
    ) -> bytes:
        """
        Exports the series to Excel in memory.
        Returns the raw bytes of the generated Excel file.
        :param file_name: The desired file name (not strictly needed for in-memory generation).
        :param progress_callback: a function(progress: float) to be called with progress [0..1].
        """

        # Create a BytesIO stream for in-memory Excel
        output = io.BytesIO()

        # Create a Workbook
        workbook = xlsxwriter.Workbook(output, {"in_memory": True})

        # Define a header cell format
        header_format = workbook.add_format({
            "bold": True,
            "bg_color": "#DDFFDD"
        })

        # 1) selected_genes sheet
        genes_sheet = workbook.add_worksheet("selected_genes")

        # Gather stage names from the first gene’s transcriptionRates
        genes = self.series.geneList.genes
        if not genes:
            # If somehow no genes exist, just return empty file
            workbook.close()
            return output.getvalue()
        stages = list(genes[0].transcriptionRates.keys())

        # -- Write header row
        header_row = ["Gene Id", "Matches"] + stages
        for col_idx, header_text in enumerate(header_row):
            genes_sheet.write(0, col_idx, header_text, header_format)

        # Build results map
        results_map = self.series.resultsMap

        # Write data rows
        for i, gene in enumerate(genes):
            # Progress ~ 0..0.5
            if i % 1000 == 0:
                progress = (i / len(genes)) * 0.5
                progress_callback(progress)
                await asyncio.sleep(0.02)  # small delay to mimic Dart's Future.delayed

            row_idx = i + 1
            genes_sheet.write(row_idx, 0, gene.geneId, header_format)  # style first col
            count_matches = len(results_map.get(gene.geneId, []))
            genes_sheet.write(row_idx, 1, count_matches, header_format)  # style second col

            # Write transcription rates
            for c, stage in enumerate(stages, start=2):
                val = gene.transcriptionRates.get(stage)
                if val is not None:
                    genes_sheet.write(row_idx, c, float(val))
                else:
                    genes_sheet.write(row_idx, c, "")  # empty cell

        # 2) distribution sheet
        distribution_sheet = workbook.add_worksheet("distribution")
        distribution_sheet.write(0, 0, "Interval", header_format)
        distribution_sheet.write(0, 1, "Genes with motif", header_format)

        data_points = []
        if self.series.distribution and self.series.distribution.dataPoints:
            data_points = self.series.distribution.dataPoints
        else:
            data_points = []

        # Write distribution data
        for i, dp in enumerate(data_points):
            # Progress ~ 0.6..0.9
            if i % 100 == 0:
                partial_progress = 0.6 + (i / max(len(data_points), 1)) * 0.3
                progress_callback(partial_progress)
                await asyncio.sleep(0.02)

            row_idx = i + 1
            # First cell is label, style it
            distribution_sheet.write(row_idx, 0, dp.label, header_format)

            # Then each gene in dp.genes. Notice in Dart code, we do:
            # [TextCellValue(dataPoint.label), for gene in dataPoint.genes => cell...]
            # That places each gene in a new column.
            # So let's do that here. The second col is the first gene, etc.
            col_idx = 1
            for gene_id in dp.genes:
                distribution_sheet.write(row_idx, col_idx, gene_id)
                col_idx += 1

        # The Dart code also modifies the default sheet(s), removing them at the end.
        # XlsxWriter by default doesn't create an extra "Sheet1" if we name our own sheets.
        # So we don't need to "delete" the original sheets.

        # Finish workbook
        workbook.close()
        output.seek(0)
        return output.getvalue()
