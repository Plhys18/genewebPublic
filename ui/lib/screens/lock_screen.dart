import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../utilities/api_service.dart';
import 'home_screen.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo-golem.png', height: 72),
            const SizedBox(height: 40),
            const _Lock(),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.outline,
    );
  }
}

class _Lock extends StatefulWidget {
  const _Lock({super.key});

  @override
  State<_Lock> createState() => __LockState();
}

class __LockState extends State<_Lock> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 60),
            const SizedBox(height: 20),
            // Username input
            SizedBox(
              width: 300,
              child: TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your username',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
            ),
            const SizedBox(height: 20),
            // Password input
            SizedBox(
              width: 300,
              child: TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onSubmitted: (_) => _handleSubmit(),
              ),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : IconButton.filled(
              onPressed: _handleSubmit,
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() async {
    setState(() {
      _loading = false;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Username and password must not be empty");
      setState(() => _loading = false);
      return;
    }

    final success = await ApiService().login(username, password);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      _showSnackBar('Incorrect username or password');
    }

    setState(() {
      _loading = false;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
