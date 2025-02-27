import 'package:flutter/material.dart';

import '../widgets/home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _name;
  bool _public = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
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
                    Text('Gene regulatory elements',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.center,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : Text(_name ?? 'Unknown Organism',
                        style: const TextStyle(fontStyle: FontStyle.italic)))),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: !_public ? const Text('private web') : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        backgroundColor: _public ? null : const Color(0xffEC6138),
      ),
      body: const Home(),
    );
  }
}
