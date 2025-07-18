import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the currently selected perceived energy score (1–5).
/// `null` indicates no selection yet.
final energyScoreProvider = StateProvider<int?>((ref) => null);
