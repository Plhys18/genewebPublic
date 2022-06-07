import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/genes/gene_list.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';

class HomeSourceTab extends StatelessWidget {
  const HomeSourceTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: _Source(),
        ),
      ),
    );
  }
}

class _Source extends StatefulWidget {
  final Function()? onLoad;
  const _Source({Key? key, this.onLoad}) : super(key: key);

  @override
  State<_Source> createState() => _SourceState();
}

class _SourceState extends State<_Source> {
  late final _model = GeneModel.of(context);
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final sourceGenes = context.select<GeneModel, GeneList?>((model) => model.sourceGenes);
    if (_isLoading) return const Center(child: Text('Import in progress…'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sourceGenes == null) const Text('Start by importing genes in FASTA format (.fa, .fasta)'),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _handlePickFile, child: const Text('Load source data')),
        if (sourceGenes != null) ...[
          const SizedBox(height: 16),
          Text('Loaded ${sourceGenes.genes.length} genes'),
//          Card(child: SizedBox(height: 400, child: GeneView(genes: sourceGenes))),
        ],
      ],
    );
  }

  Future<void> _load() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() => _isLoading = true);
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        if (kIsWeb) {
          final data = String.fromCharCodes(result.files.single.bytes!);
          debugPrint('Loaded ${data.length} bytes');
          await _model.loadFromString(data, filename: result.files.single.name);
        } else {
          final path = result.files.single.path!;
          await _model.loadFromFile(path, filename: result.files.single.name);
        }
      } else {
        debugPrint('Cancelled');
      }
      messenger.showSnackBar(SnackBar(content: Text('Imported ${_model.sourceGenes?.genes.length} genes.')));
      widget.onLoad?.call;
    } catch (error) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error loading data: $error'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePickFile() async {
    await _load();
  }
}
