import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../profile_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _currCtrl    = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading      = false;
  bool _obscureCurr  = true;
  bool _obscureNew   = true;
  bool _obscureConf  = true;

  @override
  void dispose() {
    _currCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(profileNotifierProvider.notifier)
          .changePassword(_currCtrl.text, _newCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully!')));
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            const SizedBox(height: 16),
            _passField(_currCtrl, 'Current password', _obscureCurr,
                () => setState(() => _obscureCurr = !_obscureCurr)),
            const SizedBox(height: 14),
            _passField(_newCtrl, 'New password', _obscureNew,
                () => setState(() => _obscureNew = !_obscureNew),
                validator: (v) => (v != null && v.length < 6) ? 'Min 6 characters' : null),
            const SizedBox(height: 14),
            _passField(_confirmCtrl, 'Confirm new password', _obscureConf,
                () => setState(() => _obscureConf = !_obscureConf),
                validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Update password'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String label,
      bool obscure, VoidCallback toggle,
      {String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: toggle,
          ),
        ),
        validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      );
}
