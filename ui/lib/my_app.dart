import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/screens/home_screen.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Are we running on `dev` or `prod` on the web?
  ///
  /// Returns `null` if not running on the web.
  DeploymentFlavor? get deploymentFlavor => !kIsWeb
      ? null
      : Uri.base.host == 'golem.ncbr.muni.cz' && Uri.base.scheme == 'https'
          ? DeploymentFlavor.prod
          : DeploymentFlavor.dev;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GeneModel>(
          create: (BuildContext context) => GeneModel(deploymentFlavor),
        ),
      ],
      child: MaterialApp(
        title: 'GOLEM${deploymentFlavor == DeploymentFlavor.dev ? '-DEV' : ''}',
        theme: ThemeData(
          colorSchemeSeed: const Color(0xff488AB9),
          fontFamily: 'Barlow',
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xffA0CB85)),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

enum DeploymentFlavor { dev, prod }
