import 'package:excel/excel.dart';
import 'package:geneweb/analysis/distribution.dart';

class DistributionsOutput {
  final List<Distribution> distributions;

  DistributionsOutput(this.distributions);

  List<int>? toExcel() {
    assert(distributions.isNotEmpty);
    var excel = Excel.createExcel();
    Sheet sheet = excel['distributions'];
    final headerCellStyle = CellStyle(backgroundColorHex: 'FFDDFFDD', bold: true);
    sheet.appendRow([
      'Interval',
      'Min',
      ...distributions.map((distribution) => distribution.name),
    ]);
    final dataPoints = distributions.map((distribution) => distribution.dataPoints!).toList();
    final first = dataPoints.first;
    for (var i = 0; i < first.length; i++) {
      final dataPoint = first[i];
      sheet.appendRow([
        dataPoint.label,
        dataPoint.min,
        ...dataPoints.map((dp) => dp[i].value),
      ]);
    }
    for (int i = 0; i < sheet.maxCols; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerCellStyle;
    }
    for (int i = 0; i < sheet.maxRows; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle = headerCellStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).cellStyle = headerCellStyle;
    }
    return excel.save(fileName: 'distributions.xlsx');
  }
}
