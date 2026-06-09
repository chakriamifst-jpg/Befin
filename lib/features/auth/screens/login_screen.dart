// import 'package:bfine/core/auth/auth_storage.dart';
// import 'package:bfine/features/profile/profile_provider.dart';
// import 'package:bfine/features/readings/readings_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../auth_service.dart';

// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends ConsumerState<LoginScreen> {
//   final _userCtrl = TextEditingController();
//   final _passCtrl = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   final _service = AuthService();

//   bool _loading = false;
//   bool _obscure = true;
//   bool _isLogin = true;
//   String? _error;

//   @override
//   void dispose() {
//     _userCtrl.dispose();
//     _passCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       if (_isLogin) {
//         await _service.login(_userCtrl.text.trim(), _passCtrl.text);
//         ref.invalidate(profileProvider);
//         ref.invalidate(readingsProvider);
//         final userType = await AuthStorage.getUserType();
//         print('userType: $userType'); // Debug: print the user type
//         if (mounted) {
//           if (userType == 'patient') {
//             context.go('/dashboard');
//           } else if (userType == 'doctor') {
//             context.go('/dashDoctor');
//           }
//         }
//       } else {
//         await _service.register(_userCtrl.text.trim(), _passCtrl.text);
//         setState(() => _isLogin = true);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//               content: Text('Account created! Please sign in.')));
//         }
//       }
//     } catch (e) {
//       setState(() => _error = e.toString());
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final green = theme.colorScheme.primary;

//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 32),

//                 // Logo
//                 Center(
//                   child: Container(
//                     width: 72,
//                     height: 72,
//                     decoration: BoxDecoration(
//                         color: green, borderRadius: BorderRadius.circular(20)),
//                     child: const Icon(Icons.monitor_heart_outlined,
//                         color: Colors.white, size: 36),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Center(
//                     child: Text('Bfine',
//                         style: theme.textTheme.headlineMedium
//                             ?.copyWith(fontWeight: FontWeight.w600))),
//                 Center(
//                     child: Text('Your health, monitored.',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                             color:
//                                 theme.colorScheme.onSurface.withOpacity(0.5)))),
//                 const SizedBox(height: 48),

//                 Text(_isLogin ? 'Sign in' : 'Create account',
//                     style: theme.textTheme.titleLarge
//                         ?.copyWith(fontWeight: FontWeight.w500)),
//                 const SizedBox(height: 20),

//                 TextFormField(
//                   controller: _userCtrl,
//                   decoration: const InputDecoration(
//                     labelText: 'Username',
//                     prefixIcon: Icon(Icons.person_outline),
//                   ),
//                   validator: (v) =>
//                       (v == null || v.isEmpty) ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 14),

//                 TextFormField(
//                   controller: _passCtrl,
//                   obscureText: _obscure,
//                   decoration: InputDecoration(
//                     labelText: 'Password',
//                     prefixIcon: const Icon(Icons.lock_outline),
//                     suffixIcon: IconButton(
//                       icon: Icon(_obscure
//                           ? Icons.visibility_outlined
//                           : Icons.visibility_off_outlined),
//                       onPressed: () => setState(() => _obscure = !_obscure),
//                     ),
//                   ),
//                   validator: (v) =>
//                       (v == null || v.length < 6) ? 'Min 6 characters' : null,
//                 ),

//                 if (_error != null) ...[
//                   const SizedBox(height: 12),
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: theme.colorScheme.error.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(children: [
//                       Icon(Icons.error_outline,
//                           color: theme.colorScheme.error, size: 18),
//                       const SizedBox(width: 8),
//                       Expanded(
//                           child: Text(_error!,
//                               style: TextStyle(
//                                   color: theme.colorScheme.error,
//                                   fontSize: 13))),
//                     ]),
//                   ),
//                 ],

//                 const SizedBox(height: 24),

//                 ElevatedButton(
//                   onPressed: _loading ? null : _submit,
//                   child: _loading
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                               color: Colors.white, strokeWidth: 2))
//                       : Text(_isLogin ? 'Sign in' : 'Create account'),
//                 ),
//                 const SizedBox(height: 12),

//                 Center(
//                   child: TextButton(
//                     onPressed: () => setState(() {
//                       _isLogin = !_isLogin;
//                       _error = null;
//                     }),
//                     child: Text(
//                       _isLogin
//                           ? "Don't have an account? Register"
//                           : 'Already have an account? Sign in',
//                       style: TextStyle(color: green),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_service.dart';
import '../../../core/auth/auth_storage.dart';
import '../../profile/profile_provider.dart';
import '../../readings/readings_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _service = AuthService();

  bool _loading = false;
  bool _obscure = true;
  bool _isLogin = true;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isLogin) {
        await _service.login(_userCtrl.text.trim(), _passCtrl.text);

        // Invalidate all providers → fresh data for new user
        ref.invalidate(profileProvider);
        ref.invalidate(readingsProvider);

        final userType = await AuthStorage.getUserType();
        if (mounted) {
          switch (userType?.toLowerCase()) {
            case 'doctor':
              context.go('/doctor/dashboard');
              break;
            case 'admin':
              context.go('/admin/dashboard');
              break;
            case 'patient':
              context.go('/dashboard');
              break;
            default:
              await _service.logout(ref);
              setState(() => _error = 'Access denied for this user type.');
          }
        }
      } else {
        await _service.register(_userCtrl.text.trim(), _passCtrl.text);
        setState(() {
          _isLogin = true;
        });
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Account created! Please sign in.')));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 32),
              Center(
                  child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: green, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.monitor_heart_outlined,
                    color: Colors.white, size: 36),
              )),
              const SizedBox(height: 16),
              Center(
                  child: Text('Bfine',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w600))),
              Center(
                  child: Text('Your health, monitored.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5)))),
              const SizedBox(height: 48),
              Text(_isLogin ? 'Sign in' : 'Create account',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                color: theme.colorScheme.error, fontSize: 13))),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(_isLogin ? 'Sign in' : 'Create account'),
              ),
              const SizedBox(height: 12),
              Center(
                  child: TextButton(
                onPressed: () => setState(() {
                  _isLogin = !_isLogin;
                  _error = null;
                }),
                child: Text(
                  _isLogin
                      ? "Don't have an account? Register"
                      : 'Already have an account? Sign in',
                  style: TextStyle(color: green),
                ),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
