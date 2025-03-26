// import 'package:flutter/material.dart';
// import 'package:geneweb/genes/gene_model.dart';
// import 'package:geneweb/utilities/api_service.dart';
// import 'package:provider/provider.dart';
//
// import '../analysis/analysis_series.dart';
// import '../analysis/Analysis_history_entry.dart';
//
// class AnalysisDetailsScreen extends StatefulWidget {
//   final int analysisId;
//
//   const AnalysisDetailsScreen({super.key, required this.analysisId});
//
//   @override
//   State<AnalysisDetailsScreen> createState() => _AnalysisDetailsScreenState();
// }
//
// class _AnalysisDetailsScreenState extends State<AnalysisDetailsScreen> {
//   AnalysisSeries? _analysisDetails;
//   bool _loading = true;
//   String? _error;
//   final ApiService _apiService = ApiService();
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAnalysisDetails();
//   }
//
//   Future<void> _fetchAnalysisDetails() async {
//     try {
//       final geneModel = GeneModel.of(context);
//       final details = await _apiService.fetchAnalysisDetails(widget.analysisId);
//
//       setState(() {
//         _analysisDetails = details;
//         _loading = false;
//       });
//     } catch (error) {
//       setState(() {
//         _error = "Error loading analysis: $error";
//         _loading = false;
//       });
//     }
//   }
//
//   Future<void> _loadAnalysisSettings() async {
//     setState(() {
//       _loading = true;
//     });
//
//     try {
//       final geneModel = GeneModel.of(context);
//       await geneModel.loadAnalysisSettings(widget.analysisId);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Analysis settings loaded')));
//
//       // Navigate back to home screen with loaded settings
//       Navigator.of(context).pop();
//     } catch (error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               backgroundColor: Colors.red,
//               content: Text('Error loading analysis settings: $error')));
//
//       setState(() {
//         _loading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_analysisDetails?.analysisName ?? "Analysis Details"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings_backup_restore),
//             tooltip: 'Load these settings for a new analysis',
//             onPressed: _loading ? null : _loadAnalysisSettings,
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//           ? Center(child: Text(_error!))
//           : _buildAnalysisDetails(),
//     );
//   }
//
//   Widget _buildAnalysisDetails() {
//     if (_analysisDetails == null) {
//       return const Center(child: Text("No results available."));
//     }
//
//     final distribution = _analysisDetails!.distribution;
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Analysis Summary',
//                       style: Theme.of(context).textTheme.titleLarge),
//                   const Divider(),
//                   _buildInfoRow('Name', _analysisDetails!.analysisName),
//                   _buildInfoRow('Total Motifs Found',
//                       distribution.totalCount.toString()),
//                   _buildInfoRow('Genes with Motifs',
//                       distribution.totalGenesWithMotifCount.toString()),
//                   _buildInfoRow('Total Genes Analyzed',
//                       distribution.totalGenesCount.toString()),
//                   _buildInfoRow('Interval',
//                       '${distribution.min} to ${distribution.max} bp'),
//                   _buildInfoRow('Bucket Size',
//                       '${distribution.bucketSize} bp'),
//                   if (distribution.alignMarker != null)
//                     _buildInfoRow('Aligned to',
//                         distribution.alignMarker!.toUpperCase()),
//                 ],
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           // You could add a chart here if needed
//
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Data Distribution',
//                       style: Theme.of(context).textTheme.titleLarge),
//                   const Divider(),
//                   const SizedBox(height: 8),
//                   SizedBox(
//                     height: 300,
//                     child: _buildDistributionTable(distribution),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 150,
//             child: Text(
//               label,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: Text(value),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDistributionTable(dynamic distribution) {
//     final dataPoints = distribution.dataPoints;
//
//     if (dataPoints == null || dataPoints.isEmpty) {
//       return const Center(child: Text('No distribution data available'));
//     }
//
//     return ListView.builder(
//       itemCount: dataPoints.length,
//       itemBuilder: (context, index) {
//         final point = dataPoints[index];
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 2),
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: Text('${point.min} to ${point.max} bp'),
//                 ),
//                 Expanded(
//                   flex: 1,
//                   child: Text('${point.count} motifs',
//                       textAlign: TextAlign.right),
//                 ),
//                 Expanded(
//                   flex: 1,
//                   child: Text('${(point.percent * 100).toStringAsFixed(2)}%',
//                       textAlign: TextAlign.right),
//                 ),
//                 Expanded(
//                   flex: 1,
//                   child: Text('${point.genesCount} genes',
//                       textAlign: TextAlign.right),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }