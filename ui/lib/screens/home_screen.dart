import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/my_app.dart';
import 'package:geneweb/widgets/home.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select<GeneModel, String?>((model) => model.name);
    final deploymentFlavor = context.select<GeneModel, DeploymentFlavor?>((model) => model.deploymentFlavor);
    final public = context.select<GeneModel, bool>((model) => model.publicSite);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.0,
        title: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 24.0,
                      children: [
                        Image.asset('assets/logo-golem.png', height: 36),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Gene regulatory elements', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            Expanded(child: Align(alignment: Alignment.center, child: Text(name ?? ''))),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: !public ? const Text('private web') : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        backgroundColor: public ? null : const Color(0xffEC6138),
        actions: deploymentFlavor != null
            ? null
            : <Widget>[
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
