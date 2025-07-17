import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/providers/supabase_provider.dart';
import 'package:app/features/action_steps/providers/momentum_listener_provider.dart';

// -----------------------------
// Mocks
// -----------------------------
class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockAuth extends Mock implements GoTrueClient {}

class _MockRealtimeChannel extends Mock implements RealtimeChannel {}

class _MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('momentumListenerProvider', () {
    late _MockSupabaseClient mockClient;
    late _MockRealtimeChannel mockChannel;
    late _MockAuth mockAuth;
    late _MockUser mockUser;

    setUp(() {
      mockClient = _MockSupabaseClient();
      mockChannel = _MockRealtimeChannel();
      mockAuth = _MockAuth();
      mockUser = _MockUser();

      when(() => mockClient.channel(any())).thenReturn(mockChannel);
      when(
        () => mockChannel.onBroadcast(
          event: any(named: 'event'),
          callback: any(named: 'callback'),
        ),
      ).thenReturn(mockChannel);
      when(() => mockChannel.subscribe()).thenReturn(mockChannel);
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user_123');
    });

    test('creates broadcast subscription and cleans up on dispose', () async {
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(mockClient)],
      );

      // Read provider – should set up subscription.
      container.read(momentumListenerProvider);

      verify(() => mockClient.channel('momentum_updates_user_123')).called(1);
      verify(
        () => mockChannel.onBroadcast(
          event: 'momentum_update',
          callback: any(named: 'callback'),
        ),
      ).called(1);
      verify(() => mockChannel.subscribe()).called(1);

      // Dispose container → should unsubscribe.
      container.dispose();

      verify(() => mockChannel.unsubscribe()).called(1);
    });
  });
}
