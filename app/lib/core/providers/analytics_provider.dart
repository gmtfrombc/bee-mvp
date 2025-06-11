import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/analytics_service.dart';
import 'supabase_provider.dart';

/// Riverpod provider for analytics service.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  return AnalyticsService(client);
});
