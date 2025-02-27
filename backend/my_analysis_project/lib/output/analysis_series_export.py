import io
import asyncio
import xlsxwriter

from my_analysis_project.lib.analysis.analysis_series import AnalysisSeries


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
            file_name: str
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
        genes = self.series.gene_list.genes
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
        results_map = self.series.results_map

        # Write data rows
        for i, gene in enumerate(genes):
            row_idx = i + 1
            genes_sheet.write(row_idx, 0, gene.geneId, header_format)
            count_matches = len(results_map.get(gene.geneId, []))
            genes_sheet.write(row_idx, 1, count_matches, header_format)

            for c, stage in enumerate(stages, start=2):
                val = gene.transcriptionRates.get(stage)
                if val is not None:
                    genes_sheet.write(row_idx, c, float(val))
                else:
                    genes_sheet.write(row_idx, c, "")

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

            row_idx = i + 1
            distribution_sheet.write(row_idx, 0, dp.label, header_format)
            col_idx = 1
            for gene_id in dp.genes:
                distribution_sheet.write(row_idx, col_idx, gene_id)
                col_idx += 1

        #
        workbook.close()
        output.seek(0)
        return output.getvalue()
