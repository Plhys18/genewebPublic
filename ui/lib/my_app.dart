import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'screens/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAuthProvider>(
      builder: (context, userAuthProvider, child) {
        return MaterialApp(
          title: 'GOLEM',
          theme: ThemeData(
            colorSchemeSeed: const Color(0xff488AB9),
            fontFamily: 'Barlow',
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xffA0CB85)),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
