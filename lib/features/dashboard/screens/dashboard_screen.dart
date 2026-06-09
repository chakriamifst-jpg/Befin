import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../readings/readings_provider.dart';
import '../../profile/profile_provider.dart';
import '../../../core/models/models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final readingsAsync = ref.watch(readingsProvider);
    final theme = Theme.of(context);
    final green = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning,',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5))),
              Text(p.fullName,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Bfine'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(readingsProvider);
              ref.invalidate(profileProvider);
            },
          ),
        ],
      ),
      body: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(readingsProvider)),
        data: (readings) {
          if (readings.isEmpty) return const _EmptyState();
          final latest = readings.last;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(readingsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionLabel(
                    label: 'Latest reading',
                    sub: DateFormat('MMM d, HH:mm').format(latest.timestamp)),
                const SizedBox(height: 10),
                _MetricsGrid(reading: latest),
                const SizedBox(height: 20),
                _SectionLabel(
                    label: 'Glucose history',
                    sub: 'Last ${readings.length} readings'),
                const SizedBox(height: 10),
                _GlucoseChart(readings: readings),
                const SizedBox(height: 20),
                _SectionLabel(label: 'Quick actions'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _QuickAction(
                    icon: Icons.water_drop_outlined,
                    label: 'All readings',
                    color: green,
                    onTap: () => context.go('/readings'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _QuickAction(
                    icon: Icons.psychology_outlined,
                    label: 'Prediction',
                    color: const Color(0xFF854F0B),
                    bgColor: const Color(0xFFFAEEDA),
                    onTap: () => context.go('/prediction'),
                  )),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final Reading reading;
  const _MetricsGrid({required this.reading});

  @override
  Widget build(BuildContext context) {
    final d = reading.data;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _MetricCard(
            label: 'Glucose',
            value: d.glucose,
            unit: 'mg/dL',
            normal: d.glucose < 130),
        _MetricCard(
            label: 'Blood pressure',
            value: d.bloodPressure,
            unit: 'mmHg',
            normal: d.bloodPressure < 90),
        _MetricCard(
            label: 'Insulin',
            value: d.insulin,
            unit: 'μU/mL',
            normal: d.insulin < 100),
        _MetricCard(
            label: 'Skin thickness',
            value: d.skinThickness,
            unit: 'mm',
            normal: d.skinThickness < 35),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool normal;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.unit,
      required this.normal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = normal ? const Color(0xFF1D9E75) : const Color(0xFFE24B4A);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value.toStringAsFixed(1),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600, color: color)),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4))),
                ),
              ],
            ),
            Row(children: [
              Icon(
                  normal
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  size: 12,
                  color: color),
              const SizedBox(width: 3),
              Text(normal ? 'Normal' : 'Elevated',
                  style: TextStyle(fontSize: 11, color: color)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _GlucoseChart extends StatelessWidget {
  final List<Reading> readings;
  const _GlucoseChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final recent = readings.length > 10
        ? readings.sublist(readings.length - 10)
        : readings;
    final spots = recent
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.data.glucose))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: SizedBox(
          height: 160,
          child: LineChart(LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              )),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= recent.length) return const SizedBox();
                  return Text(DateFormat('d/M').format(recent[i].timestamp),
                      style: const TextStyle(fontSize: 9, color: Colors.grey));
                },
              )),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFF1D9E75),
                barWidth: 2.5,
                dotData: FlDotData(
                  getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                    radius: 3,
                    color: s.y > 130
                        ? const Color(0xFFE24B4A)
                        : const Color(0xFF1D9E75),
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF1D9E75).withOpacity(0.08)),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? bgColor;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap,
      this.bgColor});

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (bgColor ?? color).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style:
                        TextStyle(fontWeight: FontWeight.w500, color: color)),
              ),
            ]),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? sub;
  const _SectionLabel({required this.label, this.sub});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        if (sub != null)
          Text(sub!,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4))),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.water_drop_outlined,
              size: 64, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No readings yet', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          const Text('Readings will appear once your device syncs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFE24B4A)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ]),
      );
}
