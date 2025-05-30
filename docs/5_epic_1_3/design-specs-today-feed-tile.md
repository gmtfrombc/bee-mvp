# Today Feed Tile Component Design Specifications

**Epic:** 1.3 · Today Feed (AI Daily Brief)  
**Task:** T1.3.2.1 - Design Today Feed tile component specifications  
**Module:** Core Mobile Experience  
**Status:** ✅ Complete  
**Created:** December 2024  

---

## 📋 Component Overview

The TodayFeedTile is a Material Design 3 card component that displays daily AI-generated health content prominently on the app's main screen. It serves as the primary entry point for users to engage with Today Feed content and earn momentum points.

### **Design Principles**
- **Single Focus**: One piece of engaging content per day
- **Curiosity-Driven**: Visual design that encourages exploration
- **Momentum Integration**: Clear indication of engagement rewards
- **Accessibility-First**: WCAG AA compliance throughout
- **Performance-Optimized**: Smooth animations and quick loading

---

## 🎨 Visual Design Specifications

### **Material Design 3 Structure**
```dart
// Component hierarchy
TodayFeedTile (Card)
├── Container (Gradient background)
│   ├── Header Section
│   │   ├── Title ("Today's Health Insight")
│   │   ├── Date Badge
│   │   └── Status Indicator (Fresh/Engaged/Offline)
│   ├── Content Section
│   │   ├── Content Title (Hero text)
│   │   ├── Content Summary (2-sentence preview)
│   │   └── Topic Category Badge
│   ├── Visual Section
│   │   └── Health Topic Icon/Illustration
│   └── Action Section
│       ├── Momentum Indicator (+1 point)
│       ├── Read More Button
│       └── Reading Time Estimate
```

### **Card Properties**
- **Shape**: RoundedRectangleBorder with 16px border radius
- **Elevation**: 2 (rising to 4 on hover/press)
- **Margins**: 16px horizontal, 8px vertical
- **Padding**: 20px internal padding
- **Height**: 
  - Mobile: 240px (compact)
  - Tablet: 280px (expanded)
- **Shadow**: AppTheme momentum color with 10% opacity

### **Color Scheme**
```dart
// Light Theme
static const Color cardBackground = Color(0xFFFFFFFF);
static const Color titleText = Color(0xFF212121);
static const Color summaryText = Color(0xFF757575);
static const Color accentColor = Color(0xFF4CAF50); // Momentum green

// Dark Theme  
static const Color darkCardBackground = Color(0xFF1E1E1E);
static const Color darkTitleText = Color(0xFFFFFFFF);
static const Color darkSummaryText = Color(0xFFB3B3B3);
static const Color darkAccentColor = Color(0xFF81C784); // Light momentum green
```

### **Typography Scale**
```dart
// Material Design 3 Typography
static const titleLarge = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  height: 1.2,
  letterSpacing: -0.3,
);

static const bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.4,
  letterSpacing: 0.1,
);

static const labelMedium = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.3,
  letterSpacing: 0.5,
);
```

---

## 🔄 Component States

### **1. Fresh Content State**
**Trigger**: New content available, user hasn't engaged today  
**Visual Indicators**:
- Subtle glow animation around card border (momentum green)
- "NEW" badge in top-right corner
- Momentum indicator shows "+1" with gentle pulse
- Full color saturation for all elements

**Accessibility**: 
- Semantic label: "Fresh health insight available"
- VoiceOver priority: High importance

### **2. Engaged State**
**Trigger**: User has viewed content and earned momentum point  
**Visual Indicators**:
- Checkmark icon overlay on momentum indicator
- Slightly reduced opacity (85%) for the entire card
- "VIEWED" status badge replaces "NEW"
- Disabled state styling for action button

**Accessibility**:
- Semantic label: "Health insight viewed, momentum earned"
- VoiceOver priority: Medium importance

### **3. Loading State**
**Trigger**: Content is being fetched or refreshed  
**Visual Indicators**:
- Skeleton animation for all text content
- Shimmer effect on card background
- Loading spinner in action button area
- Pulse animation for the entire card

**Accessibility**:
- Semantic label: "Loading today's health insight"
- Announce loading state to screen readers

### **4. Offline State**
**Trigger**: No network connection, showing cached content  
**Visual Indicators**:
- Cloud-off icon in header area
- "OFFLINE" badge with muted styling
- Grayscale color scheme (except momentum colors)
- Cached content timestamp display

**Accessibility**:
- Semantic label: "Offline - showing cached health insight"
- Clear indication of offline state

### **5. Error State**
**Trigger**: Content failed to load, network error occurred  
**Visual Indicators**:
- Error icon in content area
- Retry button in action section
- Muted color scheme with error accent
- Friendly error message

**Accessibility**:
- Semantic label: "Error loading health insight"
- Retry button clearly announced

---

## 📱 Responsive Design Specifications

### **Mobile Screens (375px - 428px width)**
```dart
// Mobile layout constraints
static const double mobileCardHeight = 240.0;
static const EdgeInsets mobilePadding = EdgeInsets.all(16.0);
static const EdgeInsets mobileMargin = EdgeInsets.symmetric(
  horizontal: 16.0, 
  vertical: 8.0
);

// Content layout
- Single column layout
- Compact header with date inline
- 2-line content title with ellipsis
- 3-line summary with fade edge
- Centered action button (48px height)
```

### **Tablet Screens (429px+ width)**
```dart
// Tablet layout constraints
static const double tabletCardHeight = 280.0;
static const EdgeInsets tabletPadding = EdgeInsets.all(24.0);
static const EdgeInsets tabletMargin = EdgeInsets.symmetric(
  horizontal: 24.0, 
  vertical: 12.0
);

// Content layout
- Two-column layout option
- Expanded header with badges
- 3-line content title
- 4-line summary with full text
- Larger action elements (56px height)
```

### **Dynamic Layout Breakpoints**
```dart
enum ScreenSize { mobile, tablet, desktop }

ScreenSize getScreenSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 429) return ScreenSize.mobile;
  if (width < 768) return ScreenSize.tablet;
  return ScreenSize.desktop;
}
```

---

## ♿ Accessibility Requirements

### **WCAG AA Compliance**
- **Color Contrast**: Minimum 4.5:1 for normal text, 3:1 for large text
- **Touch Targets**: Minimum 44px x 44px for all interactive elements
- **Focus Indicators**: Clear visual focus states for keyboard navigation
- **Motion Sensitivity**: Respect `prefers-reduced-motion` system setting

### **Screen Reader Support**
```dart
// Semantic labels for TodayFeedTile
Semantics(
  label: "Today's health insight: $contentTitle",
  hint: "Double tap to read full content and earn momentum point",
  button: true,
  onTap: _handleContentTap,
  child: // ... card content
);

// Individual element semantics
Semantics(
  label: "Content category: $topicCategory",
  excludeSemantics: true,
  child: TopicBadge(category: topicCategory),
);

Semantics(
  label: "Reading time: $estimatedMinutes minutes",
  excludeSemantics: true,
  child: ReadingTimeIndicator(minutes: estimatedMinutes),
);
```

### **Voice Control**
- **Voice Over**: Full navigation support
- **Voice Access**: Action labels for voice commands
- **Switch Control**: Proper focus management

### **Dynamic Type Support**
```dart
// Responsive typography
Widget _buildTitle(BuildContext context) {
  return Text(
    contentTitle,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      fontSize: _getResponsiveFontSize(context, baseFontSize: 20),
    ),
    maxLines: _getMaxLines(context),
    overflow: TextOverflow.ellipsis,
  );
}

double _getResponsiveFontSize(BuildContext context, {required double baseFontSize}) {
  final textScaleFactor = MediaQuery.textScaleFactorOf(context);
  return baseFontSize * textScaleFactor.clamp(0.8, 1.4);
}
```

---

## 🎭 Animation Specifications

### **Entry Animation**
```dart
// Card entrance animation
AnimationController _entryController = AnimationController(
  duration: Duration(milliseconds: 600),
  vsync: this,
);

// Slide up + fade in
Animation<Offset> _slideAnimation = Tween<Offset>(
  begin: Offset(0, 0.3),
  end: Offset.zero,
).animate(CurvedAnimation(
  parent: _entryController,
  curve: Curves.easeOutCubic,
));

Animation<double> _fadeAnimation = Tween<double>(
  begin: 0.0,
  end: 1.0,
).animate(CurvedAnimation(
  parent: _entryController,
  curve: Interval(0.2, 1.0, curve: Curves.easeOut),
));
```

### **Interaction Animations**
```dart
// Tap animation
Animation<double> _scaleAnimation = Tween<double>(
  begin: 1.0,
  end: 0.95,
).animate(CurvedAnimation(
  parent: _tapController,
  curve: Curves.easeInOut,
));

// Momentum indicator pulse
Animation<double> _pulseAnimation = Tween<double>(
  begin: 1.0,
  end: 1.1,
).animate(CurvedAnimation(
  parent: _pulseController,
  curve: Curves.elasticOut,
));
```

### **State Transition Animations**
- **Fresh → Engaged**: Scale + color transition (300ms)
- **Loading → Content**: Fade crossover (400ms)
- **Error → Retry**: Shake animation + color change (200ms)
- **Offline → Online**: Subtle glow restoration (500ms)

### **Motion Preferences**
```dart
// Respect reduced motion settings
bool get _shouldReduceMotion => 
    MediaQuery.disableAnimationsOf(context);

Duration get _animationDuration =>
    _shouldReduceMotion 
        ? Duration.zero 
        : Duration(milliseconds: 300);
```

---

## 🔌 Component Interface

### **Data Model**
```dart
@freezed
class TodayFeedContent with _$TodayFeedContent {
  const factory TodayFeedContent({
    required String id,
    required String title,
    required String summary,
    required String topicCategory,
    required DateTime publishedAt,
    required DateTime lastUpdated,
    String? externalLink,
    String? imageUrl,
    @Default(0.0) double aiConfidenceScore,
    @Default(2) int estimatedReadingMinutes,
    @Default(false) bool hasUserEngaged,
    @Default(false) bool isCached,
  }) = _TodayFeedContent;

  factory TodayFeedContent.fromJson(Map<String, dynamic> json) =>
      _$TodayFeedContentFromJson(json);
}

@freezed
class TodayFeedState with _$TodayFeedState {
  const factory TodayFeedState.loading() = _Loading;
  const factory TodayFeedState.loaded(TodayFeedContent content) = _Loaded;
  const factory TodayFeedState.error(String message) = _Error;
  const factory TodayFeedState.offline(TodayFeedContent cachedContent) = _Offline;
}

enum TodayFeedInteractionType {
  view,
  tap,
  externalLinkClick,
  share,
  bookmark,
}
```

### **Widget Interface**
```dart
class TodayFeedTile extends ConsumerStatefulWidget {
  const TodayFeedTile({
    super.key,
    this.onTap,
    this.onExternalLinkTap,
    this.onShare,
    this.onBookmark,
    this.showMomentumIndicator = true,
    this.enableAnimations = true,
    this.margin,
    this.height,
  });

  /// Callback when user taps the main content area
  final VoidCallback? onTap;
  
  /// Callback when user taps external link
  final VoidCallback? onExternalLinkTap;
  
  /// Callback for sharing content
  final VoidCallback? onShare;
  
  /// Callback for bookmarking content  
  final VoidCallback? onBookmark;
  
  /// Whether to show momentum point indicator
  final bool showMomentumIndicator;
  
  /// Whether to enable card animations
  final bool enableAnimations;
  
  /// Custom margin for the card
  final EdgeInsets? margin;
  
  /// Custom height for the card
  final double? height;

  @override
  ConsumerState<TodayFeedTile> createState() => _TodayFeedTileState();
}
```

### **Provider Interface**
```dart
// Riverpod provider for Today Feed content
final todayFeedProvider = StateNotifierProvider<TodayFeedNotifier, TodayFeedState>(
  (ref) => TodayFeedNotifier(ref.read(todayFeedServiceProvider)),
);

// Analytics tracking provider
final todayFeedAnalyticsProvider = Provider<TodayFeedAnalytics>(
  (ref) => TodayFeedAnalytics(ref.read(analyticsServiceProvider)),
);

// Content interaction provider
final contentInteractionProvider = Provider<ContentInteractionService>(
  (ref) => ContentInteractionService(
    ref.read(supabaseServiceProvider),
    ref.read(momentumServiceProvider),
  ),
);
```

---

## 🎯 Content Layout Specifications

### **Header Section**
```dart
Widget _buildHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Title and date
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Health Insight", style: labelMedium),
          Text(_formatDate(DateTime.now()), style: bodySmall),
        ],
      ),
      // Status badge
      _buildStatusBadge(),
    ],
  );
}
```

### **Content Section**
```dart
Widget _buildContent() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Content title
      Text(
        content.title,
        style: titleLarge,
        maxLines: _getMaxTitleLines(),
        overflow: TextOverflow.ellipsis,
      ),
      SizedBox(height: 8),
      // Content summary
      Text(
        content.summary,
        style: bodyMedium,
        maxLines: _getMaxSummaryLines(),
        overflow: TextOverflow.fade,
      ),
      SizedBox(height: 12),
      // Topic category badge
      TopicCategoryBadge(category: content.topicCategory),
    ],
  );
}
```

### **Action Section**
```dart
Widget _buildActionSection() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Reading time estimate
      Row(
        children: [
          Icon(Icons.schedule, size: 16),
          SizedBox(width: 4),
          Text("${content.estimatedReadingMinutes} min read"),
        ],
      ),
      // Read more button with momentum indicator
      ElevatedButton.icon(
        onPressed: _handleReadMore,
        icon: MomentumIcon(earned: content.hasUserEngaged),
        label: Text("Read More"),
      ),
    ],
  );
}
```

---

## 🔧 Technical Implementation Notes

### **Flutter 3.32.0 Compatibility**
- Use `debugPrint()` instead of deprecated `print()` statements
- Implement null safety with proper type annotations
- Use Material Design 3 components and theming
- Follow Flutter linting rules with strict analysis options
- Implement proper `dispose()` methods for StatefulWidgets
- Use `const` constructors where possible for performance

### **Performance Optimizations**
```dart
// Optimized image loading
Widget _buildContentImage() {
  return CachedNetworkImage(
    imageUrl: content.imageUrl ?? '',
    placeholder: (context, url) => ShimmerPlaceholder(),
    errorWidget: (context, url, error) => DefaultHealthIcon(),
    memCacheHeight: 200,
    memCacheWidth: 300,
  );
}

// Efficient list rendering
Widget build(BuildContext context) {
  return RepaintBoundary(
    child: // ... card content
  );
}
```

### **Memory Management**
```dart
@override
void dispose() {
  _entryController.dispose();
  _tapController.dispose();
  _pulseController.dispose();
  super.dispose();
}
```

---

## ✅ Acceptance Criteria Checklist

### **Visual Design**
- [ ] Material Design 3 card component structure
- [ ] Responsive layout for 375px-428px width range
- [ ] Proper elevation and shadow effects
- [ ] Consistent with app theme and color scheme
- [ ] Support for light and dark themes

### **Interactive States**
- [ ] Fresh content state with glow animation
- [ ] Engaged state with momentum confirmation
- [ ] Loading state with skeleton animation
- [ ] Offline state with cached content indicators
- [ ] Error state with retry functionality

### **Accessibility**
- [ ] WCAG AA color contrast compliance
- [ ] 44px minimum touch targets
- [ ] Screen reader semantic labels
- [ ] Keyboard navigation support
- [ ] Dynamic type scaling support

### **Performance**
- [ ] Smooth 60 FPS animations
- [ ] Efficient memory usage
- [ ] Quick load times (<500ms render)
- [ ] Proper widget lifecycle management
- [ ] Optimized image loading

### **Integration Ready**
- [ ] Component interface defined
- [ ] Data model specifications complete
- [ ] Provider interface documented
- [ ] Animation specifications ready
- [ ] Accessibility requirements documented

---

## 🚀 Next Steps

1. **Implementation Phase**: Use these specifications to implement the TodayFeedTile widget
2. **Data Integration**: Connect with TodayFeedContent data model
3. **Provider Setup**: Implement Riverpod providers for state management
4. **Testing**: Create comprehensive widget tests
5. **Accessibility Testing**: Validate screen reader compatibility

---

**Specification Status**: ✅ Complete  
**Next Task**: T1.3.2.2 - Create TodayFeedContent data model with JSON serialization  
**Estimated Implementation Time**: 8 hours  
**Dependencies**: AppTheme, ResponsiveService, AccessibilityService 