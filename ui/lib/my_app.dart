import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/screens/home_screen.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GeneModel>(
          create: (BuildContext context) => GeneModel(),
        ),
      ],
      child: MaterialApp(
        title: 'GOLEM',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
