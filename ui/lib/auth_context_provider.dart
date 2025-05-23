import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class AuthContextProvider extends StatefulWidget {
  final Widget child;

  const AuthContextProvider({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthContextProvider> createState() => _AuthContextProviderState();
}

class _AuthContextProviderState extends State<AuthContextProvider> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<UserAuthProvider>(context, listen: false);
      authProvider.checkAuthState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}