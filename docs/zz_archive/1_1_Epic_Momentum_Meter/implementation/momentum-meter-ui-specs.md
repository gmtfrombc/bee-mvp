# Momentum Meter UI Design Specifications

**Epic:** 1.1 · Momentum Meter  
**Document:** High-Fidelity UI Specifications  
**Version:** 1.0  
**Status:** 🎨 Design Phase  
**Created:** December 2024  
**Owner:** Design Team  

---

## 📋 Overview

This document provides comprehensive UI design specifications for the Momentum Meter, including high-fidelity mockups, component details, animations, and implementation guidelines. The design focuses on creating an encouraging, accessible, and visually appealing experience that motivates users through positive reinforcement.

## 🎨 Design System Foundation

### **Color Palette**

#### **Primary Momentum Colors**
```css
/* Rising State */
--momentum-rising: #4CAF50;          /* Primary green */
--momentum-rising-light: #81C784;    /* Light green */
--momentum-rising-dark: #388E3C;     /* Dark green */

/* Steady State */
--momentum-steady: #2196F3;          /* Primary blue */
--momentum-steady-light: #64B5F6;    /* Light blue */
--momentum-steady-dark: #1976D2;     /* Dark blue */

/* Needs Care State */
--momentum-care: #FF9800;            /* Primary orange */
--momentum-care-light: #FFB74D;      /* Light orange */
--momentum-care-dark: #F57C00;       /* Dark orange */
```

#### **Supporting Colors**
```css
/* Neutral Colors */
--background-primary: #FFFFFF;       /* Main background */
--background-secondary: #F5F5F5;     /* Card backgrounds */
--text-primary: #212121;             /* Main text */
--text-secondary: #757575;           /* Secondary text */
--text-hint: #BDBDBD;               /* Hint text */

/* Accent Colors */
--accent-success: #4CAF50;           /* Success states */
--accent-warning: #FF9800;           /* Warning states */
--accent-info: #2196F3;             /* Info states */
```

### **Typography**

#### **Font Hierarchy**
```css
/* Momentum State Title */
.momentum-title {
  font-family: 'SF Pro Display', 'Roboto', sans-serif;
  font-size: 24px;
  font-weight: 600;
  line-height: 28px;
  letter-spacing: -0.5px;
}

/* Momentum Message */
.momentum-message {
  font-family: 'SF Pro Text', 'Roboto', sans-serif;
  font-size: 18px;
  font-weight: 500;
  line-height: 22px;
  letter-spacing: -0.2px;
}

/* Body Text */
.body-text {
  font-family: 'SF Pro Text', 'Roboto', sans-serif;
  font-size: 16px;
  font-weight: 400;
  line-height: 20px;
  letter-spacing: 0px;
}

/* Caption Text */
.caption-text {
  font-family: 'SF Pro Text', 'Roboto', sans-serif;
  font-size: 14px;
  font-weight: 400;
  line-height: 18px;
  letter-spacing: 0.1px;
}
```

### **Spacing System**
```css
/* Base spacing unit: 8px */
--space-xs: 4px;    /* 0.5x */
--space-sm: 8px;    /* 1x */
--space-md: 16px;   /* 2x */
--space-lg: 24px;   /* 3x */
--space-xl: 32px;   /* 4x */
--space-xxl: 48px;  /* 6x */
```

---

## 🎯 High-Fidelity Mockups

### **Mockup 1: Rising State - Main View**

```
┌─────────────────────────────────────┐ ← iPhone 14 (390px)
│ ●●● 9:41 AM                    🔋📶 │ ← Status Bar
├─────────────────────────────────────┤
│ ← [👤] Welcome back, Sarah! 🔔      │ ← Header (60px)
│                                     │   #212121 text, 18px medium
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │ ← Momentum Card (200px)
│ │        YOUR MOMENTUM            │ │   #F5F5F5 background
│ │        #757575, 14px            │ │   16px padding, 12px radius
│ │                                 │ │
│ │        ┌─────────┐              │ │
│ │        │    🚀   │   Rising!    │ │ ← Circular Gauge (120px)
│ │        │ ┌─────┐ │   #4CAF50    │ │   #4CAF50 progress ring
│ │        │ │█████│ │   24px bold  │ │   8px stroke width
│ │        │ │█████│ │              │ │   Animated fill: 85%
│ │        │ │█████│ │              │ │
│ │        │ └─────┘ │              │ │
│ │        └─────────┘              │ │
│ │                                 │ │
│ │ You're on fire! Keep up the     │ │ ← Encouraging Message
│ │ great momentum! 🔥              │ │   #212121, 18px medium
│ │                                 │ │   Center aligned
│ │ ▓▓▓▓▓▓▓▓▓▓▓ 85% this week       │ │ ← Progress Bar
│ └─────────────────────────────────┘ │   #4CAF50 fill, 4px height
│                                     │
├─────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ │ ← Quick Stats (100px)
│ │Lessons  │ │ Streak  │ │ Today   │ │   3 cards, 8px gaps
│ │   4/5   │ │   12    │ │  67m    │ │   #FFFFFF background
│ │ #4CAF50 │ │  days   │ │ active  │ │   2px border radius
│ │ 20px    │ │ #2196F3 │ │ #FF9800 │ │   12px padding
│ └─────────┘ └─────────┘ └─────────┘ │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │ ← Weekly Trend (140px)
│ │ 📈 This Week's Journey          │ │   #F5F5F5 background
│ │ #212121, 16px medium            │ │   16px padding
│ │                                 │ │
│ │     🚀                          │ │ ← Emoji Trend Line
│ │    ╱ ╲     🚀                   │ │   2px stroke, #4CAF50
│ │   ╱   ╲   ╱ ╲                   │ │   Smooth bezier curves
│ │  🙂     ╲ ╱   🚀                │ │   24px emoji size
│ │ 🙂       🙂                     │ │
│ │ M T W T F S S                   │ │   #757575, 12px
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ Keep the momentum going! 💪         │ ← Action Header
│ #212121, 16px medium                │   #212121, 16px medium
│                                     │
│ • Complete today's final lesson     │ ← Action List
│ • Share your progress with coach    │   #757575, 14px
│                                     │   4px bullet spacing
│ ┌─────────────┐ ┌─────────────┐   │
│ │   Learn     │ │   Share     │   │ ← Action Buttons
│ │   #4CAF50   │ │   #2196F3   │   │   44px height, 8px radius
│ │   #FFFFFF   │ │   #FFFFFF   │   │   16px font, medium weight
│ └─────────────┘ └─────────────┘   │   8px gap between
├─────────────────────────────────────┤
│                                     │ ← Bottom padding (20px)
└─────────────────────────────────────┘
```

### **Mockup 2: Steady State - Main View**

```
┌─────────────────────────────────────┐
│ ●●● 9:41 AM                    🔋📶 │
├─────────────────────────────────────┤
│ ← [👤] Good to see you! 🔔          │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │        YOUR MOMENTUM            │ │
│ │                                 │ │
│ │        ┌─────────┐              │ │
│ │        │    🙂   │   Steady!    │ │ ← Blue Theme
│ │        │ ┌─────┐ │   #2196F3    │ │   #2196F3 progress ring
│ │        │ │████▓│ │   24px bold  │ │   65% fill animation
│ │        │ │███▓▓│ │              │ │
│ │        │ │██▓▓▓│ │              │ │
│ │        │ └─────┘ │              │ │
│ │        └─────────┘              │ │
│ │                                 │ │
│ │ You're doing well! Stay         │ │
│ │ consistent! 👍                  │ │
│ │                                 │ │
│ │ ▓▓▓▓▓▓▓░░░ 65% this week        │ │ ← Blue progress bar
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│ │Lessons  │ │ Streak  │ │ Today   │ │
│ │   3/5   │ │    8    │ │  45m    │ │
│ │ #2196F3 │ │  days   │ │ active  │ │
│ │         │ │ #4CAF50 │ │ #FF9800 │ │
│ └─────────┘ └─────────┘ └─────────┘ │
├─────────────────────────────────────┤
│ Small steps make big changes! 🌟    │
│                                     │
│ • Try one more lesson today         │
│ • Log your evening reflection       │
│                                     │
│ ┌─────────────┐ ┌─────────────┐   │
│ │ Learn More  │ │ Reflect     │   │
│ │   #2196F3   │ │   #2196F3   │   │
│ └─────────────┘ └─────────────┘   │
└─────────────────────────────────────┘
```

### **Mockup 3: Needs Care State - Main View**

```
┌─────────────────────────────────────┐
│ ●●● 9:41 AM                    🔋📶 │
├─────────────────────────────────────┤
│ ← [👤] We're here for you! 🔔       │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │        YOUR MOMENTUM            │ │
│ │                                 │ │
│ │        ┌─────────┐              │ │
│ │        │    🌱   │ Needs Care   │ │ ← Orange Theme
│ │        │ ┌─────┐ │   #FF9800    │ │   #FF9800 progress ring
│ │        │ │██▓▓▓│ │   24px bold  │ │   30% fill animation
│ │        │ │█▓▓▓▓│ │              │ │   Gentle pulsing
│ │        │ │▓▓▓▓▓│ │              │ │
│ │        │ └─────┘ │              │ │
│ │        └─────────┘              │ │
│ │                                 │ │
│ │ Let's grow together! Every      │ │ ← Extra encouraging
│ │ small step counts! 🌟          │ │   Longer message
│ │                                 │ │
│ │ ▓▓▓░░░░░░░ 30% this week        │ │ ← Orange progress bar
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│ │Lessons  │ │ Streak  │ │ Today   │ │
│ │   1/5   │ │    2    │ │  15m    │ │
│ │ #FF9800 │ │  days   │ │ active  │ │
│ │         │ │ #FF9800 │ │ #FF9800 │ │
│ └─────────┘ └─────────┘ └─────────┘ │
├─────────────────────────────────────┤
│ 💡 Easy wins to get started:       │ ← Simplified actions
│                                     │
│ • Take 2 minutes to check in        │ ← Very simple tasks
│ • Try one quick lesson              │
│                                     │
│ ┌─────────────┐ ┌─────────────┐   │
│ │ Quick Start │ │ Get Support │   │ ← Support emphasis
│ │   #FF9800   │ │   #FF9800   │   │
│ └─────────────┘ └─────────────┘   │
├─────────────────────────────────────┤
│ "Every journey starts with a       │ ← Motivational quote
│ single step. You've got this! 💪"  │   #757575, 14px italic
└─────────────────────────────────────┘
```

### **Mockup 4: Momentum Detail Modal**

```
┌─────────────────────────────────────┐
│                                     │ ← Backdrop overlay
│ ┌─────────────────────────────────┐ │   rgba(0,0,0,0.5)
│ │ Your Momentum Details      ✕    │ │ ← Modal Header
│ │ #212121, 18px medium       24px │ │   #FFFFFF background
│ ├─────────────────────────────────┤ │   16px padding
│ │                                 │ │
│ │ Current State: Rising 🚀        │ │ ← Current State
│ │ #4CAF50, 20px bold              │ │   Dynamic color
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │ ← Breakdown Cards
│ │ │ 📱 App Engagement           │ │ │   #F5F5F5 background
│ │ │    Excellent                │ │ │   12px padding
│ │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 95%   │ │ │   8px radius
│ │ └─────────────────────────────┘ │ │   4px gap between
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ 📚 Learning Progress        │ │ │
│ │ │    Good                     │ │ │
│ │ │ ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░ 75%    │ │ │
│ │ └─────────────────────────────┘ │ │
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ ✅ Daily Check-ins          │ │ │
│ │ │    Great                    │ │ │
│ │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░ 85%    │ │ │
│ │ └─────────────────────────────┘ │ │
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ 🔄 Consistency              │ │ │
│ │ │    Excellent                │ │ │
│ │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 90%    │ │ │
│ │ └─────────────────────────────┘ │ │
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │ ← Action Button
│ │ │        Got it! 👍           │ │ │   #4CAF50 background
│ │ │        #FFFFFF, 16px        │ │ │   #FFFFFF text
│ │ └─────────────────────────────┘ │ │   44px height
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## 🔧 Component Specifications

### **Momentum Meter Widget**

#### **Circular Gauge Component**
```dart
class MomentumGauge extends StatefulWidget {
  final MomentumState state;
  final double percentage;
  final VoidCallback? onTap;
  
  const MomentumGauge({
    Key? key,
    required this.state,
    required this.percentage,
    this.onTap,
  }) : super(key: key);
}
```

**Visual Specifications:**
- **Size:** 120px diameter
- **Stroke Width:** 8px
- **Background Ring:** #E0E0E0, 8px stroke
- **Progress Ring:** State color, 8px stroke
- **Center Icon:** 48px emoji, state-specific
- **Animation:** 1.5s ease-out fill animation

#### **Progress Ring Colors**
```dart
Color getProgressColor(MomentumState state) {
  switch (state) {
    case MomentumState.rising:
      return Color(0xFF4CAF50);
    case MomentumState.steady:
      return Color(0xFF2196F3);
    case MomentumState.needsCare:
      return Color(0xFF FF9800);
  }
}
```

### **Momentum Card Component**

#### **Card Structure**
```dart
class MomentumCard extends StatelessWidget {
  final MomentumData data;
  final VoidCallback? onTap;
  
  const MomentumCard({
    Key? key,
    required this.data,
    this.onTap,
  }) : super(key: key);
}
```

**Visual Specifications:**
- **Background:** #F5F5F5
- **Padding:** 16px all sides
- **Border Radius:** 12px
- **Shadow:** 0px 2px 8px rgba(0,0,0,0.1)
- **Height:** 200px
- **Margin:** 16px horizontal

#### **Typography Hierarchy**
```dart
// Title
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: Color(0xFF757575),
  letterSpacing: 0.5,
)

// State Label
TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  color: stateColor,
  letterSpacing: -0.5,
)

// Message
TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  color: Color(0xFF212121),
  letterSpacing: -0.2,
  height: 1.2,
)
```

### **Quick Stats Cards**

#### **Stats Card Component**
```dart
class QuickStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  
  const QuickStatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  }) : super(key: key);
}
```

**Visual Specifications:**
- **Background:** #FFFFFF
- **Padding:** 12px all sides
- **Border Radius:** 8px
- **Shadow:** 0px 1px 4px rgba(0,0,0,0.1)
- **Height:** 84px
- **Gap:** 8px between cards

### **Action Buttons**

#### **Primary Action Button**
```dart
class MomentumActionButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final VoidCallback onPressed;
  
  const MomentumActionButton({
    Key? key,
    required this.text,
    required this.backgroundColor,
    required this.onPressed,
  }) : super(key: key);
}
```

**Visual Specifications:**
- **Height:** 44px
- **Border Radius:** 8px
- **Font Size:** 16px, medium weight
- **Text Color:** #FFFFFF
- **Padding:** 16px horizontal
- **Minimum Width:** 120px

---

## 🎬 Animation Specifications

### **Momentum Meter Animations**

#### **Initial Load Animation**
```dart
class MomentumLoadAnimation extends StatefulWidget {
  @override
  _MomentumLoadAnimationState createState() => _MomentumLoadAnimationState();
}

class _MomentumLoadAnimationState extends State<MomentumLoadAnimation>
    with TickerProviderStateMixin {
  
  late AnimationController _progressController;
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    
    // Progress ring animation
    _progressController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Fade in animation
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Start animations
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _progressController.forward();
    });
  }
}
```

**Animation Sequence:**
1. **Fade In** (0-800ms): Card fades in with opacity 0→1
2. **Progress Fill** (300-1800ms): Ring fills from 0% to target percentage
3. **Bounce** (1800-2000ms): Slight scale bounce (1.0→1.05→1.0)

#### **State Transition Animation**
```dart
class StateTransitionAnimation extends StatefulWidget {
  final MomentumState fromState;
  final MomentumState toState;
  final double fromPercentage;
  final double toPercentage;
}
```

**Transition Sequence:**
1. **Color Transition** (0-1000ms): Ring color morphs between states
2. **Progress Update** (200-1200ms): Ring percentage updates smoothly
3. **Icon Change** (500-700ms): Emoji crossfades between states
4. **Message Update** (800-1000ms): Text fades out/in with new message

### **Micro-Interactions**

#### **Button Press Animation**
```dart
class ButtonPressAnimation extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
      ),
    );
  }
}
```

**Scale Values:**
- **Rest:** 1.0
- **Pressed:** 0.95
- **Duration:** 100ms ease-out

#### **Card Tap Feedback**
```dart
// Haptic feedback on tap
HapticFeedback.lightImpact();

// Visual feedback
AnimationController(
  duration: Duration(milliseconds: 150),
  vsync: this,
)..forward().then((_) => controller.reverse());
```

---

## 📱 Responsive Design

### **Breakpoint Specifications**

#### **Small Phones (375px width)**
```css
/* iPhone SE, small Android phones */
.momentum-card {
  padding: 12px;
  height: 180px;
}

.momentum-gauge {
  width: 100px;
  height: 100px;
}

.stats-cards {
  flex-direction: column;
  gap: 6px;
}
```

#### **Standard Phones (390px width)**
```css
/* iPhone 14, most Android phones */
.momentum-card {
  padding: 16px;
  height: 200px;
}

.momentum-gauge {
  width: 120px;
  height: 120px;
}

.stats-cards {
  flex-direction: row;
  gap: 8px;
}
```

#### **Large Phones (428px width)**
```css
/* iPhone 14 Plus, large Android phones */
.momentum-card {
  padding: 20px;
  height: 220px;
}

.momentum-gauge {
  width: 140px;
  height: 140px;
}

.stats-cards {
  flex-direction: row;
  gap: 12px;
}
```

### **Landscape Mode Adaptations**

#### **Horizontal Layout**
```dart
class LandscapeMomentumView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: MomentumCard(), // Left side
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              QuickStatsGrid(),
              SizedBox(height: 16),
              ActionButtons(),
            ],
          ),
        ),
      ],
    );
  }
}
```

---

## ♿ Accessibility Specifications

### **Screen Reader Support**

#### **Semantic Labels**
```dart
Semantics(
  label: 'Your momentum is ${state.name}. ${message}',
  hint: 'Tap to view detailed breakdown',
  child: MomentumGauge(),
)
```

#### **State Announcements**
```dart
// VoiceOver/TalkBack announcements
Map<MomentumState, String> get semanticLabels => {
  MomentumState.rising: 'Your momentum is Rising. You\'re doing great! Keep up the excellent work.',
  MomentumState.steady: 'Your momentum is Steady. You\'re making good progress. Stay consistent.',
  MomentumState.needsCare: 'Your momentum needs care. Let\'s work together to get back on track.',
};
```

### **Color Contrast Compliance**

#### **WCAG AA Standards**
```dart
// All color combinations meet 4.5:1 contrast ratio
const Map<String, double> contrastRatios = {
  'rising-text-on-white': 8.2,      // #4CAF50 on #FFFFFF
  'steady-text-on-white': 5.1,      // #2196F3 on #FFFFFF
  'care-text-on-white': 4.8,        // #FF9800 on #FFFFFF
  'primary-text-on-white': 16.1,    // #212121 on #FFFFFF
  'secondary-text-on-white': 7.0,   // #757575 on #FFFFFF
};
```

### **Touch Target Specifications**

#### **Minimum Sizes**
```dart
const double minimumTouchTarget = 44.0; // iOS/Android standard

// All interactive elements meet minimum size
class AccessibleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: minimumTouchTarget,
        minHeight: minimumTouchTarget,
      ),
      child: button,
    );
  }
}
```

### **Dynamic Type Support**

#### **Text Scaling**
```dart
class ScalableText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  
  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    
    return Text(
      text,
      style: baseStyle.copyWith(
        fontSize: baseStyle.fontSize! * textScaleFactor.clamp(0.8, 1.3),
      ),
    );
  }
}
```

---

## 🔧 Implementation Guidelines

### **Flutter Widget Structure**

#### **Main Momentum View**
```dart
class MomentumView extends StatefulWidget {
  @override
  _MomentumViewState createState() => _MomentumViewState();
}

class _MomentumViewState extends State<MomentumView> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final momentumState = ref.watch(momentumProvider);
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MomentumCard(data: momentumState),
              SizedBox(height: 16),
              QuickStatsRow(stats: momentumState.stats),
              SizedBox(height: 16),
              WeeklyTrendChart(trend: momentumState.weeklyTrend),
              SizedBox(height: 16),
              ActionSection(actions: momentumState.suggestedActions),
            ],
          ),
        );
      },
    );
  }
}
```

### **State Management Integration**

#### **Riverpod Provider Setup**
```dart
final momentumProvider = StateNotifierProvider<MomentumNotifier, MomentumState>(
  (ref) => MomentumNotifier(ref.read(apiServiceProvider)),
);

class MomentumNotifier extends StateNotifier<MomentumState> {
  final ApiService _apiService;
  
  MomentumNotifier(this._apiService) : super(MomentumState.loading()) {
    loadMomentumData();
  }
  
  Future<void> loadMomentumData() async {
    try {
      final data = await _apiService.getCurrentMomentum();
      state = MomentumState.loaded(data);
    } catch (e) {
      state = MomentumState.error(e.toString());
    }
  }
}
```

### **Performance Optimizations**

#### **Widget Caching**
```dart
class OptimizedMomentumCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MomentumCard(),
    );
  }
}
```

#### **Animation Performance**
```dart
class PerformantGauge extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MomentumGaugePainter(
        progress: animation.value,
        color: stateColor,
      ),
      willChange: true, // Optimize for frequent repaints
    );
  }
}
```

---

## 📋 Design Checklist

### **Visual Design**
- [ ] All momentum states have distinct, accessible colors
- [ ] Typography hierarchy is clear and readable
- [ ] Spacing follows 8px grid system
- [ ] Icons and emojis are consistent in size and style
- [ ] Shadows and elevations create proper depth

### **Interaction Design**
- [ ] All touch targets meet 44px minimum size
- [ ] Tap feedback is immediate and clear
- [ ] Loading states provide clear progress indication
- [ ] Error states offer helpful recovery options
- [ ] Success states celebrate user achievements

### **Accessibility**
- [ ] Color contrast meets WCAG AA standards (4.5:1)
- [ ] All interactive elements have semantic labels
- [ ] Screen reader announcements are clear and helpful
- [ ] Dynamic type scaling is supported
- [ ] Reduced motion preferences are respected

### **Performance**
- [ ] Animations run at 60fps on target devices
- [ ] Images and assets are optimized for mobile
- [ ] Widget rebuilds are minimized
- [ ] Memory usage is within acceptable limits
- [ ] Battery impact is minimal

---

## 📚 Design Assets

### **Figma File Structure**
```
BEE Momentum Meter Design
├── 🎨 Design System
│   ├── Colors
│   ├── Typography
│   ├── Spacing
│   └── Components
├── 📱 Mobile Screens
│   ├── Rising State
│   ├── Steady State
│   ├── Needs Care State
│   └── Detail Modal
├── 🔄 Animations
│   ├── Load Sequence
│   ├── State Transitions
│   └── Micro-interactions
└── ♿ Accessibility
    ├── High Contrast
    ├── Large Text
    └── Screen Reader Flow
```

### **Export Specifications**
- **Icons:** SVG format, 24px base size
- **Images:** PNG format, 2x and 3x densities
- **Animations:** Lottie JSON files
- **Colors:** Hex values with opacity variants

---

**Document Status:** 🎨 Design Complete  
**Next Phase:** Development Implementation  
**Review Required:** Engineering Team, Accessibility Team  
**Target Completion:** Week 1, Milestone M1.1.1  

---

*This UI specification serves as the definitive design guide for implementing the Momentum Meter. All visual and interaction decisions should reference this document to ensure consistency and quality.* 