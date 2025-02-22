import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geneweb/genes/gene_model.dart';

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
      _loading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (!_validateInputs(username, password)) {
      _showSnackBar("Username and password must not be empty");
      setState(() => _loading = false);
      return;
    }

    final passwordHash = _hashPassword(password);
    final payload = _buildPayload(username, passwordHash);

    try {
      final response = await _postLogin(payload);
      _handleResponse(response);
    } catch (e) {
      _showSnackBar('Network error: $e ${e.runtimeType}');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  bool _validateInputs(String username, String password) {
    return username.isNotEmpty && password.isNotEmpty;
  }

  String _hashPassword(String password) {
    return md5.convert(utf8.encode(password)).toString();
  }

  String _buildPayload(String username, String passwordHash) {
    return jsonEncode({
      'username': username,
      'password_hash': passwordHash,
    });
  }

  Future<http.Response> _postLogin(String payload) {
    return http.post(
      Uri.parse('http://0.0.0.0:8000/api/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['authenticated'] == true) {
        GeneModel.of(context).isSignedIn = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        _showSnackBar('Incorrect username or password');
      }
    } else {
      _showSnackBar('Error: ${response.statusCode}');
    }
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

}
