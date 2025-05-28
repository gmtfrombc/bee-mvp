import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing modal visibility states
final modalVisibilityProvider = StateProvider<bool>((ref) => false);

/// Provider for managing refresh state
final isRefreshingProvider = StateProvider<bool>((ref) => false);

/// Provider for managing user interaction states
final userInteractionProvider = StateProvider<UserInteractionState>((ref) {
  return const UserInteractionState();
});

/// Provider for managing animation states
final animationStateProvider = StateProvider<AnimationState>((ref) {
  return const AnimationState();
});

/// Provider for managing navigation state
final navigationStateProvider = StateProvider<String?>((ref) => null);

/// User interaction state model
class UserInteractionState {
  final bool isCardPressed;
  final bool isButtonPressed;
  final String? lastTappedButton;
  final DateTime? lastInteractionTime;

  const UserInteractionState({
    this.isCardPressed = false,
    this.isButtonPressed = false,
    this.lastTappedButton,
    this.lastInteractionTime,
  });

  UserInteractionState copyWith({
    bool? isCardPressed,
    bool? isButtonPressed,
    String? lastTappedButton,
    DateTime? lastInteractionTime,
  }) {
    return UserInteractionState(
      isCardPressed: isCardPressed ?? this.isCardPressed,
      isButtonPressed: isButtonPressed ?? this.isButtonPressed,
      lastTappedButton: lastTappedButton ?? this.lastTappedButton,
      lastInteractionTime: lastInteractionTime ?? this.lastInteractionTime,
    );
  }
}

/// Animation state model
class AnimationState {
  final bool isAnimating;
  final String? currentAnimation;
  final double animationProgress;

  const AnimationState({
    this.isAnimating = false,
    this.currentAnimation,
    this.animationProgress = 0.0,
  });

  AnimationState copyWith({
    bool? isAnimating,
    String? currentAnimation,
    double? animationProgress,
  }) {
    return AnimationState(
      isAnimating: isAnimating ?? this.isAnimating,
      currentAnimation: currentAnimation ?? this.currentAnimation,
      animationProgress: animationProgress ?? this.animationProgress,
    );
  }
}

/// Provider for managing card interaction states
final cardInteractionProvider =
    StateNotifierProvider<CardInteractionNotifier, CardInteractionState>((ref) {
      return CardInteractionNotifier();
    });

/// Card interaction state
class CardInteractionState {
  final bool isPressed;
  final bool isHovered;
  final double scale;
  final double opacity;

  const CardInteractionState({
    this.isPressed = false,
    this.isHovered = false,
    this.scale = 1.0,
    this.opacity = 1.0,
  });

  CardInteractionState copyWith({
    bool? isPressed,
    bool? isHovered,
    double? scale,
    double? opacity,
  }) {
    return CardInteractionState(
      isPressed: isPressed ?? this.isPressed,
      isHovered: isHovered ?? this.isHovered,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// Card interaction notifier
class CardInteractionNotifier extends StateNotifier<CardInteractionState> {
  CardInteractionNotifier() : super(const CardInteractionState());

  void onPressStart() {
    state = state.copyWith(isPressed: true, scale: 0.95);
  }

  void onPressEnd() {
    state = state.copyWith(isPressed: false, scale: 1.0);
  }

  void onHoverStart() {
    state = state.copyWith(isHovered: true, scale: 1.02);
  }

  void onHoverEnd() {
    state = state.copyWith(isHovered: false, scale: 1.0);
  }

  void reset() {
    state = const CardInteractionState();
  }
}
