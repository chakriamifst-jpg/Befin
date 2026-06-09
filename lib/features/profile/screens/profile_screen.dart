import 'package:bfine/features/readings/readings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../profile_provider.dart';
import '../../../features/auth/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final green = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/profile/edit'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profile) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar
              Center(
                child: Column(children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                        color: green.withOpacity(0.12), shape: BoxShape.circle),
                    child: Center(
                      child: Text(_initials(profile.fullName),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: green)),
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
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('Patient',
                        style: TextStyle(
                            color: green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              _SectionTitle(title: 'Health information'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(children: [
                    _ProfileRow(
                        label: 'Date of birth',
                        value: profile.dateOfBirth != null
                            ? DateFormat('MMM d, yyyy')
                                .format(profile.dateOfBirth!)
                            : '—'),
                    _ProfileRow(
                        label: 'Weight',
                        value: profile.weightKg != null
                            ? '${profile.weightKg!.toStringAsFixed(1)} kg'
                            : '—'),
                    _ProfileRow(
                        label: 'Height',
                        value: profile.heightCm != null
                            ? '${profile.heightCm!.toStringAsFixed(0)} cm'
                            : '—'),
                    _ProfileRow(
                        label: 'BMI',
                        value: profile.bmi != null
                            ? profile.bmi!.toStringAsFixed(1)
                            : '—',
                        valueColor: _bmiColor(profile.bmi)),
                    _ProfileRow(
                        label: 'Pregnancies',
                        value: profile.pregnancies?.toString() ?? '—',
                        isLast: true),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              _SectionTitle(title: 'Contact'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _ProfileRow(
                      label: 'Phone',
                      value: profile.phoneNumber ?? '—',
                      isLast: true),
                ),
              ),
              const SizedBox(height: 16),

              _SectionTitle(title: 'Account'),
              const SizedBox(height: 8),
              Card(
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change password'),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.go('/profile/change-password'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: theme.colorScheme.error),
                    title: Text('Sign out',
                        style: TextStyle(color: theme.colorScheme.error)),
                    onTap: () async {
                      await AuthService().logout(ref);
                      ref.invalidate(profileProvider);
                      ref.invalidate(readingsProvider);

                      if (context.mounted) context.go('/login');
                    },
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w600));
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  final Color? valueColor;
  const _ProfileRow(
      {required this.label,
      required this.value,
      this.isLast = false,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
