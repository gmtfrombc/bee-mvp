import 'package:app/core/services/onboarding_draft_storage_service.dart';
import 'package:app/features/onboarding/models/onboarding_draft.dart';
import 'package:app/features/onboarding/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Onboarding draft restores after cold restart', (tester) async {
    // ---------------------------------------------------------------------
    // 1. Seed SharedPreferences with an empty store (fresh install).
    // ---------------------------------------------------------------------
    SharedPreferences.setMockInitialValues({});

    // ---------------------------------------------------------------------
    // 2. User enters onboarding data and it is persisted.
    //    We emulate this by saving a draft directly via the storage service.
    // ---------------------------------------------------------------------
    const seedDraft = OnboardingDraft(goalTarget: 'Lose 10 lb');
    final storage = OnboardingDraftStorageService();
    await storage.saveDraft(seedDraft);

    // ---------------------------------------------------------------------
    // 3. Simulate an app cold-restart by creating a brand-new controller.
    //    The controller should load the draft asynchronously on init.
    // ---------------------------------------------------------------------
    final controller = OnboardingController();

    // Allow time for async loadDraft() to complete.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // ---------------------------------------------------------------------
    // 4. Verify that the state was restored correctly.
    // ---------------------------------------------------------------------
    expect(controller.state.goalTarget, equals('Lose 10 lb'));
  });
}
