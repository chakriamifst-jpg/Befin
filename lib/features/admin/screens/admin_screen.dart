import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../admin_providers.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'patient';
  bool _obscure = true;
  bool _showCreateForm = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(adminDoctorsProvider);
    ref.invalidate(adminPatientsProvider);
  }

  // ── Delete ────────────────────────────────────────────
  void _confirmDelete(int userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: Text('Delete $name?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE24B4A)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(adminNotifierProvider.notifier)
                    .deleteUser(userId);
                _refresh();
                if (mounted) _showSnack('User deleted', isError: false);
              } catch (e) {
                if (mounted) _showSnack(e.toString(), isError: true);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Assign ────────────────────────────────────────────
  void _openAssignModal(PatientWithDoctor pwd, List<AdminUser> doctors) {
    int? selectedDoctorId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text('Assign doctor to ${pwd.patient.fullName}'),
          content: DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Select doctor'),
            items: doctors
                .map((d) => DropdownMenuItem(
                      value: d.id,
                      child: Text(d.fullName),
                    ))
                .toList(),
            onChanged: (v) => setModalState(() => selectedDoctorId = v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedDoctorId == null) return;
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(adminNotifierProvider.notifier)
                      .assignDoctor(selectedDoctorId!, pwd.patient.id);
                  _refresh();
                  if (mounted) _showSnack('Doctor assigned', isError: false);
                } catch (e) {
                  if (mounted) _showSnack(e.toString(), isError: true);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Unassign ──────────────────────────────────────────
  void _confirmUnassign(int patientId, String patientName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove assignment'),
        content: Text('Remove doctor from $patientName?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE24B4A)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(adminNotifierProvider.notifier)
                    .unassignDoctor(patientId);
                _refresh();
                if (mounted) _showSnack('Doctor removed', isError: false);
              } catch (e) {
                if (mounted) _showSnack(e.toString(), isError: true);
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Create user ───────────────────────────────────────
  Future<void> _createUser() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() {
        _errorMsg = 'All fields are required.';
        _successMsg = null;
      });
      return;
    }
    try {
      await ref.read(adminNotifierProvider.notifier).createUser(
            _usernameCtrl.text.trim(),
            _passwordCtrl.text,
            _selectedRole,
          );
      setState(() {
        _successMsg = 'User created successfully!';
        _errorMsg = null;
        _showCreateForm = false;
        _usernameCtrl.clear();
        _passwordCtrl.clear();
        _selectedRole = 'patient';
      });
      _refresh();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _successMsg = null);
      });
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      setState(() {
        _errorMsg = msg ?? 'Error creating user.';
        _successMsg = null;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _successMsg = null;
      });
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? const Color(0xFFE24B4A) : const Color(0xFF1D9E75),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = theme.colorScheme.primary;

    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ clavier géré automatiquement
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_outlined), onPressed: _refresh),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: green,
          indicatorColor: green,
          tabs: const [
            Tab(icon: Icon(Icons.medical_services_outlined), text: 'Doctors'),
            Tab(icon: Icon(Icons.people_outline), text: 'Patients'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Tab views ──────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // ── Doctors tab ────────────────────────
                ref.watch(adminDoctorsProvider).when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          _ErrorState(message: e.toString(), onRetry: _refresh),
                      data: (doctors) => doctors.isEmpty
                          ? const _Empty(label: 'No doctors found')
                          : RefreshIndicator(
                              onRefresh: () async => _refresh(),
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: doctors.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final d = doctors[i];
                                  return _UserCard(
                                    user: d,
                                    badge: 'Doctor',
                                    badgeColor: const Color(0xFF5B8FE8),
                                    onDelete: () =>
                                        _confirmDelete(d.id, d.fullName),
                                  );
                                },
                              ),
                            ),
                    ),

                // ── Patients tab ───────────────────────
                ref.watch(adminPatientsProvider).when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          _ErrorState(message: e.toString(), onRetry: _refresh),
                      data: (patients) {
                        final doctors =
                            ref.watch(adminDoctorsProvider).valueOrNull ?? [];
                        return patients.isEmpty
                            ? const _Empty(label: 'No patients found')
                            : RefreshIndicator(
                                onRefresh: () async => _refresh(),
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: patients.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, i) {
                                    final pwd = patients[i];
                                    return _PatientCard(
                                      pwd: pwd,
                                      onDelete: () => _confirmDelete(
                                          pwd.patient.id, pwd.patient.fullName),
                                      onAssign: () =>
                                          _openAssignModal(pwd, doctors),
                                      onUnassign: () => _confirmUnassign(
                                          pwd.patient.id, pwd.patient.fullName),
                                    );
                                  },
                                ),
                              );
                      },
                    ),
              ],
            ),
          ),

          // ── Create user form ───────────────────────────
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                    color: Colors.black.withOpacity(0.08), width: 0.5),
              ),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              // ✅ padding dynamique quand clavier apparaît
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ prend le minimum d'espace
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bouton toggle
                if (!_showCreateForm) ...[
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _showCreateForm = true),
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Create new user'),
                        style: TextButton.styleFrom(foregroundColor: green),
                      ),
                      if (_successMsg != null) ...[
                        const SizedBox(width: 8),
                        Text(_successMsg!,
                            style: const TextStyle(
                                color: Color(0xFF1D9E75), fontSize: 12)),
                      ],
                    ],
                  ),
                ] else ...[
                  // Header du form
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Create user',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _showCreateForm = false;
                          _errorMsg = null;
                          _successMsg = null;
                          _usernameCtrl.clear();
                          _passwordCtrl.clear();
                          _selectedRole = 'patient';
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Username
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Password
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Role
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration:
                        const InputDecoration(labelText: 'Role', isDense: true),
                    items: const [
                      DropdownMenuItem(
                          value: 'patient', child: Text('Patient')),
                      DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                    ],
                    onChanged: (v) => setState(() => _selectedRole = v!),
                  ),
                  const SizedBox(height: 10),

                  // Submit
                  ElevatedButton.icon(
                    onPressed: _createUser,
                    icon: const Icon(Icons.add),
                    label: const Text('Create user'),
                  ),

                  // Messages
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 6),
                    Text(_errorMsg!,
                        style: const TextStyle(
                            color: Color(0xFFE24B4A), fontSize: 12)),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Doctor card
// ─────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final AdminUser user;
  final String badge;
  final Color badgeColor;
  final VoidCallback onDelete;
  const _UserCard(
      {required this.user,
      required this.badge,
      required this.badgeColor,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final initials = user.fullName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: badgeColor.withOpacity(0.1),
            child: Text(initials,
                style:
                    TextStyle(color: badgeColor, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge,
                      style: TextStyle(
                          fontSize: 11,
                          color: badgeColor,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
              const SizedBox(height: 2),
              Text(user.username,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (user.phoneNumber != null)
                Text(user.phoneNumber!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE24B4A)),
            onPressed: onDelete,
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Patient card
// ─────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final PatientWithDoctor pwd;
  final VoidCallback onDelete;
  final VoidCallback onAssign;
  final VoidCallback onUnassign;
  const _PatientCard(
      {required this.pwd,
      required this.onDelete,
      required this.onAssign,
      required this.onUnassign});

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    final p = pwd.patient;
    final initials = p.fullName
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: green.withOpacity(0.1),
            child: Text(initials,
                style: TextStyle(color: green, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(p.username,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              pwd.assignedDoctor != null
                  ? Row(children: [
                      const Icon(Icons.medical_services_outlined,
                          size: 13, color: Color(0xFF1D9E75)),
                      const SizedBox(width: 4),
                      Text(pwd.assignedDoctor!.doctorName,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1D9E75),
                              fontWeight: FontWeight.w500)),
                    ])
                  : const Text('No doctor assigned',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )),
          pwd.assignedDoctor == null
              ? TextButton(
                  onPressed: onAssign,
                  child: const Text('Assign',
                      style: TextStyle(color: Color(0xFF1D9E75))))
              : TextButton(
                  onPressed: onUnassign,
                  child: const Text('Remove',
                      style: TextStyle(color: Color(0xFFE24B4A)))),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE24B4A)),
            onPressed: onDelete,
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
class _Empty extends StatelessWidget {
  final String label;
  const _Empty({required this.label});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_outlined,
              size: 48, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
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
          TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ]),
      );
}
