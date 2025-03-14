// import 'package:flutter/material.dart';
//
// import 'package:geneweb/genes/gene_model.dart';
// import 'package:provider/provider.dart';
//
// import '../analysis/Analysis_history_entry.dart';
// import '../utilities/api_service.dart';
// import 'analysis_details_screen.dart';
//
//
// class AnalysisListScreen extends StatefulWidget {
//   const AnalysisListScreen({super.key});
//
//   @override
//   State<AnalysisListScreen> createState() => _AnalysisListScreenState();
// }
//
// class _AnalysisListScreenState extends State<AnalysisListScreen> {
//   List<AnalysisHistoryEntry> _analysesHistory = [];
//   bool _loading = true;
//   String? _error;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAnalysesHistory();
//   }
//
//   Future<void> _fetchAnalysesHistory() async {
//     try {
//       final geneModel = GeneModel.of(context);
//       await geneModel.fetchAnalyses();
//       setState(() {
//         _analysesHistory = geneModel.analysesHistory;
//         _loading = false;
//       });
//     } catch (error) {
//       setState(() {
//         _error = "Error loading analyses: $error";
//         _loading = false;
//       });
//     }
//   }
//
//   Future<void> _runNewAnalysis() async {
//     final geneModel = GeneModel.of(context);
//     setState(() {
//       _loading = true;
//     });
//
//     try {
//       final success = await geneModel.analyze();
//       if (success) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Analysis complete')));
//         await _fetchAnalysesHistory(); // Refresh list
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//             backgroundColor: Colors.red,
//             content: Text('Analysis failed')));
//       }
//     } catch (error) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           backgroundColor: Colors.red,
//           content: Text('Error running analysis: $error')));
//     } finally {
//       setState(() {
//         _loading = false;
//       });
//     }
//   }
//
//   void _navigateToDetails(int analysisId) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AnalysisDetailsScreen(analysisId: analysisId),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Analysis List')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: ElevatedButton(
//               onPressed: _loading ? null : _runNewAnalysis,
//               child: const Text('Run New Analysis'),
//             ),
//           ),
//           Expanded(
//             child: _loading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _error != null
//                 ? Center(child: Text(_error!))
//                 : _analysesHistory.isEmpty
//                 ? const Center(child: Text('No analyses performed yet.'))
//                 : ListView.builder(
//               itemCount: _analysesHistory.length,
//               itemBuilder: (context, index) {
//                 final analysis = _analysesHistory[index];
//                 return ListTile(
//                   title: Text(analysis.name),
//                   subtitle: Text("Created: ${analysis.createdAt}"),
//                   trailing: const Icon(Icons.arrow_forward),
//                   onTap: () => _navigateToDetails(analysis.id),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
