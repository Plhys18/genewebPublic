// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import '../utilities/api_service.dart';
//
// /// Widget that builds the series and allows hide/show etc.
// class ResultSeriesList extends StatefulWidget {
//   final Function(String? selected) onSelected;
//
//   const ResultSeriesList({super.key, required this.onSelected});
//
//   @override
//   State<ResultSeriesList> createState() => _ResultSeriesListState();
// }
//
// class _ResultSeriesListState extends State<ResultSeriesList> {
//   String? _selected;
//   List<AnalysisSeries> _analyses = [];
//   bool _loading = true;
//   String? _error;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAnalyses();
//   }
//
//   Future<void> _fetchAnalyses() async {
//     print("Fetching analyses in result_series_list.dart");
//     try {
//       final response = await ApiService().getRequest("analysis/history");
//       setState(() {
//         _analyses = List<AnalysisSeries>.from(response["history"]);
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
//
//   Future<void> _toggleVisibility(AnalysisSeries analysis) async {
//     try {
//       final response = await http.post(
//         Uri.parse("http://localhost:8000/api/analysis/toggle_visibility/"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"name": analysis.name, "visible": !analysis.visible}),
//       );
//       if (response.statusCode == 200) {
//         setState(() {
//           _analyses = _analyses.map((a) {
//             return a.name == analysis.name ? a.copyWith(visible: !a.visible) : a;
//           }).toList();
//         });
//       } else {
//         throw Exception("Failed to toggle visibility");
//       }
//     } catch (error) {
//       debugPrint("Error toggling visibility: $error");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) return const Center(child: CircularProgressIndicator());
//     if (_error != null) return Center(child: Text(_error!));
//
//     return ReorderableListView(
//       onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex),
//       children: _analyses.map((analysis) {
//         return ListTile(
//           key: Key(analysis.name),
//           onTap: () => _handleSelected(analysis.name),
//           dense: true,
//           selected: analysis.name == _selected,
//           title: Text(analysis.name),
//           subtitle: Text('${analysis.totalCount} motifs in ${analysis.totalGenesWithMotifCount} genes'),
//           leading: IconButton(
//             onPressed: () => _toggleVisibility(analysis),
//             icon: analysis.visible ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   void _handleReorder(int oldIndex, int newIndex) {
//     setState(() {
//       if (oldIndex < newIndex) newIndex--;
//       final item = _analyses.removeAt(oldIndex);
//       _analyses.insert(newIndex, item);
//     });
//   }
//
//   void _handleSelected(String name) {
//     setState(() => _selected = _selected == name ? null : name);
//     widget.onSelected(_selected);
//   }
// }
//
// /// Model for Analysis Series
// class AnalysisSeries {
//   final String name;
//   final bool visible;
//   final int totalCount;
//   final int totalGenesWithMotifCount;
//
//   AnalysisSeries({
//     required this.name,
//     required this.visible,
//     required this.totalCount,
//     required this.totalGenesWithMotifCount,
//   });
//
//   factory AnalysisSeries.fromJson(Map<String, dynamic> json) {
//     return AnalysisSeries(
//       name: json["name"],
//       visible: json["visible"],
//       totalCount: json["totalCount"],
//       totalGenesWithMotifCount: json["totalGenesWithMotifCount"],
//     );
//   }
//
//   AnalysisSeries copyWith({bool? visible}) {
//     return AnalysisSeries(
//       name: name,
//       visible: visible ?? this.visible,
//       totalCount: totalCount,
//       totalGenesWithMotifCount: totalGenesWithMotifCount,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/analysis_series.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:provider/provider.dart';

/// Widget that builds the series and allows hide/show etc.
class ResultSeriesList extends StatefulWidget {
  const ResultSeriesList({super.key, required this.onSelected, required List<AnalysisSeries> analyses});

  final Function(String? selected) onSelected;

  @override
  State<ResultSeriesList> createState() => _ResultSeriesListState();
}

class _ResultSeriesListState extends State<ResultSeriesList> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final analyses = context.select<GeneModel, List<AnalysisSeries>>((model) => model.analyses);
    return ReorderableListView(
      onReorder: (oldIndex, newIndex) => _handleReorder(context, oldIndex, newIndex),
      children: [
        for (final analysis in analyses)
          ListTile(
            key: Key(analysis.analysisName),
            onTap: () => _handleSelected(analysis.analysisName),
            dense: true,
            selected: analysis.analysisName == _selected,
            selectedTileColor: colorScheme.primaryContainer,
            selectedColor: colorScheme.onPrimaryContainer,
            leading: IconButton(
              onPressed: () => _handleSetVisibility(context, analysis),
              icon: analysis.visible
                  ? Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                  color: analysis.color,
                ),
                width: 24,
                height: 24,
              )
                  : const Icon(Icons.visibility_off),
            ),
            title: Text(analysis.analysisName),
            subtitle: Text(
              '${analysis.distribution!.totalCount} motifs in ${analysis.distribution!.totalGenesWithMotifCount} genes (of ${analysis.distribution!.totalGenesCount} genes)',
            ),
          ),
      ],
    );
  }

  void _handleReorder(BuildContext context, int oldIndex, int newIndex) {
    final analyses = List<AnalysisSeries>.from(GeneModel.of(context).analyses);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = analyses.removeAt(oldIndex);
    analyses.insert(newIndex, item);
    GeneModel.of(context).analyses = analyses;
  }

  void _handleSelected(String name) {
    setState(() => _selected = _selected == name ? null : name);
    widget.onSelected(_selected);
  }

  void _handleSetVisibility(BuildContext context, AnalysisSeries analysis) {
    final model = GeneModel.of(context);
    model.analyses = ([
      for (final a in model.analyses)
        if (a.analysisName == analysis.analysisName) analysis.copyWith(visible: !analysis.visible) else a
    ]);
  }
}
