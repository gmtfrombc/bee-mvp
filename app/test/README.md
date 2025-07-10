# Test Guide – Auto-Save & Restore for Onboarding Draft

This document summarises how widget & integration tests will verify the
**auto-save every 5 s** and **state restore after cold restart** requirements
for the Goal-Setup & Medical-History pages.

---

## 1. Unit Tests (Serialisation)

- Validate that `OnboardingDraft.toJson()` and `.fromJson()` preserve new
  medical & goal fields.
- Located in `features/onboarding/models/` tests.

## 2. Widget Test – Auto-Save Timer

1. Pump `MedicalHistoryPage` with a fake `SharedPreferences` instance
   (`setMockInitialValues({})`).
2. Tap a few checkboxes & enter numeric fields.
3. Fast-forward fake async clock by **6 s**.
4. Assert that draft JSON exists under key `draft_<userId>` with expected
   values.

```dart
FakeAsync().run((fake) {
  await tester.pumpWidget(MyApp());
  // interact …
  fake.elapse(const Duration(seconds: 6));
  final stored = prefs.getString('draft_user123');
  expect(stored, isNotEmpty);
});
```

## 3. Integration Test – Cold Restart Restore

1. Run app with `IntegrationTestWidgetsFlutterBinding` + in-memory prefs.
2. Fill form partially, wait 6 s for auto-save.
3. Call `binding.reassembleApplication()` to simulate termination.
4. Relaunch root widget; navigate back to page.
5. Verify previously entered values are present.

## 4. CI Hook

Add a `auto_save_restore_test.dart` in `app/integration/` and ensure it runs in
the existing `integration-test` GitHub workflow.

---

_Last updated: {{DATE}}_
