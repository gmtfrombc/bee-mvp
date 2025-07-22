import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/responsive_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/auth_error_mapper.dart';
import 'package:go_router/go_router.dart';
import 'auth_page.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/ui/widgets/bee_text_field.dart';
import '../../../core/validators/auth_validators.dart';

/// Login screen for existing users.
/// Implements validation, loading & error handling.
/// Task T2 – Milestone M1.6.2
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  // BeeTextField handles obscure toggle internally.

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final password = _pwdCtrl.text.trim();

    await ref
        .read(authNotifierProvider.notifier)
        .signInWithEmail(email: email, password: password);
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
        context.go(kLaunchRoute);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: SingleChildScrollView(
        padding: ResponsiveService.getMediumPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        : const Text('Log In'),
              ),
              SizedBox(height: spacing),
              TextButton(
                onPressed: () {
                  debugPrint('👉 Create Account tapped');
                  // Use go() to replace location – more reliable when root '/'
                  // route has no stack children.
                  final router = GoRouter.maybeOf(context);
                  if (router != null) {
                    context.go(kAuthRoute);
                    debugPrint('✅ context.go -> /auth');
                  } else {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(builder: (_) => const AuthPage()),
                        )
                        .then(
                          (_) =>
                              debugPrint('✅ Navigator.push AuthPage finished'),
                        );
                  }
                },
                child: const Text("Don't have an account? Create one"),
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
