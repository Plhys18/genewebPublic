import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:geneweb/screens/home_screen.dart';
import 'package:geneweb/screens/lock_screen.dart';
import 'package:provider/provider.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isSignedIn;
  bool? _isPublicSite = true;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GeneModel>(
          create: (context) => GeneModel(),
        ),
      ],
      child: MaterialApp(
        title: 'GOLEM',
        theme: ThemeData(
          colorSchemeSeed: const Color(0xff488AB9),
          fontFamily: 'Barlow',
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xffA0CB85)),
          useMaterial3: true,
        ),
        home: (_isPublicSite == true || _isSignedIn == true) ? const HomeScreen() : const LockScreen(),
      ),
    );
  }
}
