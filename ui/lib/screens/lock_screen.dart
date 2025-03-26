import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../utilities/api_service.dart';

class LockScreen extends StatefulWidget {
  final bool allowCancel;
  final bool isDialog;

  const LockScreen({
    super.key,
    this.allowCancel = false,
    this.isDialog = false,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/logo-golem.png', height: 72),
          const SizedBox(height: 40),
          _Lock(
            onLoginSuccess: () {
              if (widget.isDialog) {
                Navigator.pop(context, true);
              } else {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );

    if (widget.isDialog) {
      return content;
    }

    return Scaffold(
      appBar: widget.allowCancel ? AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ) : null,
      body: content,
      backgroundColor: Theme.of(context).colorScheme.outline,
    );
  }
}

class _Lock extends StatefulWidget {
  final Function onLoginSuccess;

  const _Lock({super.key, required this.onLoginSuccess});

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
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
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

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Username and password must not be empty");
      setState(() => _loading = false);
      return;
    }

    final success = await ApiService().login(username, password);

    if (success) {
      context.read<UserAuthProvider>().logIn(username);
      Navigator.pop(context, true);
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