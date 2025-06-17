import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

/// Model for events coming from `coach_stream` Realtime channel
class CoachStreamEvent {
  final String type; // e.g. typing, momentum_update
  final Map<String, dynamic> data;

  CoachStreamEvent({required this.type, required this.data});
}

/// Riverpod [StreamProvider] that emits [CoachStreamEvent]s from Supabase Realtime
final coachStreamProvider = StreamProvider.autoDispose<CoachStreamEvent>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<CoachStreamEvent>();

  final channel = client.channel('coach_stream');

  channel
      .onBroadcast(
        event: 'typing',
        callback: (payload, [_]) {
          controller.add(CoachStreamEvent(type: 'typing', data: payload));
        },
      )
      .onBroadcast(
        event: 'momentum_update',
        callback: (payload, [_]) {
          controller.add(
            CoachStreamEvent(type: 'momentum_update', data: payload),
          );
        },
      );

  channel.subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});
