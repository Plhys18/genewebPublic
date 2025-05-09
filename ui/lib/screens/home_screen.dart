import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_provider.dart';
import '../genes/gene_model.dart';
import '../widgets/home.dart';
import '../widgets/source_panel.dart';
import 'lock_screen.dart';
import 'user_profile_screen.dart';
import 'analysis_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check auth state on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserAuthProvider>().checkAuthState();
    });
  }

  void _handleLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LockScreen(allowCancel: true)),
    );

    if (result == true) {
      if (SourcePanel.sourcePanelKey.currentState != null) {
        SourcePanel.sourcePanelKey.currentState!.fetchOrganisms();
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully'))
      );
    }
  }

  void _handleLogout() async {
    await context.read<UserAuthProvider>().logout();

    if (SourcePanel.sourcePanelKey.currentState != null) {
      SourcePanel.sourcePanelKey.currentState!.fetchOrganisms();
    }

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully'))
    );
  }
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserProfileScreen()),
    );
  }

  void _navigateToAnalysisHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalysisListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<UserAuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final isLoading = authProvider.isLoading;

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
                child: isLoading
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
                    if (isLoggedIn) ...[
                      Text(
                        "Welcome ${authProvider.username}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person),
                        tooltip: 'User Profile',
                        onPressed: _navigateToProfile,
                      ),
                      IconButton(
                        icon: const Icon(Icons.history),
                        tooltip: 'Analysis History',
                        onPressed: _navigateToAnalysisHistory,
                      ),
                      const SizedBox(width: 8),
                    ],
                    isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : IconButton(
                      icon: Icon(
                        isLoggedIn ? Icons.logout : Icons.login,
                      ),
                      tooltip: isLoggedIn ? 'Log Out' : 'Log In',
                      onPressed: isLoggedIn ? _handleLogout : _handleLogin,
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