import 'package:flutter/material.dart';
import 'package:app/core/services/responsive_service.dart';

/// Metabolic Health Score (MHS) Gauge
///
/// Size & Placement Guidelines
/// ------------------------------------------------------------
/// • Default diameter: `ResponsiveService.getMomentumGaugeSize(context)` which
///   targets ~38 % of the screen width on a typical phone.
/// • Minimum diameter: 120 px (small handsets).
/// • Maximum diameter: 280 px (large tablets & desktop).
/// • Maintain at least 16 px horizontal padding from safe-area edges.
/// • Center horizontally inside its parent; leave vertical space above equal
///   to 0.25 × gauge diameter for headers.
///
/// Override [size] to customise the diameter. This stub returns a
/// [Placeholder] — the custom painter implementation will land during the main
/// milestone work. Having this stub unblocks layout and documentation tasks.
class MhsGauge extends StatelessWidget {
  const MhsGauge({super.key, this.size});

  /// Diameter of the gauge in logical pixels.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final gaugeSize = size ?? ResponsiveService.getMomentumGaugeSize(context);
    return SizedBox(
      width: gaugeSize,
      height: gaugeSize,
      child: const Placeholder(),
    );
  }
}
