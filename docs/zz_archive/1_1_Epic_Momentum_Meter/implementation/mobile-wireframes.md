# Mobile Momentum Meter Wireframes - Core Mobile Experience

**Epic:** 1.1 · Momentum Meter  
**Task:** T1.1.1.2 · Mobile Momentum Meter Wireframes  
**Status:** 🟡 IN PROGRESS  
**Created:** $(date)

---

## 📋 Overview

This document provides detailed wireframes for the mobile Momentum Meter layout, optimized for phones (375px-414px width) in portrait mode. The Momentum Meter replaces traditional "engagement scores" with a friendly, three-state motivation gauge that uses positive, encouraging language to support user motivation.

## 📱 Device Specifications

### Target Devices
- **iPhone SE (375px)** - Minimum width support
- **iPhone 12/13/14 (390px)** - Primary target
- **iPhone 12/13/14 Plus (428px)** - Large phone support
- **Android equivalents** - Similar screen sizes

### Design Constraints
- **Safe Area:** Account for notch/dynamic island
- **Thumb Zone:** Critical actions within 75% of screen height
- **Touch Targets:** Minimum 44px tap targets
- **Spacing:** 16px base grid system

---

## 🎨 Wireframe 1: Main Dashboard with Momentum Meter (Rising State)

```
┌─────────────────────────────────────┐ ← Status Bar (44px)
│ 🔋 📶 9:41 AM                      │
├─────────────────────────────────────┤ ← Safe Area Top
│ ← [Profile] Welcome back, Sarah! 🔔 │ ← Header (60px)
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │ ← Momentum Meter Card (180px)
│ │        YOUR MOMENTUM            │ │
│ │                                 │ │
│ │        ┌─────────┐              │ │
│ │        │  🚀     │  Rising!     │ │
│ │        │ ┌─────┐ │  You're on   │ │
│ │        │ │ ███ │ │  fire! 🔥    │ │
│ │        │ │ ███ │ │              │ │
│ │        │ └─────┘ │              │ │
│ │        └─────────┘              │ │
│ │                                 │ │
│ │ ▓▓▓▓▓▓▓▓▓▓▓ Keep it up! 💪      │ │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ ┌───────┐ ┌───────┐ ┌───────┐     │ ← Quick Stats Row (100px)
│ │Lessons│ │Streak │ │Today  │     │
│ │ 3/5   │ │  12   │ │ 45m   │     │
│ │done   │ │ days  │ │active │     │
│ └───────┘ └───────┘ └───────┘     │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │ ← Weekly Momentum Trend (160px)
│ │ 📈 Your Momentum This Week      │ │
│ │                                 │ │
│ │     🚀                          │ │
│ │    ╱ ╲     🚀                   │ │
│ │   ╱   ╲   ╱ ╲                   │ │
│ │  🙂     ╲ ╱   🚀                │ │
│ │ 🙂       🙂                     │ │
│ │ M T W T F S S                   │ │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ Keep the momentum going:            │ ← Action Section (120px)
│ • Complete today's lesson           │
│ • Log your evening reflection       │
│                                     │
│ ┌─────────────┐ ┌─────────────┐   │
│ │ Learn       │ │ Reflect     │   │
│ └─────────────┘ └─────────────┘   │
├─────────────────────────────────────┤
│                                     │ ← Bottom Padding (20px)
└─────────────────────────────────────┘ ← Safe Area Bottom
```

### Component Specifications

#### Header Section (60px)
- **Back Button:** 44x44px touch target, left aligned
- **Title:** "Welcome back, [Name]!" - dynamic greeting
- **Profile Avatar:** 32x32px circle, right side
- **Notifications:** Bell icon, badge for unread count

#### Momentum Meter Card (180px)
- **Background:** Elevated card with subtle shadow
- **Momentum Display:** Large circular gauge with state icon
- **State Messaging:** Encouraging text based on current state
- **Visual Indicator:** Animated progress ring around meter
- **Color Coding:** 
  - Rising 🚀 (Green): #4CAF50 - "You're on fire!"
  - Steady 🙂 (Blue): #2196F3 - "You're doing well!"
  - Needs Care 🌱 (Orange): #FF9800 - "Let's grow together!"

#### Quick Stats Row (100px)
- **Layout:** 3 equal-width cards with 8px gaps
- **Card Height:** 84px each
- **Content:** Title, main metric, subtitle
- **Interaction:** Tap to expand details

#### Weekly Momentum Trend (160px)
- **Chart Type:** Line chart with emoji state indicators
- **Interaction:** Tap points for daily details
- **Axes:** Days of week (bottom), momentum states (visual)
- **Styling:** Smooth curves with state emoji markers

#### Action Section (120px)
- **Text List:** Bullet points for encouraging next actions
- **Quick Buttons:** 2-column grid, 44px height
- **Button Style:** Outlined buttons with icons

---

## 🎨 Wireframe 2: Steady State

```
┌─────────────────────────────────────┐
│ 🔋 📶 9:41 AM                      │
├─────────────────────────────────────┤
│ ← [Profile] Good to see you! 🔔     │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │        YOUR MOMENTUM            │ │
│ │                                 │ │
│ │        ┌─────────┐              │ │
│ │        │  🙂     │  Steady!     │ │
│ │        │ ┌─────┐ │  You're      │ │
│ │        │ │ ▓▓▓ │ │  doing well! │ │
│ │        │ │ ▓▓░ │ │              │ │
│ │        │ └─────┘ │              │ │
│ │        └─────────┘              │ │
│ │                                 │ │
│ │ ▓▓▓▓▓▓▓░░░ Stay consistent! 👍  │ │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ ┌───────┐ ┌───────┐ ┌───────┐     │
│ │Lessons│ │Streak │ │Today  │     │
│ │ 2/5   │ │  8    │ │ 32m   │     │
│ │done   │ │ days  │ │active │     │
│ └───────┘ └───────┘ └───────┘     │
├─────────────────────────────────────┤
│ Small steps make big changes:       │
│ • Try one more lesson today         │
│ • Share how you're feeling          │
│                                     │
│ ┌─────────────┐ ┌─────────────┐   │
│ │ Learn More  │ │ Check In    │   │
│ └─────────────┘ └─────────────┘   │
└─────────────────────────────────────┘
```

---

## 🎨 Wireframe 3: Needs Care State

```
┌─────────────────────────────────────┐
│ 🔋 📶 9:41 AM                      │
├─────────────────────────────────────┤
│ ← [Profile] We're here for you! 🔔  │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │        YOUR MOMENTUM            │ │
│ │                                 │ │
│ │        ┌─────────┐              │ │
│ │        │  🌱     │  Needs Care  │ │
│ │        │ ┌─────┐ │  Let's grow  │ │
│ │        │ │ ▓░░ │ │  together!   │ │
│ │        │ │ ░░░ │ │              │ │
│ │        │ └─────┘ │              │ │
│ │        └─────────┘              │ │
│ │                                 │ │
│ │ ▓▓░░░░░░░░ Small steps count! 🌟│ │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ ┌───────┐ ┌───────┐ ┌───────┐     │
│ │Lessons│ │Streak │ │Today  │     │
│ │ 0/5   │ │  2    │ │ 8m    │     │
│ │done   │ │ days  │ │active │     │
│ └───────┘ └───────┘ └───────┘     │
├─────────────────────────────────────┤
│ 💡 Easy wins to get started:       │ ← Simplified, encouraging actions
│ • Take 2 minutes to check in       │
│ • Try one quick lesson              │
│                                     │
│ ┌─────────────┐ ┌─────────────┐   │
│ │ Quick Start │ │ Get Support │   │
│ └─────────────┘ └─────────────┘   │
├─────────────────────────────────────┤
│ "Every journey starts with a       │ ← Motivational message
│ single step. You've got this! 💪"  │
└─────────────────────────────────────┘
```

### Needs Care State Adaptations
- **Tone:** Extra encouraging, supportive language
- **Actions:** Simplified to 1-2 very easy wins
- **Messaging:** Motivational quotes and gentle support
- **Colors:** Warm orange (#FF9800) - growth and nurturing
- **Support Button:** Direct access to coach/help

---

## 🎨 Wireframe 4: Momentum Detail Modal

```
┌─────────────────────────────────────┐
│                                     │
│ ┌─────────────────────────────────┐ │ ← Modal Overlay
│ │ Your Momentum Details      ✕    │ │
│ ├─────────────────────────────────┤ │
│ │                                 │ │
│ │ Current State: Rising 🚀        │ │
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ App Engagement    Excellent │ │ │
│ │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 100%  │ │ │
│ │ └─────────────────────────────┘ │ │
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ Learning Progress    Good   │ │ │
│ │ │ ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░ 60%    │ │ │
│ │ └─────────────────────────────┘ │ │
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ Daily Check-ins   Great     │ │ │
│ │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░ 80%    │ │ │
│ │ └─────────────────────────────┘ │ │
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ Consistency      Excellent  │ │ │
│ │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 100%  │ │ │
│ │ └─────────────────────────────┘ │ │
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │        [Got it!]            │ │ │
│ │ └─────────────────────────────┘ │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Modal Specifications
- **Trigger:** Tap on momentum meter
- **Animation:** Slide up from bottom with backdrop
- **Breakdown:** 4 main contributing factors
- **Progress Bars:** Visual representation with positive labels
- **Dismiss:** Tap X, backdrop, or "Got it!" button

---

## 📐 Responsive Behavior

### Small Phones (375px width)
- **Momentum Card:** Reduce padding by 4px
- **Stats Cards:** Stack vertically if needed
- **Chart:** Maintain aspect ratio, reduce height to 140px
- **Buttons:** Full width on small screens

### Large Phones (428px width)
- **Momentum Card:** Increase padding by 4px
- **Stats Cards:** Add more spacing between cards
- **Chart:** Increase height to 180px
- **Buttons:** Maintain 2-column layout with more spacing

### Landscape Mode
- **Layout:** Horizontal split with momentum meter on left, details on right
- **Chart:** Expand to use full available width
- **Actions:** Horizontal button row instead of grid

---

## 🎯 Interaction Specifications

### Touch Targets
- **Minimum Size:** 44x44px for all interactive elements
- **Spacing:** 8px minimum between adjacent touch targets
- **Feedback:** 0.1s haptic feedback on tap

### Animations
- **Momentum Updates:** Smooth state transition over 1.5s
- **Card Reveals:** Staggered fade-in (0.1s delay between cards)
- **Chart Drawing:** Progressive line drawing over 2s
- **Button Press:** Scale down to 0.95 with 0.1s duration

### Gestures
- **Pull to Refresh:** Standard iOS/Android pattern
- **Swipe Cards:** Horizontal swipe to see more details
- **Pinch Chart:** Zoom into weekly chart for daily details

---

## 🔄 State Management

### Data States
- **Loading:** Skeleton screens with shimmer
- **Success:** Full data display with animations
- **Error:** Retry button with encouraging message
- **Empty:** Onboarding prompts for new users
- **Offline:** Cached data with offline indicator

### Real-time Updates
- **State Changes:** Smooth transition animations between states
- **New Events:** Subtle pulse animation on affected cards
- **Milestone Reached:** Celebration micro-animation
- **Streak Updates:** Confetti animation for achievements

---

## 📊 Accessibility Considerations

### Screen Reader Support
- **Semantic Labels:** Descriptive labels for all elements
- **State Announcement:** "Your momentum is Rising, you're doing great!"
- **Trend Description:** "Your momentum has been steady this week"
- **Progress Cards:** "Lessons: 3 out of 5 completed today"

### Visual Accessibility
- **Color Contrast:** WCAG AA compliance (4.5:1 ratio minimum)
- **Text Size:** Support for Dynamic Type scaling
- **Focus Indicators:** Clear focus rings for keyboard navigation
- **Reduced Motion:** Respect system motion preferences

### Motor Accessibility
- **Large Touch Targets:** 44px minimum for all interactive elements
- **Voice Control:** Support for voice navigation commands
- **Switch Control:** Compatible with assistive switch devices

---

## 📝 Next Steps

1. **Validate Wireframes:** Review with stakeholders and users
2. **Create High-Fidelity Mockups:** Add visual design and BEE branding
3. **Interactive Prototype:** Build clickable prototype for testing
4. **Accessibility Review:** Ensure compliance with accessibility standards

---

**Status:** ✅ COMPLETE  
**Next Task:** T1.1.1.3 - Create high-fidelity Figma mockups with BEE branding and momentum meter design 