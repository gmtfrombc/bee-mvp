import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

/// Utility to display a celebratory overlay when the user completes an
/// Action Step. Falls back to a subtle color flash if the user has enabled
/// the "Reduce Motion" accessibility setting.
class ConfettiOverlay {
  ConfettiOverlay._();

  /// Shows the overlay on the nearest [Overlay] above [context].
  ///
  /// If [reducedMotion] is true, a 250 ms fade flash is displayed instead of
  /// animated confetti.
  static void show(BuildContext context, {required bool reducedMotion}) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => _ConfettiOverlayEntry(
            reducedMotion: reducedMotion,
            onCompleted: () {
              if (entry.mounted) entry.remove();
            },
          ),
    );

    overlay.insert(entry);
  }
}

class _ConfettiOverlayEntry extends StatefulWidget {
  const _ConfettiOverlayEntry({
    required this.reducedMotion,
    required this.onCompleted,
  });

  final bool reducedMotion;
  final VoidCallback onCompleted;

  @override
  State<_ConfettiOverlayEntry> createState() => _ConfettiOverlayEntryState();
}

class _ConfettiOverlayEntryState extends State<_ConfettiOverlayEntry>
    with SingleTickerProviderStateMixin {
  ConfettiController? _controller;

  @override
  void initState() {
    super.initState();

    if (!widget.reducedMotion) {
      _controller = ConfettiController(
        duration: const Duration(milliseconds: 1500),
      )..addListener(() {
        if (_controller!.state == ConfettiControllerState.stopped) {
          widget.onCompleted();
        }
      });
      _controller!.play();
    } else {
      // Remove the overlay after the flash has faded out.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCompleted());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reducedMotion) {
      return Positioned.fill(
        child: IgnorePointer(
          child: AnimatedOpacity(
            // Start fully opaque then fade out quickly.
            opacity: 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.primary.withAlpha((0.3 * 255).round()),
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: ConfettiWidget(
          confettiController: _controller!,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          emissionFrequency: 0.05,
          numberOfParticles: 25,
          gravity: 0.3,
          colors: const [Colors.green, Colors.blue, Colors.orange, Colors.pink],
        ),
      ),
    );
  }
}
