// lib/views/trends_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../views/BottomNavBar.dart';
import '../controller/BottomNavBarController.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({Key? key}) : super(key: key);

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  final BottomNavBarController _navController = BottomNavBarController(
    initialIndex: 3,
  );

  final Map<String, List<Map<String, dynamic>>> _trends = {
    'Giorno': [
      {'tag': 'Flutter', 'count': 48},
      {'tag': 'AI', 'count': 35},
      {'tag': 'Cinema', 'count': 23},
      {'tag': 'Video', 'count': 18},
      {'tag': 'News', 'count': 12},
      {'tag': 'News', 'count': 12},
    ],
    'Mese': [
      {'tag': 'Flutter', 'count': 600},
      {'tag': 'AI', 'count': 480},
      {'tag': 'Cinema', 'count': 310},
      {'tag': 'Video', 'count': 230},
      {'tag': 'News', 'count': 190},
    ],
    'Anno': [
      {'tag': 'Video', 'count': 980},
      {'tag': 'News', 'count': 870},
      {'tag': 'News', 'count': 12},
    ],
  };

  String _selectedPeriod = 'Giorno';
  bool _isBarChart = true;

  final List<Color> _barColors = [
    const Color.fromARGB(255, 206, 13, 13),
    const Color(0xFFF0792B),
    const Color.fromARGB(255, 240, 201, 43),
    const Color.fromARGB(255, 38, 211, 19),
    const Color.fromARGB(255, 29, 217, 238),
    const Color.fromARGB(255, 30, 54, 163),
  ];

  final List<Color> _pieColors = [
    const Color.fromARGB(255, 206, 13, 13),
    const Color(0xFFF0792B),
    const Color.fromARGB(255, 240, 201, 43),
    const Color.fromARGB(255, 38, 211, 19),
    const Color.fromARGB(255, 29, 217, 238),
    const Color.fromARGB(255, 30, 54, 163),
  ];

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trends = _trends[_selectedPeriod]!;
    final total = trends.fold<int>(
      0,
      (sum, item) => sum + (item['count'] as int),
    );
    final maxValue =
        trends
            .map((e) => e['count'] as int)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFE6D2B0),
      body: SafeArea(
        child: Column(
          children: [
            // Header: verde acqua e testo bianco, selezioni arancioni
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: const Color(0xFF00897B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trend dei Tag',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dropdown periodo bianco con testo acqua
                          Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButton<String>(
                              value: _selectedPeriod,
                              dropdownColor: Colors.white,
                              underline: const SizedBox(),
                              style: const TextStyle(
                                color: Color(0xFF00897B),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF00897B),
                              ),
                              items:
                                  _trends.keys
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e,
                                            style: const TextStyle(
                                              color: Color(0xFF00897B),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() => _selectedPeriod = v!),
                            ),
                          ),
                          // Toggle tipo grafico bianco bordo acqua, selezione arancione
                          ToggleButtons(
                            borderRadius: BorderRadius.circular(16),
                            borderColor: Colors.white,
                            selectedBorderColor: Colors.white,
                            fillColor: const Color(0xFFF0792B),
                            selectedColor: Colors.white,
                            color: Colors.white,
                            constraints: const BoxConstraints(
                              minHeight: 36,
                              minWidth: 90,
                            ),
                            isSelected: [_isBarChart, !_isBarChart],
                            onPressed:
                                (i) => setState(() => _isBarChart = i == 0),
                            children: const [Text('Istogramma'), Text('Torta')],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Grafico con altezza fissa e padding uniforme
            SizedBox(
              height: screenHeight * 0.45,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Card(
                  color: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isBarChart
                              ? 'Istogramma di ${_selectedPeriod.toLowerCase()}'
                              : 'Grafico a torta di ${_selectedPeriod.toLowerCase()}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00897B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child:
                              _isBarChart
                                  ? BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      borderData: FlBorderData(show: false),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (v, meta) {
                                              final idx = v.toInt();
                                              return idx < trends.length
                                                  ? Text(
                                                    trends[idx]['tag'],
                                                    style: TextStyle(
                                                      color:
                                                          _barColors[idx %
                                                              _barColors
                                                                  .length],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  )
                                                  : const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        topTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (v, meta) {
                                              final idx = v.toInt();
                                              if (idx < trends.length) {
                                                final count =
                                                    trends[idx]['count'] as int;
                                                final percent = (count /
                                                        total *
                                                        100)
                                                    .toStringAsFixed(1);
                                                return Text(
                                                  '$count ($percent%)',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        rightTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      gridData: FlGridData(show: false),
                                      maxY: maxValue * 1.2,
                                      barGroups: List.generate(
                                        trends.length,
                                        (i) => BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY:
                                                  (trends[i]['count'] as int)
                                                      .toDouble(),
                                              color:
                                                  _barColors[i %
                                                      _barColors.length],
                                              width: 24,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ],
                                        ),
                                      ),
                                      barTouchData: BarTouchData(
                                        enabled: false,
                                      ),
                                    ),
                                  )
                                  : PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 40,
                                      sections: List.generate(trends.length, (
                                        i,
                                      ) {
                                        final count = trends[i]['count'] as int;
                                        final percent = (count / total * 100)
                                            .toStringAsFixed(1);
                                        return PieChartSectionData(
                                          value: count.toDouble(),
                                          title:
                                              '${trends[i]['tag']}\n$percent%',
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          color:
                                              _pieColors[i % _pieColors.length],
                                        );
                                      }),
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16), // spazio sotto il grafico
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _navController.selectedIndex,
        onTap: (idx) => _navController.changeTab(idx, context),
      ),
    );
  }
}
