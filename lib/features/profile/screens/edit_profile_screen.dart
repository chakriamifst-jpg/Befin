import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _pregCtrl = TextEditingController();
  DateTime? _dob;
  bool _loading = false;
  bool _initialized = false;
  bool _isFemale = false;
  @override
  void dispose() {
    for (final c in [
      _firstCtrl,
      _lastCtrl,
      _phoneCtrl,
      _weightCtrl,
      _heightCtrl,
      _pregCtrl
    ]) c.dispose();
    super.dispose();
  }

  void _initFrom(profile) {
    if (_initialized) return;
    _firstCtrl.text = profile.firstName ?? '';
    _lastCtrl.text = profile.lastName ?? '';
    _phoneCtrl.text = profile.phoneNumber ?? '';
    _weightCtrl.text = profile.weightKg?.toString() ?? '';
    _heightCtrl.text = profile.heightCm?.toString() ?? '';

    _pregCtrl.text = profile.pregnancies?.toString() ?? '';
    _isFemale = (profile.pregnancies != null && profile.pregnancies! > 0);

    _dob = profile.dateOfBirth;
    _initialized = true;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _dob = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(profileNotifierProvider.notifier).updateProfile({
        'firstName': _firstCtrl.text.trim(),
        'lastName': _lastCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'dateOfBirth': _dob?.toIso8601String(),
        'weightKg': double.tryParse(_weightCtrl.text),
        'heightCm': double.tryParse(_heightCtrl.text),
        'pregnancies': _isFemale ? (int.tryParse(_pregCtrl.text) ?? 0) : 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated!')));
        context.go('/profile');
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profile) {
          _initFrom(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(children: [
                _field(_firstCtrl, 'First name', required: true),
                _field(_lastCtrl, 'Last name', required: true),
                _field(_phoneCtrl, 'Phone number'),
                _field(_weightCtrl, 'Weight (kg)',
                    type: TextInputType.number,
                    validator: (v) => _numValidator(v, 20, 300, 'Weight')),
                _field(_heightCtrl, 'Height (cm)',
                    type: TextInputType.number,
                    validator: (v) => _numValidator(v, 50, 250, 'Height')),
                // Selector Male / Female
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isFemale = false;
                        _pregCtrl.text = '0';
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_isFemale
                              ? const Color(0xFF1D9E75)
                              : Colors.transparent,
                          border: Border.all(color: const Color(0xFF1D9E75)),
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12)),
                        ),
                        child: Center(
                            child: Text('Male',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: !_isFemale
                                      ? Colors.white
                                      : const Color(0xFF1D9E75),
                                ))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isFemale = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isFemale
                              ? const Color(0xFF1D9E75)
                              : Colors.transparent,
                          border: Border.all(color: const Color(0xFF1D9E75)),
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(12)),
                        ),
                        child: Center(
                            child: Text('Female',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: _isFemale
                                      ? Colors.white
                                      : const Color(0xFF1D9E75),
                                ))),
                      ),
                    ),
                  ),
                ]),

// Pregnancies visible seulement si Female
                if (_isFemale) ...[
                  const SizedBox(height: 14),
                  _field(_pregCtrl, 'Pregnancies',
                      type: TextInputType.number,
                      validator: (v) => _numValidator(v, 0, 20, 'Pregnancies')),
                ],
                const SizedBox(height: 14),
                const SizedBox(height: 4),
                // Date picker
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Date of birth',
                        prefixIcon: Icon(Icons.cake_outlined)),
                    child: Text(
                      _dob != null
                          ? DateFormat('MMM d, yyyy').format(_dob!)
                          : 'Select date',
                      style:
                          TextStyle(color: _dob != null ? null : Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save changes'),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(labelText: label),
          validator: validator ??
              (required
                  ? (v) => (v == null || v.isEmpty) ? 'Required' : null
                  : null),
        ),
      );

  String? _numValidator(String? v, num min, num max, String field) {
    if (v == null || v.isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return 'Invalid number';
    if (n < min || n > max) return '$field must be between $min and $max';
    return null;
  }
}
