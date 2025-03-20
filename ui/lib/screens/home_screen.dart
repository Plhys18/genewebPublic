import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../genes/gene_model.dart';
import '../widgets/home.dart';
import 'lock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;

  void _handleLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LockScreen()),
    );
  }

  void _handleLogout() {
    context.read<UserAuthProvider>().logOut();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LockScreen()),
    );
    context.read<GeneModel>().removeEverythingAssociatedWithCurrentSession();
  }

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      'Gene regulatory elements',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(
                context.select<GeneModel, String?>((model) => model.name) ?? 'Unknown Organism',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        context.watch<UserAuthProvider>().isLoggedIn
                            ? Icons.logout
                            : Icons.login,
                      ),
                      onPressed: context.watch<UserAuthProvider>().isLoggedIn
                          ? _handleLogout
                          : _handleLogin,
                    ),
                    Text(
                      context.watch<UserAuthProvider>().isLoggedIn
                          ? 'Log Out'
                          : 'Log In',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: const Home(),
    );
  }
}
