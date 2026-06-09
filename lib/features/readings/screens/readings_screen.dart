import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../readings_provider.dart';
import '../../../core/models/models.dart';

class ReadingsScreen extends ConsumerStatefulWidget {
  const ReadingsScreen({super.key});
  @override
  ConsumerState<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends ConsumerState<ReadingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(readingsProvider);
    final theme = Theme.of(context);
    final green = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Readings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(readingsProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: green,
          indicatorColor: green,
          tabs: const [Tab(text: 'History'), Tab(text: 'Charts')],
        ),
      ),
      body: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE24B4A)),
            const SizedBox(height: 12),
            Text(e.toString(), textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextButton.icon(
                onPressed: () => ref.invalidate(readingsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ]),
        ),
        data: (readings) {
          if (readings.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.water_drop_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No readings yet', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 6),
                Text('Your device will sync readings automatically.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
            );
          }
          final reversed = readings.reversed.toList();
          return TabBarView(
            controller: _tabs,
            children: [
              // History tab
              RefreshIndicator(
                onRefresh: () async => ref.invalidate(readingsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reversed.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ReadingTile(reading: reversed[i]),
                ),
              ),
              // Charts tab
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ChartCard(title: 'Glucose (mg/dL)',        readings: readings, getValue: (r) => r.data.glucose,       normalThreshold: 130, color: green),
                  const SizedBox(height: 12),
                  _ChartCard(title: 'Blood Pressure (mmHg)',  readings: readings, getValue: (r) => r.data.bloodPressure, normalThreshold: 90,  color: const Color(0xFF5B8FE8)),
                  const SizedBox(height: 12),
                  _ChartCard(title: 'Insulin (μU/mL)',        readings: readings, getValue: (r) => r.data.insulin,       normalThreshold: 100, color: const Color(0xFFE2904B)),
                  const SizedBox(height: 12),
                  _ChartCard(title: 'Skin Thickness (mm)',    readings: readings, getValue: (r) => r.data.skinThickness, normalThreshold: 35,  color: const Color(0xFF9B59B6)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final Reading reading;
  const _ReadingTile({required this.reading});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final d      = reading.data;
    final isHigh = d.glucose > 130 || d.bloodPressure > 90 || d.insulin > 100;
    final color  = isHigh ? const Color(0xFFE24B4A) : const Color(0xFF1D9E75);
    final bg     = isHigh ? const Color(0xFFFCEBEB) : const Color(0xFFE1F5EE);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(Icons.water_drop_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'G: ${d.glucose.toStringAsFixed(0)}  '
                'BP: ${d.bloodPressure.toStringAsFixed(0)}  '
                'Ins: ${d.insulin.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 3),
              Text('Skin: ${d.skinThickness.toStringAsFixed(0)} mm',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5))),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(20)),
              child: Text(isHigh ? 'Elevated' : 'Normal',
                  style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w500, color: color)),
            ),
            const SizedBox(height: 4),
            Text(DateFormat('MMM d, HH:mm').format(reading.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4))),
          ]),
        ]),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<Reading> readings;
  final double Function(Reading) getValue;
  final double normalThreshold;
  final Color color;
  const _ChartCard({required this.title, required this.readings,
      required this.getValue, required this.normalThreshold, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final recent = readings.length > 14 ? readings.sublist(readings.length - 14) : readings;
    final spots  = recent.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), getValue(e.value)))
        .toList();
    final values = spots.map((s) => s.y).toList();
    final minY   = (values.reduce((a, b) => a < b ? a : b) - 10).clamp(0.0, 9999.0);
    final maxY   =  values.reduce((a, b) => a > b ? a : b) + 10;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(LineChartData(
              minY: minY, maxY: maxY,
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.withOpacity(0.12), strokeWidth: 1),
              ),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: normalThreshold,
                  color: const Color(0xFFE24B4A).withOpacity(0.4),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (_) => 'limit',
                    style: const TextStyle(fontSize: 9, color: Color(0xFFE24B4A)),
                  ),
                ),
              ]),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 34,
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                      style: const TextStyle(fontSize: 9, color: Colors.grey)),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 18,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= recent.length || i % 3 != 0) return const SizedBox();
                    return Text(DateFormat('d/M').format(recent[i].timestamp),
                        style: const TextStyle(fontSize: 9, color: Colors.grey));
                  },
                )),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots, isCurved: true, color: color, barWidth: 2,
                  dotData: FlDotData(
                    getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                      radius: 3,
                      color: s.y > normalThreshold ? const Color(0xFFE24B4A) : color,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(show: true, color: color.withOpacity(0.07)),
                ),
              ],
            )),
          ),
        ]),
      ),
    );
  }
}
