// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get onboarding_q10_prompt =>
      'On a scale of 1 to 5 (5 being highest importance), select the importance of each to you';

  @override
  String get onboarding_q11_prompt =>
      'On a scale of 1 to 5 (5 being most ready) select how ready you are to make meaningful changes?';

  @override
  String get onboarding_q12_prompt =>
      'On a scale of 1 to 5 (5 being most confident) how confident are you that you can stick with changes you start?';

  @override
  String get onboarding_q13_prompt =>
      'Which statement best describes why you want to make changes right now?';

  @override
  String get onboarding_q14_prompt =>
      'If you reach your health goals, what will be most satisfying?';

  @override
  String get onboarding_q15_prompt => 'When I face a challenge, I usually…';

  @override
  String get onboarding_q16_prompt =>
      'How do you want your coach to support you?';
}
