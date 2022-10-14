import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/screens/home_analysis_tab.dart';
import 'package:geneweb/screens/home_results_tab.dart';
import 'package:geneweb/screens/home_source_tab.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final distributionsCount = context.select<GeneModel, int>((model) => model.distributions.length);
    final name = context.select<GeneModel, String?>((model) => model.name);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name ?? 'Gene web'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Source data'),
              const Tab(text: 'Analysis'),
              Tab(text: 'Results${distributionsCount > 0 ? ' ($distributionsCount)' : ''}'),
            ],
          ),
        ),
        body: const TabBarView(children: [
          HomeSourceTab(),
          HomeAnalysisTab(),
          HomeResultsTab(),
        ]),
      ),
    );
  }
}
