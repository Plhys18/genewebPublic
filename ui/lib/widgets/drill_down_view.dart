import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../analysis/analysis_series.dart';

/// Widget that builds the drill-down view
class DrillDownView extends StatefulWidget {
  final String? name;

  const DrillDownView({super.key, required this.name});

  @override
  State<DrillDownView> createState() => _DrillDownViewState();
}

class _DrillDownViewState extends State<DrillDownView> {
  List<String> patterns = [];
  List<DrillDownResult>? _results;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDrillDownData();
  }

  @override
  void didUpdateWidget(covariant DrillDownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      patterns = [];
      _fetchDrillDownData();
    }
  }

  Future<void> _fetchDrillDownData([String? pattern]) async {
    if (widget.name == null) return;

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse("http://localhost:8000/api/analysis/drilldown/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "analysis_name": widget.name,
          "pattern": pattern,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results = (data["results"] as List)
              .map((e) => DrillDownResult.fromJson(e))
              .toList();
          _loading = false;
        });
      } else {
        throw Exception("Failed to fetch drill-down results");
      }
    } catch (error) {
      setState(() {
        _error = "Error loading drill-down: $error";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_results == null || _results!.isEmpty) {
      return const Center(child: Text('No drill-down data available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: patterns.isEmpty ? null : () => _handleBreadCrumb(null),
              child: const Text('Motif drill down'),
            ),
            for (final pattern in patterns) ...[
              const Text(' > '),
              TextButton(
                onPressed: () => _handleBreadCrumb(pattern),
                child: Text(pattern),
              ),
            ]
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results!.length,
            itemBuilder: (context, index) {
              final result = _results![index];
              return ListTile(
                dense: true,
                title: Text(result.pattern),
                subtitle: result.share != null && result.shareOfAll != null
                    ? Text(
                    'Matches ${((result.share ?? 0) * 100).round()}% of selection, '
                        '(${((result.shareOfAll ?? 0) * 100).round()}% of all results)')
                    : null,
                trailing: Text(result.count.toString()),
                onTap: () => _handleDrillDownDeeper(result.pattern),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleDrillDownDeeper(String pattern) {
    setState(() {
      patterns.add(pattern);
      _fetchDrillDownData(pattern);
    });
  }

  void _handleBreadCrumb(String? pattern) {
    setState(() {
      if (pattern == null) {
        patterns = [];
      } else {
        patterns = [...patterns.takeWhile((e) => e != pattern), pattern];
      }
      _fetchDrillDownData(pattern);
    });
  }
}

/// Model for DrillDownResult
class DrillDownResult {
  final String pattern;
  final int count;
  final double? share;
  final double? shareOfAll;

  DrillDownResult({
    required this.pattern,
    required this.count,
    this.share,
    this.shareOfAll,
  });

  factory DrillDownResult.fromJson(Map<String, dynamic> json) {
    return DrillDownResult(
      pattern: json["pattern"],
      count: json["count"],
      share: json["share"]?.toDouble(),
      shareOfAll: json["share_of_all"]?.toDouble(),
    );
  }
}
