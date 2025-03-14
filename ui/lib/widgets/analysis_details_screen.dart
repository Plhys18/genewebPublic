// import 'package:flutter/material.dart';
// import 'package:geneweb/genes/gene_model.dart';
// import 'package:geneweb/utilities/api_service.dart';
// import 'package:provider/provider.dart';
//
// import '../analysis/analysis_series.dart';
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
//   ApiService _apiService = ApiService();
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
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(_analysisDetails?["name"] ?? "Analysis Details")),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//           ? Center(child: Text(_error!))
//           : _buildAnalysisDetails(),
//     );
//   }
//
//   Widget _buildAnalysisDetails() {
//     final results = _analysisDetails?["results"];
//     if (results == null || results.isEmpty) {
//       return const Center(child: Text("No results available."));
//     }
//
//     return ListView.builder(
//       itemCount: results.length,
//       itemBuilder: (context, index) {
//         final result = results[index];
//         return Card(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: ListTile(
//             title: Text("Gene ID: ${result["key"]}"),
//             subtitle: Text(result["value"].toString()),
//           ),
//         );
//       },
//     );
//   }
// }
