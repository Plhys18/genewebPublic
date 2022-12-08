import 'package:excel/excel.dart';
import 'package:geneweb/analysis/analysis.dart';

class AnalysisOutput {
  final Analysis analysis;

  AnalysisOutput(this.analysis);

  List<int>? toExcel(String fileName) {
    assert(analysis.geneList.genes.isNotEmpty);
    var excel = Excel.createExcel();
    final originalSheets = excel.sheets.keys;
    final headerCellStyle = CellStyle(backgroundColorHex: 'FFDDFFDD', bold: true);

    // genes
    Sheet genesSheet = excel['selected_genes'];
    genesSheet.appendRow([
      'Gene Id',
      'Matches',
      for (final key in analysis.geneList.genes.first.transcriptionRates.keys) key,
    ]);
    for (var i = 0; i < analysis.geneList.genes.length; i++) {
      final gene = analysis.geneList.genes[i];
      genesSheet.appendRow([
        gene.geneId,
        analysis.result?.where((g) => g.gene.geneId == gene.geneId).length,
        for (final key in analysis.geneList.genes.first.transcriptionRates.keys) gene.transcriptionRates[key],
      ]);
    }
    for (int i = 0; i < genesSheet.maxCols; i++) {
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerCellStyle;
    }
    for (int i = 0; i < genesSheet.maxRows; i++) {
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle = headerCellStyle;
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).cellStyle = headerCellStyle;
    }

    // distributions
    Sheet distributionSheet = excel['distribution'];
    distributionSheet.appendRow(['Interval', 'Genes with motif']);
    for (final dataPoint in analysis.distribution!.dataPoints!) {
      distributionSheet.appendRow([
        dataPoint.label,
        for (final gene in dataPoint.genes) gene,
      ]);
    }
    for (int i = 0; i < distributionSheet.maxCols; i++) {
      distributionSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerCellStyle;
    }
    for (int i = 0; i < distributionSheet.maxRows; i++) {
      distributionSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle = headerCellStyle;
    }

    for (var element in originalSheets) {
      excel.delete(element);
    }
    return excel.save(fileName: fileName);
  }
}
