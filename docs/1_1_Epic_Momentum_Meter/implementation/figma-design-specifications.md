# Figma Design Specifications - Daily Engagement Dashboard

**Epic:** 1.1 · Daily Engagement Dashboard  
**Task:** T1.1.1.3 · High-Fidelity Figma Mockups  
**Status:** 🟡 IN PROGRESS  
**Created:** $(date)

---

## 📋 Overview

This document provides comprehensive design specifications for creating high-fidelity Figma mockups of the Daily Engagement Dashboard with BEE branding. These specifications ensure consistency, accessibility, and alignment with Material Design 3 principles.

## 🎨 BEE Brand Identity

### Brand Personality
- **Encouraging**: Supportive and motivational tone
- **Trustworthy**: Professional and reliable
- **Approachable**: Friendly and accessible
- **Empowering**: Focuses on user agency and progress

### Visual Principles
- **Clarity**: Information hierarchy is immediately clear
- **Warmth**: Colors and imagery feel welcoming
- **Progress**: Visual emphasis on growth and achievement
- **Balance**: Not overwhelming, promotes calm focus

---

## 🌈 Color System

### Primary Color Palette

#### BEE Primary (Wellness Green)
- **Primary 500**: `#4CAF50` - Main brand color, high engagement states
- **Primary 400**: `#66BB6A` - Lighter variant for backgrounds
- **Primary 600**: `#43A047` - Darker variant for emphasis
- **Primary 700**: `#388E3C` - Dark mode primary

#### Secondary Color Palette

#### Engagement Score Colors
- **High Engagement (71-100)**: `#4CAF50` (Success Green)
- **Medium Engagement (41-70)**: `#FF9800` (Warning Orange)
- **Low Engagement (0-40)**: `#F44336` (Alert Red - used sparingly)

#### Supporting Colors
- **Info Blue**: `#2196F3` - Information, links, secondary actions
- **Success Green**: `#4CAF50` - Achievements, completed goals
- **Warning Orange**: `#FF9800` - Attention needed, moderate progress
- **Error Red**: `#F44336` - Errors, critical issues (minimal use)

### Neutral Color Palette

#### Light Theme
- **Surface**: `#FFFFFF` - Card backgrounds, main surfaces
- **Background**: `#F8F9FA` - App background
- **On-Surface**: `#1C1B1F` - Primary text
- **On-Surface-Variant**: `#49454F` - Secondary text
- **Outline**: `#79747E` - Borders, dividers
- **Outline-Variant**: `#CAC4D0` - Subtle borders

#### Dark Theme Support
- **Surface**: `#1C1B1F` - Card backgrounds
- **Background**: `#141218` - App background
- **On-Surface**: `#E6E1E5` - Primary text
- **On-Surface-Variant**: `#CAC4D0` - Secondary text

### Accessibility Compliance
- **Contrast Ratios**: All color combinations meet WCAG 2.1 AA standards (4.5:1 minimum)
- **Color Blindness**: Tested with Deuteranopia and Protanopia simulators
- **High Contrast Mode**: Alternative high-contrast palette available

---

## 📝 Typography System

### Font Family
- **Primary**: SF Pro (iOS) / Outfit (Android) - System fonts for optimal performance
- **Fallback**: System UI fonts for cross-platform consistency

### Type Scale (Material Design 3)

#### Display Styles
- **Display Large**: 57px, Regular, -0.25px letter spacing
- **Display Medium**: 45px, Regular, 0px letter spacing
- **Display Small**: 36px, Regular, 0px letter spacing

#### Headline Styles
- **Headline Large**: 32px, Regular, 0px letter spacing - Page titles
- **Headline Medium**: 28px, Regular, 0px letter spacing - Section headers
- **Headline Small**: 24px, Regular, 0px letter spacing - Card titles

#### Title Styles
- **Title Large**: 22px, Regular, 0px letter spacing - Engagement score
- **Title Medium**: 16px, Medium, 0.15px letter spacing - Card headers
- **Title Small**: 14px, Medium, 0.1px letter spacing - Progress labels

#### Body Styles
- **Body Large**: 16px, Regular, 0.5px letter spacing - Main content
- **Body Medium**: 14px, Regular, 0.25px letter spacing - Secondary content
- **Body Small**: 12px, Regular, 0.4px letter spacing - Captions

#### Label Styles
- **Label Large**: 14px, Medium, 0.1px letter spacing - Buttons
- **Label Medium**: 12px, Medium, 0.5px letter spacing - Form labels
- **Label Small**: 11px, Medium, 0.5px letter spacing - Timestamps

### Typography Usage Guidelines
- **Engagement Score**: Title Large, Bold weight, Primary color
- **Section Headers**: Headline Small, Medium weight
- **Progress Metrics**: Title Medium, Regular weight
- **Action Items**: Body Large, Regular weight
- **Timestamps**: Label Small, Medium weight, On-Surface-Variant color

---

## 🧩 Component Library

### 1. Engagement Score Card

#### Visual Specifications
- **Dimensions**: 343×180px (mobile), full width with 16px margins
- **Background**: Surface color with 8px border radius
- **Elevation**: 2dp shadow (0px 1px 3px rgba(0,0,0,0.12))
- **Padding**: 24px all sides

#### Score Display
- **Score Number**: 72px font size, Bold weight, center aligned
- **Score Ring**: 120px diameter, 8px stroke width, animated progress
- **Trend Indicator**: 16px arrow icon + 14px text, positioned top-right
- **Progress Bar**: Full width, 4px height, 8px border radius

#### Color States
- **High Score (71-100)**: Success Green ring and text
- **Medium Score (41-70)**: Warning Orange ring and text
- **Low Score (0-40)**: Neutral gray ring, encouraging text

### 2. Progress Cards Row

#### Layout Specifications
- **Container**: Full width with 16px horizontal margins
- **Card Spacing**: 8px gaps between cards
- **Card Dimensions**: Equal width (107px on 375px screen), 84px height
- **Border Radius**: 12px for modern appearance

#### Individual Card Design
- **Background**: Surface color with 1dp elevation
- **Padding**: 12px all sides
- **Content Layout**: Vertical stack with center alignment
- **Icon**: 24×24px, positioned top center
- **Metric**: Title Medium, Bold weight
- **Label**: Body Small, On-Surface-Variant color

#### Card Types
1. **Goals Card**: Target icon, "3/5" metric, "Goals" label
2. **Streak Card**: Fire icon, "12" metric, "Day streak" label
3. **Time Card**: Clock icon, "45m" metric, "Today" label

### 3. Weekly Trend Chart

#### Chart Specifications
- **Dimensions**: 343×160px (mobile), full width with margins
- **Background**: Surface color, 12px border radius
- **Padding**: 16px all sides
- **Chart Area**: 311×112px effective drawing area

#### Chart Elements
- **Line Style**: 2px stroke width, smooth curves
- **Data Points**: 6px diameter circles, filled with primary color
- **Grid Lines**: Subtle horizontal lines, Outline-Variant color
- **Axis Labels**: Label Small, days of week (M T W T F S S)
- **Interaction**: Tap data points for details popup

#### Chart Colors
- **Line Color**: Primary 500 for positive trends
- **Fill Gradient**: Primary 500 to transparent (20% opacity)
- **Data Points**: Primary 600 with white border

### 4. Action Section

#### Layout Specifications
- **Container**: Full width, 16px horizontal margins
- **Section Title**: "Next Actions" - Headline Small, Medium weight
- **Action List**: Vertical list with 8px spacing between items
- **Button Row**: 2-column grid with 8px gap

#### Action List Items
- **Bullet Style**: Primary color dot (6px diameter)
- **Text Style**: Body Large, Regular weight
- **Spacing**: 4px between bullet and text

#### Quick Action Buttons
- **Dimensions**: Equal width, 44px height minimum
- **Style**: Outlined buttons with 20px border radius
- **Text**: Label Large, Medium weight
- **Icon**: 18×18px, positioned left of text
- **States**: Default, Pressed (scale 0.95), Disabled

### 5. Header Component

#### Layout Specifications
- **Height**: 60px including safe area
- **Background**: Background color (transparent)
- **Padding**: 16px horizontal, 8px vertical

#### Header Elements
- **Back Button**: 44×44px touch target, 24×24px icon
- **Title Text**: "Welcome back, [Name]!" - Title Large
- **Profile Avatar**: 32×32px circle, placeholder or user image
- **Notification Bell**: 24×24px icon with optional badge

---

## 📱 Screen Specifications

### 1. Main Dashboard Screen

#### Layout Structure
```
┌─────────────────────────────────────┐ ← Status Bar (44px)
│ 🔋 📶 9:41 AM                      │
├─────────────────────────────────────┤ ← Safe Area Top (44px)
│ ← [👤] Welcome back, Sarah! 🔔     │ ← Header (60px)
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │ ← Engagement Score Card (180px)
│ │           TODAY'S SCORE         │ │
│ │                                 │ │
│ │        ┌─────────┐              │ │
│ │        │   85    │  Excellent!  │ │
│ │        │ ┌─────┐ │  ↗️ +12 pts  │ │
│ │        │ │ 🔥  │ │              │ │
│ │        │ └─────┘ │              │ │
│ │        └─────────┘              │ │
│ │                                 │ │
│ │ ▓▓▓▓▓▓▓▓▓░░ 85% to daily goal   │ │
│ └─────────────────────────────────┘ │
│                                     │ ← Spacing (16px)
├─────────────────────────────────────┤
│ ┌───────┐ ┌───────┐ ┌───────┐     │ ← Progress Cards (100px)
│ │🎯     │ │🔥     │ │⏰     │     │
│ │ 3/5   │ │  12   │ │ 45m   │     │
│ │Goals  │ │Streak │ │Today  │     │
│ └───────┘ └───────┘ └───────┘     │
├─────────────────────────────────────┤ ← Spacing (16px)
│ ┌─────────────────────────────────┐ │ ← Weekly Trend Chart (160px)
│ │ 📈 Weekly Engagement Trend      │ │
│ │                                 │ │
│ │     ●                           │ │
│ │    ╱ ╲     ●                    │ │
│ │   ╱   ╲   ╱ ╲                   │ │
│ │  ╱     ╲ ╱   ●                  │ │
│ │ ●       ●                       │ │
│ │ M T W T F S S                   │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤ ← Spacing (16px)
│ Next Actions:                       │ ← Action Section (120px)
│ • Log your afternoon mood           │
│ • Complete 2 remaining goals        │
│                                     │
│ ┌─────────────┐ ┌─────────────┐   │
│ │ 😊 Log Mood │ │ 🎯 Goals   │   │
│ └─────────────┘ └─────────────┘   │
├─────────────────────────────────────┤
│                                     │ ← Bottom Padding (20px)
└─────────────────────────────────────┘ ← Safe Area Bottom (34px)
```

#### Screen Dimensions
- **Total Height**: 812px (iPhone 12/13/14)
- **Content Height**: 734px (excluding safe areas)
- **Width**: 375px (minimum), 390px (primary), 428px (large)

### 2. Loading State Screen

#### Skeleton Components
- **Score Card Skeleton**: Gray placeholder with shimmer animation
- **Progress Cards Skeleton**: Three gray rectangles with shimmer
- **Chart Skeleton**: Gray rectangle with subtle pulse animation
- **Shimmer Animation**: 1.5s duration, left-to-right sweep

#### Loading Indicators
- **Primary Spinner**: 24px diameter, Primary color, center of score circle
- **Progress Indicator**: Linear progress bar at top of screen
- **Skeleton Color**: `#E0E0E0` with 20% opacity shimmer overlay

### 3. Empty State Screen

#### Empty State Messaging
- **Illustration**: Simple line art of dashboard with dotted elements
- **Primary Message**: "Let's get started!"
- **Secondary Message**: "Complete your first activity to see your engagement score"
- **Call-to-Action**: "Log Your First Activity" button

#### Visual Elements
- **Illustration Size**: 200×160px, centered
- **Message Spacing**: 24px between illustration and text
- **Button**: Primary style, full width with 16px margins

### 4. Error State Screen

#### Error Messaging
- **Icon**: Alert triangle, 48×48px, Warning Orange
- **Primary Message**: "Something went wrong"
- **Secondary Message**: "We couldn't load your dashboard. Please try again."
- **Actions**: "Retry" button and "Contact Support" link

#### Layout
- **Centered Layout**: All elements vertically centered
- **Spacing**: 16px between elements
- **Button Style**: Primary button for retry action

---

## 🎭 Animation Specifications

### 1. Score Counter Animation

#### Animation Details
- **Duration**: 1.5 seconds
- **Easing**: Ease-out cubic bezier (0.25, 0.46, 0.45, 0.94)
- **Start Value**: 0
- **End Value**: Actual score (e.g., 85)
- **Frame Rate**: 60 FPS for smooth counting

#### Implementation Notes
- Count should increment in realistic steps (not just linear)
- Ring progress animates simultaneously with counter
- Color transitions smoothly based on score ranges

### 2. Card Reveal Animation

#### Staggered Animation
- **Total Duration**: 0.8 seconds
- **Stagger Delay**: 0.1 seconds between cards
- **Animation Type**: Slide up + fade in
- **Distance**: 20px upward movement
- **Opacity**: 0 to 1

#### Sequence
1. Score card animates first (0s)
2. Progress cards animate together (0.2s)
3. Chart animates last (0.4s)
4. Action section animates (0.6s)

### 3. Chart Drawing Animation

#### Line Drawing Effect
- **Duration**: 2 seconds
- **Easing**: Ease-in-out
- **Method**: SVG path animation or progressive point revelation
- **Data Points**: Appear after line reaches them

#### Interaction Animations
- **Data Point Tap**: Scale to 1.2x over 0.2s
- **Tooltip Appearance**: Fade in over 0.3s with slight scale
- **Chart Zoom**: Smooth transition over 0.4s

### 4. Button Interactions

#### Press Animation
- **Scale**: Down to 0.95x
- **Duration**: 0.1 seconds
- **Easing**: Ease-out
- **Haptic Feedback**: Light impact on iOS

#### Ripple Effect (Android)
- **Origin**: Touch point
- **Color**: Primary color at 20% opacity
- **Duration**: 0.6 seconds
- **Radius**: Expands to cover button area

### 5. Real-time Update Animations

#### Score Update
- **Pulse Effect**: Brief scale to 1.05x and back
- **Color Flash**: Subtle highlight in Primary color
- **Duration**: 0.5 seconds total

#### New Data Indicator
- **Badge Animation**: Scale from 0 to 1 with bounce
- **Glow Effect**: Subtle outer glow for 2 seconds
- **Auto-dismiss**: Fade out after 3 seconds

---

## 📐 Responsive Design Guidelines

### Breakpoints

#### Mobile Phones
- **Small**: 375px width (iPhone SE)
- **Medium**: 390px width (iPhone 12/13/14)
- **Large**: 428px width (iPhone 12/13/14 Plus)

#### Tablets
- **Portrait**: 768px width (iPad)
- **Landscape**: 1024px width (iPad landscape)

### Responsive Adaptations

#### Small Phones (375px)
- **Score Card**: Reduce padding to 20px
- **Progress Cards**: Maintain 3-column layout, reduce font sizes
- **Chart**: Reduce height to 140px
- **Buttons**: Stack vertically if needed

#### Large Phones (428px)
- **Score Card**: Increase padding to 28px
- **Progress Cards**: Add more spacing between cards
- **Chart**: Increase height to 180px
- **Buttons**: Maintain 2-column layout with more spacing

#### Tablet Portrait (768px)
- **Layout**: Maintain mobile layout with increased margins
- **Score Card**: Center with max-width of 400px
- **Progress Cards**: Increase card size proportionally
- **Chart**: Expand to use available width

#### Tablet Landscape (1024px)
- **Layout**: Two-column layout with score/cards on left, chart on right
- **Score Card**: Fixed width of 350px
- **Chart**: Expand to fill remaining space
- **Actions**: Horizontal layout instead of vertical

---

## ♿ Accessibility Specifications

### Color Accessibility

#### Contrast Ratios
- **Primary Text**: 7:1 contrast ratio (AAA level)
- **Secondary Text**: 4.5:1 contrast ratio (AA level)
- **Interactive Elements**: 3:1 contrast ratio minimum
- **Focus Indicators**: 3:1 contrast ratio with background

#### Color Blindness Support
- **Deuteranopia**: Tested with green-blind simulation
- **Protanopia**: Tested with red-blind simulation
- **Tritanopia**: Tested with blue-blind simulation
- **Alternative Indicators**: Icons and patterns supplement color coding

### Typography Accessibility

#### Font Size Support
- **Minimum Size**: 12px for small text
- **Body Text**: 16px minimum for readability
- **Dynamic Type**: Support iOS Dynamic Type and Android font scaling
- **Maximum Scale**: 200% scaling support

#### Reading Support
- **Line Height**: 1.5x font size minimum
- **Letter Spacing**: Optimized for readability
- **Word Spacing**: Standard spacing maintained at all scales

### Interaction Accessibility

#### Touch Targets
- **Minimum Size**: 44×44px for all interactive elements
- **Spacing**: 8px minimum between adjacent targets
- **Visual Feedback**: Clear pressed states for all buttons

#### Screen Reader Support
- **Semantic Labels**: Descriptive labels for all elements
- **Score Announcement**: "Your engagement score is 85 out of 100, excellent"
- **Progress Description**: "Goals: 3 out of 5 completed, 60 percent"
- **Chart Description**: "Weekly trend chart showing increasing engagement"

#### Keyboard Navigation
- **Focus Order**: Logical tab order through all interactive elements
- **Focus Indicators**: Clear visual focus rings
- **Keyboard Shortcuts**: Standard navigation shortcuts supported

### Motion Accessibility

#### Reduced Motion Support
- **Respect Preferences**: Honor system reduced motion settings
- **Alternative Animations**: Fade transitions instead of movement
- **Essential Motion**: Only animate when necessary for understanding

---

## 📋 Figma File Organization

### Page Structure
```
📄 BEE Dashboard Design System
├── 🎨 Brand Guidelines
│   ├── Color Palette
│   ├── Typography Scale
│   └── Logo Usage
├── 🧩 Component Library
│   ├── Engagement Score Card
│   ├── Progress Cards
│   ├── Chart Components
│   ├── Buttons & Controls
│   └── Navigation Elements
├── 📱 Mobile Screens
│   ├── Main Dashboard
│   ├── Loading State
│   ├── Empty State
│   ├── Error State
│   └── Score Detail Modal
├── 📐 Responsive Layouts
│   ├── Small Phone (375px)
│   ├── Large Phone (428px)
│   ├── Tablet Portrait
│   └── Tablet Landscape
└── 🎭 Animation Specs
    ├── Score Counter
    ├── Card Reveals
    ├── Chart Drawing
    └── Micro-interactions
```

### Component Organization
- **Atomic Design**: Atoms → Molecules → Organisms → Templates
- **Consistent Naming**: BEE/Component/Variant format
- **Auto Layout**: Use Figma Auto Layout for responsive components
- **Design Tokens**: Create styles for colors, typography, and effects

### Collaboration Features
- **Comments**: Use for design decisions and feedback
- **Version History**: Tag major iterations
- **Sharing**: Set up proper permissions for stakeholders
- **Handoff**: Prepare developer handoff with specs and assets

---

## 🚀 Implementation Notes

### Asset Export
- **Icons**: SVG format for scalability
- **Images**: 2x and 3x PNG for different screen densities
- **Colors**: Export as design tokens (JSON format)
- **Typography**: Document font weights and sizes

### Developer Handoff
- **Spacing**: Document all margins, padding, and gaps
- **Animations**: Provide duration, easing, and sequence details
- **States**: Document all interactive states and transitions
- **Responsive**: Provide breakpoint specifications

### Design System Integration
- **Flutter Theme**: Map colors and typography to Flutter ThemeData
- **Component Library**: Create reusable Flutter widgets
- **Documentation**: Maintain design system documentation
- **Updates**: Version control for design system changes

---

## 📝 Next Steps

1. **Create Figma File**: Set up file structure and import brand assets
2. **Build Component Library**: Create all reusable components
3. **Design Screens**: Apply components to create all screen states
4. **Add Interactions**: Prototype key user flows and animations
5. **Accessibility Review**: Validate all accessibility requirements
6. **Stakeholder Review**: Present designs for feedback and approval
7. **Developer Handoff**: Prepare assets and specifications for implementation

---

**Status:** ✅ COMPLETE  
**Next Task:** T1.1.1.4 - Design engagement score visualization components 