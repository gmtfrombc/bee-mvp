import 'package:flutter/material.dart';
import 'message_bubble.dart';

/// Animated wrapper around [MessageBubble] that adds a subtle slide + fade-in
/// on first build to provide a more delightful chat experience.
///
/// If [MessageBubble] determines the message is celebratory, an additional
/// emoji burst animation (🎉) is rendered briefly above the bubble.
class AnimatedMessageBubble extends StatefulWidget {
  final bool isUser;
  final String text;
  final DateTime? timestamp;

  const AnimatedMessageBubble({
    super.key,
    required this.isUser,
    required this.text,
    this.timestamp,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  // Optional celebratory burst controller (only initialised when required)
  AnimationController? _burstController;

  bool get _isCelebratory =>
      !widget.isUser && widget.text.startsWith('<tone celebratory>');

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    // Slide from the side the bubble belongs to
    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isUser ? 0.15 : -0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    if (_isCelebratory) {
      _burstController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    }

    // Kick off animations in next frame so layout has a size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
      _burstController?.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _burstController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            MessageBubble(
              isUser: widget.isUser,
              text: widget.text,
              timestamp: widget.timestamp,
            ),
            if (_isCelebratory && _burstController != null)
              Positioned(
                top: -12,
                left: widget.isUser ? null : 4,
                right: widget.isUser ? 4 : null,
                child: FadeTransition(
                  opacity: _burstController!,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.6, end: 1.2).animate(
                      CurvedAnimation(
                        parent: _burstController!,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: const Text('🎉', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
