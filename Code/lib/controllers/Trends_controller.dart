// lib/controllers/trends_controller.dart

import '../models/trend.dart';

class TrendsController {
  final Map<String, List<Trend>> trendsData;
  String _selectedPeriod;
  bool _isBarChart;

  TrendsController({
    required Map<String, List<Trend>> trendsData,
    String initialPeriod = 'Giorno',
    bool isBarChart = true,
  })  : trendsData = trendsData,
        _selectedPeriod = initialPeriod,
        _isBarChart = isBarChart;

  List<Trend> get trends => trendsData[_selectedPeriod]!;
  String get selectedPeriod => _selectedPeriod;
  bool get isBarChart => _isBarChart;

  int get totalCount =>
      trends.fold<int>(0, (sum, t) => sum + t.count);
  double get maxCount =>
      trends.map((t) => t.count).reduce((a, b) => a > b ? a : b).toDouble();

  void changePeriod(String period) {
    _selectedPeriod = period;
  }

  void toggleChartType(bool bar) {
    _isBarChart = bar;
  }
}
