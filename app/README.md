# BEE MVP - Momentum Meter App

<!-- GitHub build test: credentials restored 2025-01-06 -->

## Overview

The BEE (Behavioral Engagement Engine) Momentum Meter is a patient-facing motivation gauge that replaces traditional "engagement scores" with a friendly, three-state system designed to encourage rather than demotivate users.

## Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── supabase_config.dart      # Supabase configuration
│   └── theme/
│       └── app_theme.dart            # BEE design system implementation
├── features/
│   └── momentum/
│       ├── domain/
│       │   └── models/
│       │       └── momentum_data.dart # Momentum data models
│       └── presentation/
│           ├── providers/
│           │   └── momentum_provider.dart # Riverpod state management
│           └── screens/
│               └── momentum_screen.dart   # Main momentum screen
└── main.dart                         # App entry point
```

## Features Implemented (T1.1.3.1)

### ✅ Project Structure Setup
- Clean architecture with feature-based organization
- Core configuration and theming
- Domain models for momentum data
- State management with Riverpod

### ✅ Dependencies Added
- **State Management**: `flutter_riverpod` for reactive state management
- **Backend Integration**: `supabase_flutter` for API connectivity
- **Charts**: `fl_chart` for weekly trend visualization
- **Animations**: `lottie` for smooth animations
- **Utilities**: `intl`, `shared_preferences`, `connectivity_plus`

### ✅ Design System Implementation
- BEE momentum state colors (Rising 🚀, Steady 🙂, Needs Care 🌱)
- Material Design 3 foundation with custom theming
- Typography hierarchy optimized for health apps
- Accessibility-compliant color contrasts

### ✅ Basic UI Structure
- Main momentum screen with placeholder components
- Loading states with skeleton screens
- Error handling with retry functionality
- Pull-to-refresh functionality

## Momentum States

### Rising State 🚀
- **Color**: Green (#4CAF50)
- **Message**: "You're on fire! Keep up the great momentum!"
- **Tone**: Celebratory, energetic

### Steady State 🙂
- **Color**: Blue (#2196F3)
- **Message**: "You're doing well! Stay consistent!"
- **Tone**: Encouraging, supportive

### Needs Care State 🌱
- **Color**: Orange (#FF9800)
- **Message**: "Let's grow together! Every small step counts!"
- **Tone**: Nurturing, hopeful

## Getting Started

### Prerequisites
- Flutter SDK 3.7.2 or higher
- Dart SDK
- iOS Simulator / Android Emulator or physical device

### Installation

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure Supabase** (TODO):
   - Update `lib/core/config/supabase_config.dart` with actual Supabase credentials
   - Replace placeholder URLs and keys

3. **Run the app**:
   ```bash
   flutter run
   ```

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## Next Steps (Upcoming Tasks)

### T1.1.3.2: Circular Momentum Gauge (8h)
- Custom painter implementation for circular progress ring
- State-specific animations and theming
- Touch interactions and accessibility

### T1.1.3.3: Momentum Card Component (8h)
- Complete momentum card with gauge integration
- State transitions and animations
- Responsive design implementation

### T1.1.3.4: Weekly Trend Chart (8h)
- fl_chart integration for trend visualization
- Emoji markers for daily states
- Interactive chart with touch feedback

### T1.1.3.5: Quick Stats Cards (6h)
- Lessons, streak, and daily activity cards
- Dynamic data binding
- Responsive grid layout

### T1.1.3.6: Action Buttons (4h)
- State-appropriate action suggestions
- Navigation integration
- Accessibility compliance

## Architecture Decisions

### State Management
- **Riverpod**: Chosen for its compile-time safety and excellent testing support
- **AsyncValue**: Used for handling loading, error, and data states
- **StateNotifier**: Provides immutable state updates

### Design System
- **Material Design 3**: Modern foundation with custom BEE theming
- **Accessibility First**: WCAG AA compliance built-in
- **Responsive Design**: Optimized for 375px-428px mobile screens

### Performance
- **Efficient Rebuilds**: Riverpod providers minimize unnecessary widget rebuilds
- **Lazy Loading**: Components load data only when needed
- **Memory Management**: Proper disposal of resources and listeners

## Configuration

### Environment Variables (TODO)
Create a `.env` file with:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Assets
- `assets/images/`: Image assets for momentum meter
- `assets/animations/`: Lottie animation files
- `assets/icons/`: Custom icons and graphics
- `assets/fonts/`: BEE custom fonts (when available)

## Contributing

1. Follow the established project structure
2. Use the BEE design system colors and typography
3. Ensure accessibility compliance
4. Write tests for new features
5. Update documentation

## License

Private - BEE Platform Development

---

**Status**: T1.1.3.1 Complete ✅  
**Next Task**: T1.1.3.2 - Circular Momentum Gauge Implementation  
**Epic Progress**: M1.1.3 - 1/14 tasks complete (7%)
