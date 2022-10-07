import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_list.dart';

class GeneView extends StatelessWidget {
  final GeneList genes;

  const GeneView({Key? key, required this.genes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemBuilder: _itemBuilder, itemCount: genes.genes.length);
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final gene = genes.genes[index];
    return ListTile(
      title: Text(gene.geneId),
      subtitle: Text([gene.header, ...gene.notes].join('\n')),
    );
  }
}
