import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../profile/profile_provider.dart';
import '../../readings/readings_provider.dart';

class PredictionScreen extends ConsumerWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync  = ref.watch(profileProvider);
    final readingsAsync = ref.watch(readingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ML Prediction')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text(e.toString())),
        data: (profile) => readingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text(e.toString())),
          data: (readings) {
            final latest = readings.isNotEmpty ? readings.last : null;
            final bmi    = profile.bmi;
            final age    = profile.age;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFEF9F27).withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF854F0B), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Predictions are run by your doctor. '
                        'This screen shows the inputs that will be used.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF633806)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                Text('Prediction inputs',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Column(children: [
                      _InputRow(label: 'Pregnancies',
                          value: profile.pregnancies?.toString() ?? '—',
                          icon: Icons.child_care_outlined),
                      _InputRow(label: 'Glucose',
                          value: latest != null
                              ? '${latest.data.glucose.toStringAsFixed(1)} mg/dL'
                              : '—',
                          icon: Icons.water_drop_outlined),
                      _InputRow(label: 'Blood pressure',
                          value: latest != null
                              ? '${latest.data.bloodPressure.toStringAsFixed(1)} mmHg'
                              : '—',
                          icon: Icons.favorite_border_outlined),
                      _InputRow(label: 'Skin thickness',
                          value: latest != null
                              ? '${latest.data.skinThickness.toStringAsFixed(1)} mm'
                              : '—',
                          icon: Icons.straighten_outlined),
                      _InputRow(label: 'Insulin',
                          value: latest != null
                              ? '${latest.data.insulin.toStringAsFixed(1)} μU/mL'
                              : '—',
                          icon: Icons.science_outlined),
                      _InputRow(label: 'BMI',
                          value: bmi != null ? bmi.toStringAsFixed(1) : '—',
                          icon: Icons.monitor_weight_outlined,
                          sub: bmi != null
                              ? '${profile.weightKg?.toStringAsFixed(0)} kg / '
                                '${profile.heightCm?.toStringAsFixed(0)} cm'
                              : 'Complete your profile'),
                      _InputRow(label: 'Age',
                          value: age?.toString() ?? '—',
                          icon: Icons.cake_outlined),
                      _InputRow(label: 'Diabetes Pedigree',
                          value: '0.5 (default)',
                          icon: Icons.account_tree_outlined,
                          sub: 'Family history not yet collected',
                          isLast: true),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Data source
                if (latest != null) ...[
                  Text('Data source',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.sensors,
                              color: Color(0xFF0F6E56), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Latest sensor reading',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('MMM d, yyyy — HH:mm')
                                  .format(latest.timestamp),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                ],

                // Profile warning
                if (bmi == null || age == null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFE24B4A).withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_outlined,
                          color: Color(0xFFA32D2D), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Complete your profile (weight, height, date of birth) '
                          'so your doctor can run an accurate prediction.',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF7A1F1F)),
                        ),
                      ),
                    ]),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? sub;
  final bool isLast;
  const _InputRow({required this.label, required this.value,
      required this.icon, this.sub, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5))),
              if (sub != null)
                Text(sub!, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.35),
                    fontSize: 11)),
            ],
          )),
          Text(value, style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
        ]),
      ),
      if (!isLast) const Divider(height: 1),
    ]);
  }
}
