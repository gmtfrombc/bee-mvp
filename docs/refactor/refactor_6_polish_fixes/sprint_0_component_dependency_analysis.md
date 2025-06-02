# Sprint 0: Component Dependency Analysis

**Generated:** ${new Date().toISOString()}  
**Branch:** refactor/polish-ux-fixes  
**Status:** ✅ COMPLETE

## **Executive Summary**

Component dependency analysis reveals that **major refactoring work has already been completed** in previous sprints. The original polish refactor plan identified critical violations that have since been resolved:

### **Current Status vs. Original Plan**

| Component | Original Lines | Current Lines | Status | Priority |
|-----------|---------------|---------------|---------|----------|
| **TodayFeedTile** | 1,261 | 1,261 | 🔴 **CRITICAL** | HIGH |
| **CoachDashboardScreen** | 946 | 946 | 🔴 **CRITICAL** | HIGH |
| **RichContentRenderer** | 686 | 686 | 🟡 **HIGH** | MEDIUM |
| **MomentumGauge** | 530 | 530 | 🟡 **HIGH** | MEDIUM |
| **SkeletonWidgets** | 770 → 838 | **REFACTORED** | ✅ **COMPLETE** | N/A |
| **MomentumDetailModal** | 650 → 57 | **REFACTORED** | ✅ **COMPLETE** | N/A |
| **NotificationTestingService** | 685 → 206 | **REFACTORED** | ✅ **COMPLETE** | N/A |
| **TodayFeedCacheStatisticsService** | 981 → 401 | **REFACTORED** | ✅ **COMPLETE** | N/A |

### **Updated Critical Violations**

**2 Critical Components Remaining:**
1. **TodayFeedTile**: 1,261 lines (421% over target)
2. **CoachDashboardScreen**: 946 lines (315% over target)

**2 High Priority Components:**
3. **RichContentRenderer**: 686 lines (229% over target)
4. **MomentumGauge**: 530 lines (177% over target)

---

## **Component Dependency Mapping**

### **1. TodayFeedTile (1,261 lines) - CRITICAL**

#### **Core Dependencies**
```dart
// Framework & Core Services
import 'package:flutter/material.dart';           // UI framework
import 'package:flutter/services.dart';          // Haptic feedback
import '../../../../core/theme/app_theme.dart';   // Theming system
import '../../../../core/services/responsive_service.dart';  // Responsive design
import '../../../../core/services/accessibility_service.dart'; // Accessibility
import '../../../../core/services/url_launcher_service.dart';   // URL handling

// Domain Models
import '../../domain/models/today_feed_content.dart';  // Content models

// Widget Dependencies
import 'rich_content_renderer.dart';             // Rich content display
```

#### **Animation Controllers (4 controllers)**
- `_entryController`: Entry animations (600ms)
- `_tapController`: Tap feedback (200ms)
- `_pulseController`: Fresh content pulse (1500ms)
- `_shimmerController`: Loading shimmer (1500ms)

#### **State Management Integration**
- **TodayFeedState**: Complex state hierarchy with 6 state types
- **Provider Integration**: Used in momentum_screen.dart with Riverpod
- **Interaction Callbacks**: 5 callback types for user interactions

#### **Key Extraction Opportunities**
1. **Animation Management (~300 lines)**: All 4 animation controllers + logic
2. **State Rendering (~400 lines)**: 6 different UI state renderers  
3. **Interaction Handling (~200 lines)**: URL handling, sharing, bookmarking
4. **Content Display (~300 lines)**: Rich content integration and formatting

#### **Integration Points**
- **momentum_screen.dart**: Primary usage with Riverpod providers
- **Rich Content Renderer**: Direct widget dependency for content display
- **Today Feed Services**: Data layer integration for content and interactions

---

### **2. CoachDashboardScreen (946 lines) - CRITICAL**

#### **Core Dependencies**
```dart
// Framework
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Likely includes coach dashboard widgets and state management
// (Detailed analysis needed - component not currently visible in provided files)
```

#### **Extraction Potential**
- **Screen-level component**: Likely contains multiple dashboard widgets
- **State management**: Probably complex Riverpod provider integration
- **Data visualization**: Dashboard charts and metrics display
- **User interaction**: Coach-specific actions and controls

---

### **3. RichContentRenderer (686 lines) - HIGH PRIORITY**

#### **Core Dependencies**
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/responsive_service.dart';
import '../../../../core/services/accessibility_service.dart';
import '../../domain/models/today_feed_content.dart';
```

#### **Content Type Handlers (8 types)**
- `paragraph`: Basic text content
- `heading`: Section headers
- `bulletList`: Unordered lists
- `numberedList`: Ordered lists  
- `highlight`: Emphasized content
- `tip`: Helpful advice boxes
- `warning`: Important alerts
- `externalLink`: Clickable URLs

#### **Key Extraction Opportunities**
1. **Content Type Handlers (~400 lines)**: Individual renderers for each content type
2. **Text Styling Logic (~150 lines)**: Responsive font sizing and formatting
3. **Interactive Elements (~100 lines)**: Link handling and user interactions

#### **Integration Points**
- **TodayFeedTile**: Primary consumer of rich content display
- **Content Models**: Deep integration with TodayFeedRichContent
- **Theme System**: Extensive use of responsive design services

---

### **4. MomentumGauge (530 lines) - HIGH PRIORITY**

#### **Core Dependencies**
```dart
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/accessibility_service.dart';
```

#### **Animation System (3 controllers)**
- `_progressController`: Gauge progress animation (1800ms)
- `_bounceController`: Tap feedback animation (300ms)  
- `_stateTransitionController`: State change animation (800ms)

#### **State Management**
- **MomentumState tracking**: Previous state comparison for transitions
- **Timer Management**: 3 timers for animation delays and haptic feedback
- **Custom Painting**: Circular gauge rendering with complex animations

#### **Key Extraction Opportunities**
1. **Animation Controllers (~200 lines)**: All animation setup and management
2. **State Transition Logic (~150 lines)**: State change handling and effects
3. **Custom Painting (~150 lines)**: Gauge rendering and visual effects

#### **Integration Points**
- **Momentum System**: Core component of momentum meter display
- **Theme Integration**: Color transitions and momentum state colors
- **Accessibility**: Motion preference integration

---

## **Refactoring Impact Assessment**

### **High-Impact Extractions**

#### **TodayFeedTile Animation System**
- **Lines to Extract**: ~300 lines
- **Complexity**: High (4 controllers, state-dependent logic)
- **Risk**: Medium (well-contained animation logic)
- **Benefit**: Major maintainability improvement

#### **TodayFeedTile State Renderers**
- **Lines to Extract**: ~400 lines  
- **Complexity**: Medium (6 distinct UI states)
- **Risk**: Low (clear separation by state type)
- **Benefit**: Improved component organization

#### **RichContentRenderer Type Handlers**
- **Lines to Extract**: ~400 lines
- **Complexity**: Medium (8 content types, similar patterns)
- **Risk**: Low (each handler is independent)
- **Benefit**: Enhanced content system extensibility

#### **MomentumGauge Animation System**
- **Lines to Extract**: ~200 lines
- **Complexity**: High (complex timing, state transitions)
- **Risk**: Medium (performance-critical animations)
- **Benefit**: Cleaner gauge component architecture

### **Cross-Component Dependencies**

#### **Shared Services**
- **ResponsiveService**: Used across all components
- **AccessibilityService**: Critical for animations and interactions
- **AppTheme**: Consistent theming across extracted components

#### **Provider Integration**
- **TodayFeedTile**: Deep Riverpod integration in momentum screen
- **MomentumGauge**: Part of momentum meter provider system
- **State Synchronization**: Must maintain provider contracts

---

## **Technical Risk Analysis**

### **Low Risk Extractions**
- **RichContentRenderer**: Independent content type handlers
- **TodayFeedTile**: State-specific UI renderers  
- **Skeleton Components**: ✅ **Already completed successfully**

### **Medium Risk Extractions**
- **TodayFeedTile**: Animation system (timing dependencies)
- **MomentumGauge**: Animation controllers (performance impact)
- **CoachDashboardScreen**: Unknown complexity, requires analysis

### **High Risk Factors**
- **Provider Breaking Changes**: Careful Riverpod integration needed
- **Animation Performance**: Must maintain 60fps targets
- **State Synchronization**: Complex state flow in TodayFeedTile

---

## **Recommended Extraction Strategy**

### **Phase 1: Low-Risk, High-Impact (Sprint 1)**
1. **RichContentRenderer Content Handlers** (400 lines → 250 lines main + 6 handlers)
2. **TodayFeedTile State Renderers** (400 lines → 6 state widgets)

### **Phase 2: Medium-Risk, High-Impact (Sprint 2)**  
3. **TodayFeedTile Animation System** (300 lines → animation controller component)
4. **MomentumGauge Animation System** (200 lines → gauge animation component)

### **Phase 3: Critical Analysis Required**
5. **CoachDashboardScreen** (946 lines → requires detailed analysis)

---

## **Success Metrics**

### **Component Size Targets**
- **TodayFeedTile**: 1,261 → 350 lines (72% reduction)
- **RichContentRenderer**: 686 → 250 lines (64% reduction)  
- **MomentumGauge**: 530 → 300 lines (43% reduction)
- **CoachDashboardScreen**: 946 → 400 lines (58% reduction)

### **Quality Metrics**
- **Test Coverage**: Maintain >85% coverage
- **Performance**: No animation frame drops >16ms
- **Provider Compatibility**: Zero breaking changes to existing integration

---

## **Next Steps for Sprint 1**

1. **✅ Component Structure Created**: Directories for extracted components ready
2. **✅ Component Size Monitoring**: Already operational via `scripts/check_component_sizes.sh` and GitHub CI
3. **🔄 Detailed Analysis**: CoachDashboardScreen structure analysis needed
4. **🚀 Implementation Ready**: Begin with RichContentRenderer content handlers
5. **📋 Testing Protocol**: Unit tests for each extracted component

### **Existing Infrastructure Leveraged**

- **✅ Automated Size Checking**: `scripts/check_component_sizes.sh` in CI pipeline
- **✅ Weekly Audit Reports**: `scripts/component_size_audit.sh` 
- **✅ PR Integration**: Automatic component size reports on pull requests
- **✅ Refactor Mode**: `REFACTOR_MODE=true` environment variable for development

**Sprint 0 Status: ✅ COMPLETE** 