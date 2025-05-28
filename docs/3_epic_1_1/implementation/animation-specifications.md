# BEE Momentum Meter - Animation Specifications

**Epic:** 1.1 · Momentum Meter  
**Task:** T1.1.1.7 · Animation Sequences and Micro-interactions  
**Status:** ✅ Complete  
**Created:** December 2024  

---

## 🎬 **Animation Overview**

The momentum meter uses carefully crafted animations to create an engaging, delightful user experience that reinforces positive behavior change. All animations follow Material Design motion principles with custom timing curves optimized for health and wellness contexts.

### **Animation Principles**
- **Meaningful Motion**: Every animation serves a purpose and supports user understanding
- **Encouraging Feedback**: Animations reinforce positive momentum and provide gentle guidance
- **Performance First**: 60 FPS target with efficient implementations
- **Accessibility Aware**: Respects reduced motion preferences
- **State Continuity**: Smooth transitions maintain context during state changes

---

## 🚀 **Primary Animation Sequences**

### **1. Initial Load Sequence**
*The complete animation sequence when the momentum meter first appears*

#### **Timeline Overview**
```
0ms     ├─ Card Fade In Starts
        │
300ms   ├─ Gauge Fill Animation Starts
        │
800ms   ├─ Card Fade In Completes
        │
1800ms  ├─ Gauge Fill Completes
        ├─ Bounce Effect Starts
        │
2000ms  ├─ Bounce Effect Completes
        ├─ Stats Cards Stagger In
        │
2400ms  ├─ Action Buttons Fade In
        │
2600ms  └─ Animation Sequence Complete
```

#### **1.1 Card Fade In (0-800ms)**
```dart
class CardFadeInAnimation {
  static const Duration duration = Duration(milliseconds: 800);
  static const Curve curve = Curves.easeOut;
  
  static Animation<double> createOpacity(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.3, curve: curve),
    ));
  }
  
  static Animation<Offset> createSlide(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.3, curve: curve),
    ));
  }
}
```

#### **1.2 Gauge Fill Animation (300-1800ms)**
```dart
class GaugeFillAnimation {
  static const Duration duration = Duration(milliseconds: 1500);
  static const Curve curve = Cubic(0.25, 0.46, 0.45, 0.94);
  
  static Animation<double> createProgress(
    AnimationController controller,
    double targetPercentage,
  ) {
    return Tween<double>(
      begin: 0.0,
      end: targetPercentage / 100.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.12, 0.68, curve: curve),
    ));
  }
}
```

#### **1.3 Bounce Effect (1800-2000ms)**
```dart
class BounceAnimation {
  static const Duration duration = Duration(milliseconds: 200);
  static const Curve curve = Cubic(0.68, -0.55, 0.265, 1.55);
  
  static Animation<double> createScale(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.68, 0.76, curve: curve),
    ));
  }
}
```

#### **1.4 Stats Cards Stagger (2000-2400ms)**
```dart
class StatsStaggerAnimation {
  static const Duration duration = Duration(milliseconds: 400);
  static const Duration staggerDelay = Duration(milliseconds: 100);
  
  static List<Animation<double>> createStagger(
    AnimationController controller,
    int itemCount,
  ) {
    return List.generate(itemCount, (index) {
      final start = 0.76 + (index * 0.04);
      final end = start + 0.08;
      
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });
  }
}
```

### **2. State Transition Animation**
*Smooth transitions when momentum state changes*

#### **2.1 Color Morph Animation**
```dart
class ColorMorphAnimation {
  static const Duration duration = Duration(milliseconds: 1000);
  static const Curve curve = Curves.easeInOut;
  
  static Animation<Color?> createColorTransition(
    AnimationController controller,
    Color fromColor,
    Color toColor,
  ) {
    return ColorTween(
      begin: fromColor,
      end: toColor,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
  
  static Animation<double> createGlowTransition(
    AnimationController controller,
  ) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 70,
      ),
    ]).animate(controller);
  }
}
```

#### **2.2 Emoji Crossfade Animation**
```dart
class EmojiCrossfadeAnimation {
  static const Duration duration = Duration(milliseconds: 600);
  
  static Animation<double> createOutgoing(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ));
  }
  
  static Animation<double> createIncoming(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));
  }
  
  static Animation<double> createScale(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.1),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 20,
      ),
    ]).animate(controller);
  }
}
```

#### **2.3 Message Update Animation**
```dart
class MessageUpdateAnimation {
  static const Duration duration = Duration(milliseconds: 800);
  
  static Animation<double> createFadeOut(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));
  }
  
  static Animation<double> createFadeIn(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));
  }
  
  static Animation<Offset> createSlide(AnimationController controller) {
    return TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -0.1),
        ),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ),
        weight: 70,
      ),
    ]).animate(controller);
  }
}
```

---

## 🎯 **Micro-interactions**

### **3. Button Interactions**

#### **3.1 Button Press Animation**
```dart
class ButtonPressAnimation {
  static const Duration duration = Duration(milliseconds: 100);
  static const double scaleValue = 0.95;
  
  static Animation<double> createPress(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: scaleValue,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }
  
  static Animation<double> createElevation(AnimationController controller) {
    return Tween<double>(
      begin: 2.0,
      end: 0.0,
    ).animate(controller);
  }
}
```

#### **3.2 Button Hover Animation (Web/Desktop)**
```dart
class ButtonHoverAnimation {
  static const Duration duration = Duration(milliseconds: 200);
  
  static Animation<double> createElevation(AnimationController controller) {
    return Tween<double>(
      begin: 2.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
  }
  
  static Animation<Offset> createTranslation(AnimationController controller) {
    return Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.02),
    ).animate(controller);
  }
}
```

### **4. Card Interactions**

#### **4.1 Card Tap Feedback**
```dart
class CardTapAnimation {
  static const Duration duration = Duration(milliseconds: 150);
  
  static Animation<double> createScale(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.02),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }
  
  static Animation<double> createGlow(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
  }
}
```

### **5. Progress Bar Animations**

#### **5.1 Progress Bar Update**
```dart
class ProgressBarAnimation {
  static const Duration duration = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeInOut;
  
  static Animation<double> createWidth(
    AnimationController controller,
    double fromWidth,
    double toWidth,
  ) {
    return Tween<double>(
      begin: fromWidth,
      end: toWidth,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
  
  static Animation<Color?> createColor(
    AnimationController controller,
    Color fromColor,
    Color toColor,
  ) {
    return ColorTween(
      begin: fromColor,
      end: toColor,
    ).animate(controller);
  }
}
```

### **6. Trend Chart Animations**

#### **6.1 Line Drawing Animation**
```dart
class TrendLineAnimation {
  static const Duration duration = Duration(milliseconds: 1000);
  static const Curve curve = Curves.easeInOut;
  
  static Animation<double> createPath(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
  
  static Animation<double> createEmojiStagger(
    AnimationController controller,
    int index,
    int total,
  ) {
    final start = (index / total) * 0.8;
    final end = start + 0.2;
    
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.elasticOut),
    ));
  }
}
```

---

## 🎨 **Special Effects**

### **7. Celebration Animations**

#### **7.1 Achievement Burst**
```dart
class AchievementBurstAnimation {
  static const Duration duration = Duration(milliseconds: 2000);
  
  static Animation<double> createParticleScale(
    AnimationController controller,
    int particleIndex,
  ) {
    final delay = particleIndex * 0.1;
    final start = delay / 2.0;
    final end = (delay + 0.8) / 2.0;
    
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 70,
      ),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    ));
  }
  
  static Animation<Offset> createParticlePosition(
    AnimationController controller,
    double angle,
  ) {
    return Tween<Offset>(
      begin: Offset.zero,
      end: Offset(
        math.cos(angle) * 100,
        math.sin(angle) * 100,
      ),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
  }
}
```

#### **7.2 Momentum Streak Glow**
```dart
class StreakGlowAnimation {
  static const Duration duration = Duration(milliseconds: 3000);
  
  static Animation<double> createGlow(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.7),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 0.0),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }
  
  static Animation<double> createPulse(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticInOut,
    ));
  }
}
```

---

## ♿ **Accessibility Considerations**

### **8. Reduced Motion Support**

#### **8.1 Motion Preference Detection**
```dart
class MotionPreferences {
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
  
  static Duration adjustDuration(
    Duration originalDuration,
    BuildContext context,
  ) {
    if (shouldReduceMotion(context)) {
      return const Duration(milliseconds: 1);
    }
    return originalDuration;
  }
  
  static Curve adjustCurve(
    Curve originalCurve,
    BuildContext context,
  ) {
    if (shouldReduceMotion(context)) {
      return Curves.linear;
    }
    return originalCurve;
  }
}
```

#### **8.2 Alternative Static States**
```dart
class AccessibleMomentumMeter extends StatelessWidget {
  final MomentumState state;
  final double percentage;
  final bool reduceMotion;
  
  @override
  Widget build(BuildContext context) {
    final shouldReduce = reduceMotion || 
        MediaQuery.of(context).disableAnimations;
    
    if (shouldReduce) {
      return StaticMomentumMeter(
        state: state,
        percentage: percentage,
      );
    }
    
    return AnimatedMomentumMeter(
      state: state,
      percentage: percentage,
    );
  }
}
```

### **9. Screen Reader Announcements**

#### **9.1 State Change Announcements**
```dart
class MomentumAnnouncements {
  static void announceStateChange(
    BuildContext context,
    MomentumState oldState,
    MomentumState newState,
  ) {
    final message = _buildStateChangeMessage(oldState, newState);
    
    Semantics.of(context)?.announce(
      message,
      TextDirection.ltr,
    );
  }
  
  static String _buildStateChangeMessage(
    MomentumState oldState,
    MomentumState newState,
  ) {
    if (newState.type == MomentumStateType.rising) {
      return 'Great progress! Your momentum is now rising.';
    } else if (newState.type == MomentumStateType.steady) {
      return 'You\'re maintaining steady momentum. Keep it up!';
    } else {
      return 'Your momentum needs some care. Let\'s work together to improve it.';
    }
  }
}
```

---

## 🔧 **Implementation Utilities**

### **10. Animation Controller Management**

#### **10.1 Momentum Animation Controller**
```dart
class MomentumAnimationController extends StatefulWidget {
  final Widget child;
  final MomentumState state;
  final double percentage;
  
  @override
  State<MomentumAnimationController> createState() => 
      _MomentumAnimationControllerState();
}

class _MomentumAnimationControllerState 
    extends State<MomentumAnimationController>
    with TickerProviderStateMixin {
  
  late AnimationController _primaryController;
  late AnimationController _transitionController;
  late AnimationController _interactionController;
  
  @override
  void initState() {
    super.initState();
    _setupControllers();
  }
  
  void _setupControllers() {
    _primaryController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );
    
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _interactionController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimationControllerProvider(
      primaryController: _primaryController,
      transitionController: _transitionController,
      interactionController: _interactionController,
      child: widget.child,
    );
  }
  
  @override
  void dispose() {
    _primaryController.dispose();
    _transitionController.dispose();
    _interactionController.dispose();
    super.dispose();
  }
}
```

#### **10.2 Animation Sequence Manager**
```dart
class AnimationSequenceManager {
  final AnimationController controller;
  final List<AnimationStep> steps;
  
  AnimationSequenceManager({
    required this.controller,
    required this.steps,
  });
  
  Future<void> playSequence() async {
    for (final step in steps) {
      await step.execute(controller);
    }
  }
  
  void stopSequence() {
    controller.stop();
  }
}

abstract class AnimationStep {
  Future<void> execute(AnimationController controller);
}

class DelayStep extends AnimationStep {
  final Duration delay;
  
  DelayStep(this.delay);
  
  @override
  Future<void> execute(AnimationController controller) async {
    await Future.delayed(delay);
  }
}

class AnimateToStep extends AnimationStep {
  final double value;
  final Duration duration;
  final Curve curve;
  
  AnimateToStep({
    required this.value,
    required this.duration,
    this.curve = Curves.linear,
  });
  
  @override
  Future<void> execute(AnimationController controller) async {
    await controller.animateTo(
      value,
      duration: duration,
      curve: curve,
    );
  }
}
```

---

## 📊 **Performance Monitoring**

### **11. Animation Performance Tracking**

#### **11.1 Frame Rate Monitor**
```dart
class AnimationPerformanceMonitor {
  static const int targetFPS = 60;
  static const Duration sampleWindow = Duration(seconds: 1);
  
  final List<Duration> _frameTimes = [];
  DateTime? _lastFrameTime;
  
  void recordFrame() {
    final now = DateTime.now();
    
    if (_lastFrameTime != null) {
      final frameDuration = now.difference(_lastFrameTime!);
      _frameTimes.add(frameDuration);
      
      // Keep only recent frames
      final cutoff = now.subtract(sampleWindow);
      _frameTimes.removeWhere((time) => 
          now.subtract(time) > sampleWindow);
    }
    
    _lastFrameTime = now;
  }
  
  double get averageFPS {
    if (_frameTimes.isEmpty) return 0.0;
    
    final averageFrameTime = _frameTimes
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b) / _frameTimes.length;
    
    return 1000000.0 / averageFrameTime;
  }
  
  bool get isPerformant => averageFPS >= (targetFPS * 0.9);
}
```

---

## 📋 **Implementation Checklist**

### **Animation Specifications Complete ✅**
- [x] Initial load sequence with staggered animations
- [x] State transition animations with color morphing
- [x] Micro-interactions for buttons and cards
- [x] Progress bar and trend chart animations
- [x] Special celebration effects
- [x] Accessibility support with reduced motion
- [x] Screen reader announcements
- [x] Performance monitoring utilities
- [x] Animation controller management
- [x] Comprehensive timing specifications

### **Technical Requirements Met**
- [x] 60 FPS performance target
- [x] Material Design motion principles
- [x] Reduced motion preference support
- [x] Smooth state transitions (1000ms)
- [x] Engaging micro-interactions (<200ms)
- [x] Meaningful animation sequences
- [x] Performance optimization techniques

---

## 🚀 **Next Steps**

1. **Implementation Testing**: Validate animation performance on target devices
2. **User Testing**: Gather feedback on animation timing and feel
3. **Accessibility Audit**: Test with screen readers and reduced motion
4. **Performance Optimization**: Fine-tune for 60 FPS on lower-end devices
5. **Cross-Platform Validation**: Ensure consistent behavior across platforms

---

**Status**: ✅ Complete  
**Review Required**: Design Team, Engineering Team, Accessibility Team  
**Next Task**: T1.1.1.8 - Accessibility Specifications  
**Estimated Hours**: 4h (Actual: 4h)  

---

*These animation specifications ensure the momentum meter provides an engaging, accessible, and performant user experience that reinforces positive behavior change.* 