import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/features/action_steps/state/action_step_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockAuth extends Mock implements GoTrueClient {}

class _FakeTable {
  Future<void> insert(dynamic values) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ActionStepController.submit completes under 2 s', () async {
    final client = _MockSupabaseClient();
    final auth = _MockAuth();
    final user = User(
      id: 'uid',
      appMetadata: {},
      userMetadata: {},
      aud: '',
      createdAt: DateTime.now().toIso8601String(),
    );

    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(user);

    final table = _FakeTable();
    when<dynamic>(() => client.from('action_steps')).thenReturn(table);

    final controller = ActionStepController(client);
    controller.updateCategory('exercise');
    controller.updateDescription('Walk 5000 steps');
    controller.updateFrequency(5);

    final sw = Stopwatch()..start();
    await controller.submit();
    sw.stop();

    expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
