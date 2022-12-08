import 'package:excel/excel.dart';
import 'package:geneweb/analysis/distribution.dart';

class DistributionsOutput {
  final List<Distribution> distributions;

  DistributionsOutput(this.distributions);

  List<int>? toExcel(String fileName) {
    assert(distributions.isNotEmpty);
    var excel = Excel.createExcel();
    final originalSheets = excel.sheets.keys;
    final headerCellStyle = CellStyle(backgroundColorHex: 'FFDDFFDD', bold: true);
    final dataPoints = distributions.map((distribution) => distribution.dataPoints!).toList();
    final first = dataPoints.first;

    // Motif counts
    Sheet motifSheet = excel['motifs'];
    motifSheet.appendRow([
      'Interval',
      'Min',
      ...distributions.map((distribution) => distribution.name),
      '',
      ...distributions.map((distribution) => '${distribution.name} [%]'),
    ]);
    for (var i = 0; i < first.length; i++) {
      final dataPoint = first[i];
      motifSheet.appendRow([
        dataPoint.label,
        dataPoint.min,
        ...dataPoints.map((dp) => dp[i].count),
        '',
        ...dataPoints.map((dp) => dp[i].percent),
      ]);
    }
    for (int i = 0; i < motifSheet.maxCols; i++) {
      motifSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerCellStyle;
    }
    for (int i = 0; i < motifSheet.maxRows; i++) {
      motifSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle = headerCellStyle;
      motifSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).cellStyle = headerCellStyle;
    }

    // Gene counts
    Sheet genesSheet = excel['genes'];
    genesSheet.appendRow([
      'Interval',
      'Min',
      ...distributions.map((distribution) => distribution.name),
      '',
      ...distributions.map((distribution) => '${distribution.name} [%]'),
    ]);
    for (var i = 0; i < first.length; i++) {
      final dataPoint = first[i];
      genesSheet.appendRow([
        dataPoint.label,
        dataPoint.min,
        ...dataPoints.map((dp) => dp[i].genesCount),
        '',
        ...dataPoints.map((dp) => dp[i].genesPercent),
      ]);
    }
    for (int i = 0; i < genesSheet.maxCols; i++) {
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerCellStyle;
    }
    for (int i = 0; i < genesSheet.maxRows; i++) {
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle = headerCellStyle;
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).cellStyle = headerCellStyle;
    }

    for (var element in originalSheets) {
      excel.delete(element);
    }
    return excel.save(fileName: fileName);
  }
}
