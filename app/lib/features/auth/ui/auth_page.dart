import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/auth_error_mapper.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/ui/widgets/bee_text_field.dart';
import '../../../core/validators/auth_validators.dart';
import '../../../core/ui/bee_toast.dart';

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

  // BeeTextField handles its own visibility toggle when `obscureText` is true, so no local state is required.

  @override
  void initState() {
    super.initState();
    debugPrint('🆕 AuthPage mounted');
  }

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

    final response = await ref
        .read(authNotifierProvider.notifier)
        .signUpWithEmail(name: name, email: email, password: password);

    debugPrint(
      '[AuthPage] signUp response: session=${response.session} user=${response.user?.id} identities=${response.user?.identities}',
    );

    // === New: Duplicate email guard ===
    final identities = response.user?.identities as List<dynamic>?;
    if (response.session == null &&
        (identities == null || identities.isEmpty)) {
      // No session and no user → Supabase may have silently skipped account creation because
      // the e-mail is already registered. Show user-friendly error and abort navigation.
      if (!mounted) return;
      showBeeToast(context, 'Account already exists', type: BeeToastType.error);
      return;
    }

    if (!mounted) return;

    // Decide navigation based on whether Supabase returned a session.
    if (response.session == null) {
      context.go(kConfirmRoute, extra: email);
    } else {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        router.go(kLaunchRoute);
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔧 AuthPage built');
    final authAsync = ref.watch(authNotifierProvider);
    final spacing = ResponsiveService.getMediumSpacing(context);

    ref.listen(authNotifierProvider, (prev, next) {
      if (next.hasError) {
        final msg = mapAuthError(next.error!);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
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
              BeeTextField(
                controller: _nameCtrl,
                label: 'Name',
                textInputAction: TextInputAction.next,
                validator:
                    (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              SizedBox(height: spacing),
              BeeTextField(
                controller: _emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: emailValidator,
              ),
              SizedBox(height: spacing),
              BeeTextField(
                controller: _pwdCtrl,
                label: 'Password',
                obscureText: true,
                validator: passwordValidator,
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
                  // If inside GoRouter, simply pop back to the previous route
                  // (LoginPage at '/'). Fallback to Navigator.pop when router
                  // is absent (e.g., unit tests using MaterialApp).
                  if (Navigator.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
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

// Removed private _BeeTextField – replaced by shared BeeTextField.
