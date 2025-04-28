import 'package:flutter/material.dart';
import 'package:geneweb/my_app.dart';
import 'package:geneweb/utilities/api_service.dart';
import 'package:provider/provider.dart';

import 'auth_context_provider.dart';
import 'auth_provider.dart';
import 'genes/gene_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        ChangeNotifierProvider(create: (context) => UserAuthProvider()),
        ChangeNotifierProvider(create: (context) => GeneModel()),
      ],
      child: const AuthContextProvider(
        child: MyApp(),
      ),
    ),
  );
}
