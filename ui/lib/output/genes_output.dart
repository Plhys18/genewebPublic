import 'package:excel/excel.dart';
import 'package:geneweb/genes/gene_list.dart';

class GenesOutput {
  final GeneList genes;

  GenesOutput(this.genes);

  List<int>? toExcel(String? name) {
    assert(genes.genes.isNotEmpty);
    var excel = Excel.createExcel();
    Sheet sheet = excel['genes'];
    final headerCellStyle = CellStyle(backgroundColorHex: 'FFDDFFDD', bold: true);
    sheet.appendRow([
      'Gene Id',
      for (final key in genes.genes.first.markers.keys) key,
      for (final key in genes.genes.first.transcriptionRates.keys) key,
    ]);
    for (var i = 0; i < genes.genes.length; i++) {
      final gene = genes.genes[i];
      sheet.appendRow([
        gene.geneId,
        for (final key in genes.genes.first.markers.keys) gene.markers[key],
        for (final key in genes.genes.first.transcriptionRates.keys) gene.transcriptionRates[key],
      ]);
    }
    for (int i = 0; i < sheet.maxCols; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerCellStyle;
    }
    for (int i = 0; i < sheet.maxRows; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle = headerCellStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).cellStyle = headerCellStyle;
    }
    return excel.save(fileName: '${name ?? 'genes'}.xlsx');
  }
}
