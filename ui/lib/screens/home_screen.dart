import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/widgets/home_panel.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = context.select<GeneModel, String?>((model) => model.name);
    return Scaffold(
      appBar: AppBar(title: Text(name ?? 'Pollen Motifs')),
      body: const HomePanel(),
    );
  }
}
