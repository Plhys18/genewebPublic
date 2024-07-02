import 'package:excel/excel.dart';
import 'package:geneweb/analysis/analysis_series.dart';

/// Responsible for exporting the [series]
class AnalysisSeriesExport {
  final AnalysisSeries series;

  AnalysisSeriesExport(this.series);

  /// Exports the series to Excel
  Future<List<int>?> toExcel(String fileName, Function(double progress) progressCallback) async {
    assert(series.geneList.genes.isNotEmpty);
    var excel = Excel.createExcel();
    final originalSheets = excel.sheets.keys;
    final headerCellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('FFDDFFDD'), bold: true);

    // selected_genes sheet
    Sheet genesSheet = excel['selected_genes'];
    final stages = series.geneList.genes.first.transcriptionRates.keys.toList();
    // header row
    genesSheet.appendRow([
      const TextCellValue('Gene Id'),
      const TextCellValue('Matches'),
      for (final stage in stages) TextCellValue(stage),
    ]);
    // data rows
    final resultsMap = series.resultsMap;
    for (var i = 0; i < series.geneList.genes.length; i++) {
      if (i % 1000 == 0) {
        progressCallback(i / series.geneList.genes.length * 0.5);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      final gene = series.geneList.genes[i];
      genesSheet.appendRow([
        TextCellValue(gene.geneId),
        IntCellValue(resultsMap[gene.geneId]?.length ?? 0),
//        series.result?.where((g) => g.gene.geneId == gene.geneId).length,
        for (final stage in stages)
          gene.transcriptionRates[stage] == null
              ? const TextCellValue('')
              : DoubleCellValue(gene.transcriptionRates[stage]!.toDouble()),
      ]);
    }
    // style the header and first two columns
    for (int i = 0; i < genesSheet.maxColumns; i++) {
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerCellStyle;
    }
    for (int i = 0; i < genesSheet.maxRows; i++) {
      if (i % 1000 == 0) {
        progressCallback(0.5 + i / genesSheet.maxRows * 0.1);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle = headerCellStyle;
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).cellStyle = headerCellStyle;
    }

    // distribution sheet
    Sheet distributionSheet = excel['distribution'];
    distributionSheet.appendRow([const TextCellValue('Interval'), const TextCellValue('Genes with motif')]);
    int i = 0;
    final datapoints = series.distribution!.dataPoints!;
    for (final dataPoint in datapoints) {
      if (i++ % 100 == 0) {
        progressCallback(0.6 + i / datapoints.length * 0.3);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      distributionSheet.appendRow([
        TextCellValue(dataPoint.label),
        for (final gene in dataPoint.genes) TextCellValue(gene),
      ]);
    }
    for (int i = 0; i < distributionSheet.maxColumns; i++) {
      distributionSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerCellStyle;
    }
    for (int i = 0; i < distributionSheet.maxRows; i++) {
      if (i % 100 == 0) {
        progressCallback(0.9 + i / distributionSheet.maxRows * 0.1);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      distributionSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle = headerCellStyle;
    }

    for (var element in originalSheets) {
      excel.delete(element);
    }
    return excel.save(fileName: fileName);
  }
}
