import 'package:flutter/material.dart';
import 'package:geneweb/my_app.dart';
import 'package:geneweb/utilities/api_service.dart';
import 'package:provider/provider.dart';

import 'auth_context_provider.dart';
import 'auth_provider.dart';
import 'genes/gene_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service before creating providers
  await ApiService.init();

  runApp(
    MultiProvider(
      providers: [
        // Use create instead of value to ensure proper disposal
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        // Auth provider needs to be created before GeneModel
        ChangeNotifierProvider(create: (context) => UserAuthProvider()),
        // GeneModel depends on auth provider for data fetching
        ChangeNotifierProvider(create: (context) => GeneModel()),
      ],
      child: const AuthContextProvider(
        child: MyApp(),
      ),
    ),
  );
}
