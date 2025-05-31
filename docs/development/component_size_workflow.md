# Component Size Governance - Developer Workflow

**Quick Reference:** Services ≤500 lines | Widgets ≤300 lines | Screens ≤400 lines | Modals ≤250 lines

## Daily Development Workflow

### Before Starting Development

```bash
# Check current compliance status
./scripts/check_component_sizes.sh

# Review any existing violations in files you'll be modifying
```

### Creating New Components

1. **Choose appropriate component type:**
   ```dart
   // ✅ Good: Focused widget
   class UserAvatarWidget extends StatelessWidget {
     // ~100-200 lines - single responsibility
   }
   
   // ❌ Avoid: Multi-purpose widget
   class UserProfileCompleteWidget extends StatelessWidget {
     // 500+ lines - too many responsibilities
   }
   ```

2. **Keep line counts in mind:**
   - Plan component structure before coding
   - Extract helpers and sub-components early
   - Use composition over monolithic components

### Modifying Existing Components

1. **Check current size:**
   ```bash
   wc -l app/lib/path/to/your/component.dart
   ```

2. **If adding features to large components:**
   - Consider extracting to new component instead
   - Refactor before adding if near limit
   - Extract sub-components proactively

### Before Committing

The pre-commit hook will automatically run when you commit:

```bash
git add .
git commit -m "Your commit message"  # Hook runs automatically
```

**If size violations are detected:**
```bash
❌ COMMIT BLOCKED: 2 file(s) violate size guidelines

📋 Component Size Guidelines:
   Services: ≤500 lines
   Widgets: ≤300 lines
   Screens: ≤400 lines 
   Modals: ≤250 lines

🔧 To proceed:
   1. Refactor oversized components following established patterns
   2. See: docs/refactor/component_size_audit_refactor_plan.md
   3. Or bypass with: git commit --no-verify (NOT RECOMMENDED)
```

**Resolution Options:**

1. **Recommended: Refactor the component**
   ```bash
   # Follow refactoring patterns (see examples below)
   # Then commit again
   git add .
   git commit -m "Refactor: Extract components to comply with size guidelines"
   ```

2. **Emergency bypass (only for critical fixes):**
   ```bash
   git commit --no-verify -m "Emergency fix: Critical bug"
   # IMMEDIATELY follow up with refactoring
   ```

### During Pull Request

The CI/CD pipeline will:
- ✅ Block builds if violations exist
- 📊 Generate detailed reports in PR comments
- 📁 Upload detailed reports as artifacts

**Example PR Comment:**
```markdown
## 🔍 BEE Component Size Audit Report

**Overall Compliance Rate:** 85%
**Violations:** 3 components

### Critical Violations (>50% over limit)
- `TodayFeedTile`: 1261 lines (320% over 300-line limit)

### Actions Required
1. Refactor critical violations before merge
2. Plan refactoring for moderate violations
```

## Common Refactoring Patterns

### Widget Extraction

**Before:**
```dart
class LargeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 100 lines of header code
        Container(/* complex header */),
        
        // 150 lines of body code  
        Container(/* complex body */),
        
        // 100 lines of footer code
        Container(/* complex footer */),
      ],
    );
  }
}
```

**After:**
```dart
class LargeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LargeWidgetHeader(),
        LargeWidgetBody(), 
        LargeWidgetFooter(),
      ],
    );
  }
}

class LargeWidgetHeader extends StatelessWidget {
  // ~100 lines - focused responsibility
}

class LargeWidgetBody extends StatelessWidget {
  // ~150 lines - focused responsibility  
}

class LargeWidgetFooter extends StatelessWidget {
  // ~100 lines - focused responsibility
}
```

### Service Decomposition

**Before:**
```dart
class LargeService {
  // Data fetching methods (200 lines)
  Future<Data> fetchData() { }
  Future<Data> refreshData() { }
  
  // Validation logic (200 lines)
  bool validateData(Data data) { }
  List<Error> getValidationErrors(Data data) { }
  
  // Caching logic (200 lines)
  void cacheData(Data data) { }
  Data? getCachedData() { }
  
  // Total: 600+ lines
}
```

**After:**
```dart
class CoreDataService {
  // ~200 lines - core data operations
}

class DataValidationService {
  // ~200 lines - validation logic  
}

class DataCacheService {
  // ~200 lines - caching operations
}

class DataService {
  // ~100 lines - coordinates other services
  final CoreDataService _coreService;
  final DataValidationService _validationService;
  final DataCacheService _cacheService;
}
```

### Screen Component Breakdown

**Before:**
```dart
class LargeScreen extends StatefulWidget {
  @override
  _LargeScreenState createState() => _LargeScreenState();
}

class _LargeScreenState extends State<LargeScreen> {
  // State management (100 lines)
  // App bar building (100 lines)  
  // Body content (200 lines)
  // Bottom navigation (100 lines)
  // Event handlers (200 lines)
  // Total: 700+ lines
}
```

**After:**
```dart
class LargeScreen extends StatefulWidget {
  @override
  _LargeScreenState createState() => _LargeScreenState();
}

class _LargeScreenState extends State<LargeScreen> {
  // ~150 lines - screen structure and coordination
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LargeScreenAppBar(),
      body: LargeScreenBody(),
      bottomNavigationBar: LargeScreenNavigation(),
    );
  }
}

class LargeScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  // ~100 lines - app bar logic
}

class LargeScreenBody extends StatefulWidget {
  // ~200 lines - main content
}

class LargeScreenNavigation extends StatelessWidget {
  // ~100 lines - navigation logic
}
```

## Tools and Commands

### Quick Commands

```bash
# Check component sizes
./scripts/check_component_sizes.sh

# Generate detailed audit report  
./scripts/component_size_audit.sh

# Count lines in specific file
wc -l app/lib/path/to/file.dart

# Test pre-commit hook
git add . && git commit -m "Test commit"

# Bypass pre-commit (emergency only)
git commit --no-verify -m "Emergency fix"
```

### IDE Integration

**VS Code Settings (.vscode/settings.json):**
```json
{
  "files.associations": {
    "*.dart": "dart"
  },
  "editor.rulers": [300, 400, 500],
  "dart.lineLength": 300
}
```

## Troubleshooting

### Pre-commit Hook Not Running

```bash
# Check if hook exists and is executable
ls -la .git/hooks/pre-commit

# Make executable if needed
chmod +x .git/hooks/pre-commit

# Test manually
.git/hooks/pre-commit
```

### False Positives

If the size checker incorrectly categorizes a file:

1. Check the file path patterns in the script
2. Update patterns if needed (coordinate with team)
3. Consider if component is correctly structured

### CI/CD Failures

```bash
# Test locally before pushing
./scripts/check_component_sizes.sh

# Fix violations before pushing
# Push after achieving compliance
```

## Best Practices

### Proactive Size Management

1. **Monitor while developing:**
   ```bash
   # Add to your development flow
   watch -n 5 "wc -l current_file.dart"
   ```

2. **Extract early and often:**
   - Don't wait until hitting limits
   - Extract when approaching 70% of limit
   - Prefer composition over large components

3. **Use meaningful names:**
   ```dart
   // ✅ Good
   class UserProfileHeaderActions extends StatelessWidget { }
   
   // ❌ Avoid  
   class UserProfileWidget1 extends StatelessWidget { }
   ```

### Component Design

1. **Single Responsibility:**
   - Each component should have one clear purpose
   - Avoid "god widgets" that do everything

2. **Composition over Inheritance:**
   - Build complex UIs from smaller components
   - Use widget composition patterns

3. **Clear Boundaries:**
   - Separate data logic from UI logic
   - Extract business logic to services
   - Keep presentation components focused on UI

### Code Organization

```
lib/
├── features/
│   └── feature_name/
│       ├── presentation/
│       │   ├── screens/           # ≤400 lines each
│       │   ├── widgets/           # ≤300 lines each
│       │   └── components/        # ≤300 lines each
│       ├── domain/
│       └── data/
│           └── services/          # ≤500 lines each
└── core/
    └── services/                  # ≤500 lines each
```

## Support and Resources

- **Architecture Guide:** `docs/architecture/component_governance.md`
- **Refactoring Plan:** `docs/refactor/component_size_audit_refactor_plan.md`
- **Team Guidelines:** `docs/development/code_review_checklist.md`
- **Scripts:** `scripts/check_component_sizes.sh`, `scripts/component_size_audit.sh`

**Need Help?**
1. Check existing refactoring examples in the codebase
2. Review the refactoring plan documentation
3. Ask team for guidance on complex refactoring scenarios
4. Consider pair programming for challenging extractions 