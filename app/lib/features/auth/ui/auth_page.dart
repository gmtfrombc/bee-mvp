import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/auth_error_mapper.dart';
import 'package:app/core/widgets/launch_controller.dart';
import 'login_page.dart';
import 'confirmation_pending_page.dart';

/// Registration screen that captures Name, Email, and Password.
///
/// Task T1 – Milestone M1.6.2
/// • Uses Riverpod for state management
/// • All paddings/spacing come from ResponsiveService
/// • No magic numbers – adheres to theming guidelines
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  bool _obscurePwd = true;
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _pwdCtrl.text.trim();

    // Flag that sign-up was initiated so listener can act on null session.
    _submitted = true;

    await ref
        .read(authNotifierProvider.notifier)
        .signUpWithEmail(name: name, email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final spacing = ResponsiveService.getMediumSpacing(context);

    ref.listen(authNotifierProvider, (prev, next) {
      if (next.hasError) {
        final msg = mapAuthError(next.error!);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } else if (next.hasValue && next.value != null) {
        // Navigate to Home (AppWrapper) once user is authenticated
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LaunchController()),
          (route) => false,
        );
      } else if (next.hasValue && next.value == null && _submitted) {
        // No session yet → show confirmation pending
        final email = _emailCtrl.text.trim();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ConfirmationPendingPage(email: email),
          ),
          (route) => false,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SingleChildScrollView(
        padding: ResponsiveService.getMediumPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BeeTextField(
                controller: _nameCtrl,
                label: 'Name',
                textInputAction: TextInputAction.next,
                validator:
                    (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              SizedBox(height: spacing),
              _BeeTextField(
                controller: _emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final email = v?.trim() ?? '';
                  if (email.isEmpty) return 'Required';
                  final reg = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+");
                  if (!reg.hasMatch(email)) return 'Invalid email';
                  return null;
                },
              ),
              SizedBox(height: spacing),
              _BeeTextField(
                controller: _pwdCtrl,
                label: 'Password',
                obscureText: _obscurePwd,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePwd ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                ),
                validator: (v) {
                  final pwd = v ?? '';
                  if (pwd.isEmpty) return 'Required';
                  if (pwd.length < 8) return 'Min 8 characters';
                  return null;
                },
              ),
              SizedBox(height: spacing * 2),
              ElevatedButton(
                onPressed: authAsync.isLoading ? null : _submit,
                child:
                    authAsync.isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Create Account'),
              ),
              SizedBox(height: spacing),
              TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
                },
                child: const Text('Already have an account? Log in'),
              ),
              if (authAsync.hasError) ...[
                SizedBox(height: spacing),
                Text(
                  mapAuthError(authAsync.error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin wrapper around TextFormField with theme-compliant decoration.
class _BeeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _BeeTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
    );
  }
}
