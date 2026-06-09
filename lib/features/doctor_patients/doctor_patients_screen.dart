import 'package:bfine/features/dashboard/doctor_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
// import '../../features/profile/profile_provider.dart';
// import '../../features/readings/readings_provider.dart';
import '../../../core/models/models.dart';

// ─────────────────────────────────────────────
// Patients List Screen
// ─────────────────────────────────────────────
class DoctorPatientsScreen extends ConsumerWidget {
  const DoctorPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(myPatientsProvider);
    final theme = Theme.of(context);
    final green = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(myPatientsProvider),
          ),
        ],
      ),
      body: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE24B4A)),
            const SizedBox(height: 12),
            Text(e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextButton.icon(
                onPressed: () => ref.invalidate(myPatientsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ]),
        ),
        data: (patients) {
          if (patients.isEmpty) {
            return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64, color: Colors.grey.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    const Text('No patients assigned yet',
                        style: TextStyle(color: Colors.grey)),
                  ]),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myPatientsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: patients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = patients[i];
                final initials = p.fullName
                    .trim()
                    .split(' ')
                    .where((s) => s.isNotEmpty)
                    .take(2)
                    .map((s) => s[0].toUpperCase())
                    .join();
                return Card(
                  child: ListTile(
                    onTap: () => context.go(
                      '/doctor/patients/${p.id}',
                      extra: p,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: green.withOpacity(0.1),
                      child: Text(initials,
                          style: TextStyle(
                              color: green, fontWeight: FontWeight.w600)),
                    ),
                    title: Text(p.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle:
                        p.phoneNumber != null ? Text(p.phoneNumber!) : null,
                    trailing: const Icon(Icons.chevron_right, size: 18),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Patient Detail Screen (readings + ML)
// ─────────────────────────────────────────────
class PatientDetailScreen extends ConsumerStatefulWidget {
  // final PatientSummary patient;
  final PatientSummary patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(patientProfileProvider(widget.patient.id));
    final readingsAsync = ref.watch(patientReadingsProvider(widget.patient.id));
    final predState = ref.watch(predictionProvider(widget.patient.id));
    final predNotifier =
        ref.read(predictionProvider(widget.patient.id).notifier);
    final theme = Theme.of(context);
    final green = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.fullName),
        bottom: TabBar(
          controller: _tabs,
          labelColor: green,
          indicatorColor: green,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Readings'),
            Tab(text: 'ML Prediction'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tab 1: Overview (profile) ──────────────────
          profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (profile) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar + name
                Center(
                    child: Column(children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: green.withOpacity(0.1),
                    child: Text(
                      _initials(profile.fullName),
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: green),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(profile.fullName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('@${profile.username}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4))),
                ])),
                const SizedBox(height: 20),

                // Health info
                Text('Health information',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(children: [
                      _InfoRow(
                          label: 'Date of birth',
                          value: profile.dateOfBirth != null
                              ? DateFormat('MMM d, yyyy')
                                  .format(profile.dateOfBirth!)
                              : '—'),
                      _InfoRow(
                          label: 'Age', value: profile.age?.toString() ?? '—'),
                      _InfoRow(
                          label: 'Weight',
                          value: profile.weightKg != null
                              ? '${profile.weightKg!.toStringAsFixed(1)} kg'
                              : '—'),
                      _InfoRow(
                          label: 'Height',
                          value: profile.heightCm != null
                              ? '${profile.heightCm!.toStringAsFixed(0)} cm'
                              : '—'),
                      _InfoRow(
                          label: 'BMI',
                          value: profile.bmi != null
                              ? profile.bmi!.toStringAsFixed(1)
                              : '—',
                          valueColor: _bmiColor(profile.bmi)),
                      _InfoRow(
                          label: 'Pregnancies',
                          value: profile.pregnancies?.toString() ?? '—',
                          isLast: true),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Contact
                Text('Contact',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _InfoRow(
                        label: 'Phone',
                        value: profile.phoneNumber ?? '—',
                        isLast: true),
                  ),
                ),

                // Quick ML button
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _tabs.animateTo(2),
                  icon: const Icon(Icons.psychology_outlined),
                  label: const Text('Run ML Prediction'),
                ),
              ],
            ),
          ),

          // ── Tab 2: Readings ────────────────────────────
          readingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Color(0xFFE24B4A)),
                    const SizedBox(height: 12),
                    Text(e.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey)),
                    TextButton.icon(
                        onPressed: () => ref.invalidate(
                            patientReadingsProvider(widget.patient.id)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry')),
                  ]),
            ),
            data: (readings) {
              if (readings.isEmpty) {
                return const Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop_outlined,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No readings yet',
                            style: TextStyle(color: Colors.grey)),
                      ]),
                );
              }

              final reversed = readings.reversed.toList();
              final latest = readings.last;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Latest metrics
                  Text('Latest reading',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.6,
                    children: [
                      _MetricMini(
                          label: 'Glucose',
                          value: latest.data.glucose,
                          unit: 'mg/dL',
                          normal: latest.data.glucose < 130),
                      _MetricMini(
                          label: 'Blood pressure',
                          value: latest.data.bloodPressure,
                          unit: 'mmHg',
                          normal: latest.data.bloodPressure < 90),
                      _MetricMini(
                          label: 'Insulin',
                          value: latest.data.insulin,
                          unit: 'μU/mL',
                          normal: latest.data.insulin < 100),
                      _MetricMini(
                          label: 'Skin thickness',
                          value: latest.data.skinThickness,
                          unit: 'mm',
                          normal: latest.data.skinThickness < 35),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Glucose chart
                  Text('Glucose trend',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _GlucoseChart(readings: readings),
                  const SizedBox(height: 16),

                  // History list
                  Text('History (${readings.length} readings)',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...reversed.map((r) => _ReadingTile(reading: r)),
                ],
              );
            },
          ),

          // ── Tab 3: ML Prediction ───────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Result card
              if (predState.result != null) ...[
                _PredictionResultCard(result: predState.result!),
                const SizedBox(height: 16),
              ],

              // Error
              if (predState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFA32D2D), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(predState.error!,
                            style: const TextStyle(color: Color(0xFF7A1F1F)))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Run button
              ElevatedButton.icon(
                onPressed: predState.isLoading
                    ? null
                    : () => predNotifier.predict(widget.patient.id),
                icon: predState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.psychology_outlined),
                label: Text(predState.isLoading
                    ? 'Running prediction...'
                    : predState.result != null
                        ? 'Run again'
                        : 'Run ML Prediction'),
              ),
              const SizedBox(height: 20),

              // Inputs used
              Text('Inputs used for prediction',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              profileAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
                data: (profile) => readingsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                  data: (readings) {
                    final latest = readings.isNotEmpty ? readings.last : null;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Column(children: [
                          _InfoRow(
                              label: 'Pregnancies',
                              value: profile.pregnancies?.toString() ?? '—'),
                          _InfoRow(
                              label: 'Glucose',
                              value: latest != null
                                  ? '${latest.data.glucose.toStringAsFixed(1)} mg/dL'
                                  : '—'),
                          _InfoRow(
                              label: 'Blood pressure',
                              value: latest != null
                                  ? '${latest.data.bloodPressure.toStringAsFixed(1)} mmHg'
                                  : '—'),
                          _InfoRow(
                              label: 'Skin thickness',
                              value: latest != null
                                  ? '${latest.data.skinThickness.toStringAsFixed(1)} mm'
                                  : '—'),
                          _InfoRow(
                              label: 'Insulin',
                              value: latest != null
                                  ? '${latest.data.insulin.toStringAsFixed(1)} μU/mL'
                                  : '—'),
                          _InfoRow(
                              label: 'BMI',
                              value: profile.bmi != null
                                  ? profile.bmi!.toStringAsFixed(1)
                                  : '—'),
                          _InfoRow(
                              label: 'Age',
                              value: profile.age?.toString() ?? '—'),
                          _InfoRow(
                              label: 'DPF',
                              value: '0.5 (default)',
                              isLast: true),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color? _bmiColor(double? bmi) {
    if (bmi == null) return null;
    if (bmi < 18.5) return const Color(0xFF5B8FE8);
    if (bmi < 25) return const Color(0xFF1D9E75);
    if (bmi < 30) return const Color(0xFFE2904B);
    return const Color(0xFFE24B4A);
  }
}

// ─────────────────────────────────────────────
// Prediction result card
// ─────────────────────────────────────────────
class _PredictionResultCard extends StatelessWidget {
  final String result;
  const _PredictionResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDiabetic = result.toLowerCase().contains('diabetic') &&
        !result.toLowerCase().contains('not');
    final color =
        isDiabetic ? const Color(0xFFE24B4A) : const Color(0xFF1D9E75);
    final bgColor =
        isDiabetic ? const Color(0xFFFCEBEB) : const Color(0xFFE1F5EE);
    final icon =
        isDiabetic ? Icons.warning_amber_rounded : Icons.shield_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 12),
        Text(result,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 6),
        Text(
          isDiabetic
              ? 'Patient shows signs of diabetes. Further examination recommended.'
              : 'No signs of diabetes detected based on current data.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: color.withOpacity(0.8)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  final Color? valueColor;
  const _InfoRow(
      {required this.label,
      required this.value,
      this.isLast = false,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500, color: valueColor)),
          ],
        ),
      ),
      if (!isLast) const Divider(height: 1),
    ]);
  }
}

class _MetricMini extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool normal;
  const _MetricMini(
      {required this.label,
      required this.value,
      required this.unit,
      required this.normal});

  @override
  Widget build(BuildContext context) {
    final color = normal ? const Color(0xFF1D9E75) : const Color(0xFFE24B4A);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11)),
            Text('${value.toStringAsFixed(0)} $unit',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: color, fontSize: 14)),
            Row(children: [
              Icon(
                  normal
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  size: 11,
                  color: color),
              const SizedBox(width: 3),
              Text(normal ? 'OK' : 'High',
                  style: TextStyle(fontSize: 10, color: color)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final Reading reading;
  const _ReadingTile({required this.reading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = reading.data;
    final isHigh = d.glucose > 130 || d.bloodPressure > 90 || d.insulin > 100;
    final color = isHigh ? const Color(0xFFE24B4A) : const Color(0xFF1D9E75);
    final bg = isHigh ? const Color(0xFFFCEBEB) : const Color(0xFFE1F5EE);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(Icons.water_drop_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'G: ${d.glucose.toStringAsFixed(0)}  '
                  'BP: ${d.bloodPressure.toStringAsFixed(0)}  '
                  'Ins: ${d.insulin.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('Skin: ${d.skinThickness.toStringAsFixed(0)} mm',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4))),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(20)),
              child: Text(isHigh ? 'Elevated' : 'Normal',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w500, color: color)),
            ),
            const SizedBox(height: 3),
            Text(DateFormat('MMM d, HH:mm').format(reading.timestamp),
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ]),
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
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: SizedBox(
          height: 150,
          child: LineChart(LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: Colors.grey.withOpacity(0.12), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: const TextStyle(fontSize: 9, color: Colors.grey)),
              )),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
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
                barWidth: 2,
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
                    color: const Color(0xFF1D9E75).withOpacity(0.07)),
              ),
            ],
          )),
        ),
      ),
    );
  }
}
