import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'action_step_form.dart';

/// Entry page for creating a weekly Action Step.
class ActionStepSetupPage extends ConsumerWidget {
  const ActionStepSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Action Step')),
      body: const SafeArea(child: ActionStepForm()),
    );
  }
}
