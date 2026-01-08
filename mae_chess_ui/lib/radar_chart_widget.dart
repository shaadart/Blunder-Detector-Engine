import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MaeRadarChart extends StatelessWidget {
  final double objective; // Win Probability
  final double fragility; // Graph Fragility
  final double chaos;     // Calculation Chaos

  const MaeRadarChart({
    super.key,
    required this.objective,
    required this.fragility,
    required this.chaos,
  });

  @override
  Widget build(BuildContext context) {
    // We visualize 3 Axes.
    // We can duplicate them to make a shape (e.g. 3 points makes a triangle)
    
    return SizedBox(
      height: 150,
      width: 150,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          gridBorderData: const BorderSide(color: Colors.white12, width: 2),
          tickBorderData: const BorderSide(color: Colors.transparent),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: const TextStyle(color: Colors.white70, fontSize: 10),
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          
          // The Axes Titles
          getTitle: (index, angle) {
            switch (index) {
              case 0: return const RadarChartTitle(text: 'WIN PROB');
              case 1: return const RadarChartTitle(text: 'FRAGILITY');
              case 2: return const RadarChartTitle(text: 'CHAOS');
              default: return const RadarChartTitle(text: '');
            }
          },
          
          // The Data Blob
          dataSets: [
            RadarDataSet(
              fillColor: const Color(0xFF00E5FF).withOpacity(0.2), // Cyan Tint
              borderColor: const Color(0xFF00E5FF),
              entryRadius: 2,
              borderWidth: 2,
              dataEntries: [
                RadarEntry(value: objective),
                RadarEntry(value: fragility),
                RadarEntry(value: chaos),
              ],
            ),
             // Dummy invisible dataset to force scale 0.0 to 1.0
             RadarDataSet(
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              dataEntries: [
                const RadarEntry(value: 0.0),
                const RadarEntry(value: 0.0),
                const RadarEntry(value: 0.0),
              ],
            ),
             RadarDataSet(
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              dataEntries: [
                const RadarEntry(value: 1.0),
                const RadarEntry(value: 1.0),
                const RadarEntry(value: 1.0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}