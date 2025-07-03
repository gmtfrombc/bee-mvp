import 'package:flutter/material.dart';

/// Simple placeholder page allowing the user to set a new password using a
/// Supabase recovery `access_token`. Real validation & UX improvements will be
/// added in subsequent tasks.
class PasswordResetPage extends StatefulWidget {
  final String accessToken;
  const PasswordResetPage({super.key, required this.accessToken});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    // TODO: Integrate real password update call in later task.
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop();

    setState(() => _isSubmitting = false);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
                validator:
                    (v) =>
                        v == null || v.length < 8 ? 'Enter min 8 chars' : null,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child:
                      _isSubmitting
                          ? const CircularProgressIndicator()
                          : const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
