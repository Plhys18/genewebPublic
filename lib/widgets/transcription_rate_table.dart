import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_list.dart';

class TranscriptionRateTable extends StatelessWidget {
  final GeneList list;

  const TranscriptionRateTable({Key? key, required this.list}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Table(children: [
      TableRow(children: [
        const Text('Transcription rates'),
        for (final key in list.transcriptionRates.keys) TableCell(child: Text(key)),
      ]),
      TableRow(children: [
        const Text('Min'),
        for (final key in list.transcriptionRates.keys)
          TableCell(child: Text(list.transcriptionRates[key]!.min.toStringAsFixed(2))),
      ]),
      TableRow(children: [
        const Text('Mean'),
        for (final key in list.transcriptionRates.keys)
          TableCell(child: Text(list.transcriptionRates[key]!.mean.toStringAsFixed(2))),
      ]),
      TableRow(children: [
        const Text('Max'),
        for (final key in list.transcriptionRates.keys)
          TableCell(child: Text(list.transcriptionRates[key]!.max.toStringAsFixed(2))),
      ]),
      TableRow(children: [
        const Text('Length'),
        for (final key in list.transcriptionRates.keys)
          TableCell(child: Text(list.transcriptionRates[key]!.length.toString())),
      ]),
    ]);
  }
}
