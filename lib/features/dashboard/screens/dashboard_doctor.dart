// import 'package:bfine/features/dashboard/doctorDash_provider.dart';
// import 'package:bfine/features/profile/profile_provider.dart';
// import 'package:bfine/features/readings/readings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// class DashboardDoctor extends ConsumerWidget {
//   const DashboardDoctor({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final profileAsync = ref.watch(profileProvider);
//     final mesPatientAsync = ref.watch(mesPatientProvider);
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: profileAsync.when(
//             data: (p) => Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     Text(
//                       "good morning Dr",
//                       style: theme.textTheme.bodySmall?.copyWith(
//                           color: theme.colorScheme.onSurface.withOpacity(0.5)),
//                     ),
//                     Text(p.fullName,
//                         style: theme.textTheme.titleMedium
//                             ?.copyWith(fontWeight: FontWeight.w600)),
//                   ],
//                 ),
//             error: (_, __) => Text("erreur"),
//             loading: () => Text("loading")),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh_outlined),
//             onPressed: () {
//               ref.invalidate(readingsProvider);
//               ref.invalidate(profileProvider);
//             },
//           ),
//         ],
//       ),
//       body: mesPatientAsync.when(
//         data: (nbr) => Center(
//           // Center est mieux que Row pour un chiffre seul
//           child: Text(
//             'Patients assignés : $nbr',
//             style: theme.textTheme.headlineMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//               color: theme.colorScheme.primary,
//             ),
//           ),
//         ),
//         error: (err, stack) => Center(child: Text("Erreur de chargement")),
//         loading: () => const Center(child: CircularProgressIndicator()),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profile/profile_provider.dart';
import '../doctor_providers.dart';

class DashboardDoctor extends ConsumerWidget {
  const DashboardDoctor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final countAsync = ref.watch(patientCountProvider);
    final patientsAsync = ref.watch(myPatientsProvider);
    final theme = Theme.of(context);
    final green = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome,',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5))),
              Text('Dr. ${p.fullName}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(profileProvider);
              ref.invalidate(patientCountProvider);
              ref.invalidate(myPatientsProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Stats card ─────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.people_outline, color: green, size: 28),
                ),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('My Patients',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  countAsync.when(
                    data: (c) => Text('$c patients',
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600, color: green)),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('—'),
                  ),
                ]),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/doctor/patients'),
                  child: const Text('View all'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // ── Recent patients ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent patients',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => context.go('/doctor/patients'),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          patientsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorCard(
                message: e.toString(),
                onRetry: () => ref.invalidate(myPatientsProvider)),
            data: (patients) {
              if (patients.isEmpty) return const _EmptyPatients();
              final recent = patients.take(5).toList();
              return Column(
                children: recent
                    .map((p) => _PatientCard(
                          patient: p,
                          onTap: () => context.go(
                            '/doctor/patients/${p.id}',
                            extra: p,
                          ),
                          // Passer l'objet patient complet via extra
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientSummary patient;
  final VoidCallback onTap;
  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = theme.colorScheme.primary;
    final initials = patient.fullName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: green.withOpacity(0.1),
          child: Text(initials,
              style: TextStyle(color: green, fontWeight: FontWeight.w600)),
        ),
        title: Text(patient.fullName,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: patient.phoneNumber != null
            ? Text(patient.phoneNumber!,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5)))
            : null,
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }
}

class _EmptyPatients extends StatelessWidget {
  const _EmptyPatients();
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(children: [
              Icon(Icons.people_outline,
                  size: 48, color: Colors.grey.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text('No patients yet',
                  style: TextStyle(color: Colors.grey)),
            ]),
          ),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Icon(Icons.error_outline, color: Color(0xFFE24B4A)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ]),
        ),
      );
}
