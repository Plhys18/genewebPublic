import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_model.dart';

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
  late final _controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
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
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onEditingComplete: _handleSubmit,
              ),
            ),
            const SizedBox(height: 20),
            IconButton.filled(onPressed: _handleSubmit, icon: const Icon(Icons.arrow_forward)),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    // final password = _controller.text.trim();
    // final md5Hash = md5.convert(utf8.encode(password)).toString();
    // if (md5Hash == 'c36db9789b1401a805d8bb72ba70a3bc') {
      GeneModel.of(context).isSignedIn = true;
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password')));
    // }
  }
}
