import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/widgets/home.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = context.select<GeneModel, String?>((model) => model.name);
    final public = context.select<GeneModel, bool>((model) => model.publicSite);
    return Scaffold(
      appBar: AppBar(
        title: Text('${name ?? 'Pollen Motifs'}${public ? '' : ' (Private)'}'),
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

//TODO SVG does not work...
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    const String assetName = 'assets/logo_prif.svg';
    return Container(
        height: 100,
        color: Colors.red,
        child: SvgPicture.asset(assetName, semanticsLabel: 'MUNI SCI', width: 100, height: 100, color: Colors.amber));
  }
}
