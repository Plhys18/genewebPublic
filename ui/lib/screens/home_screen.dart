import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/widgets/home.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = context.select<GeneModel, String?>((model) => model.name);
    final public = context.select<GeneModel, bool>((model) => model.publicSite);
    return Scaffold(
      appBar: AppBar(
        title: Text('${name ?? 'GOLEM'}${public ? '' : ' (Private)'}'),
        backgroundColor: public ? null : Colors.deepOrange[900],
        actions: <Widget>[
          IconButton(
            icon: public ? const Icon(Icons.lock_open) : const Icon(Icons.lock),
            onPressed: () => GeneModel.of(context).setPublicSite(!public),
          ),
        ],
      ),
      body: const Home(),
    );
  }
}
