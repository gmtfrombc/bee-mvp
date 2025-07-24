import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 's_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/s.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// Question 10 prompt – importance selection
  ///
  /// In en, this message translates to:
  /// **'On a scale of 1 to 5 (5 being highest importance), select the importance of each to you'**
  String get onboarding_q10_prompt;

  /// Question 11 prompt – readiness to change
  ///
  /// In en, this message translates to:
  /// **'On a scale of 1 to 5 (5 being most ready) select how ready you are to make meaningful changes?'**
  String get onboarding_q11_prompt;

  /// Question 12 prompt – confidence level
  ///
  /// In en, this message translates to:
  /// **'On a scale of 1 to 5 (5 being most confident) how confident are you that you can stick with changes you start?'**
  String get onboarding_q12_prompt;

  /// Question 13 prompt – motivation reason
  ///
  /// In en, this message translates to:
  /// **'Which statement best describes why you want to make changes right now?'**
  String get onboarding_q13_prompt;

  /// Question 14 prompt – satisfaction outcome
  ///
  /// In en, this message translates to:
  /// **'If you reach your health goals, what will be most satisfying?'**
  String get onboarding_q14_prompt;

  /// Question 15 prompt – coping mechanism
  ///
  /// In en, this message translates to:
  /// **'When I face a challenge, I usually…'**
  String get onboarding_q15_prompt;

  /// Question 16 prompt – coach support style
  ///
  /// In en, this message translates to:
  /// **'How do you want your coach to support you?'**
  String get onboarding_q16_prompt;

  /// Label for weight input (pounds)
  ///
  /// In en, this message translates to:
  /// **'Current weight (lb)'**
  String get onboarding_medical_weight_label;

  /// Label for height feet input
  ///
  /// In en, this message translates to:
  /// **'Height (ft)'**
  String get onboarding_medical_height_ft_label;

  /// Label for height inches input
  ///
  /// In en, this message translates to:
  /// **'Height (in)'**
  String get onboarding_medical_height_in_label;

  /// Label for systolic blood pressure input
  ///
  /// In en, this message translates to:
  /// **'Blood pressure systolic (top)'**
  String get onboarding_medical_bp_systolic_label;

  /// Label for diastolic blood pressure input
  ///
  /// In en, this message translates to:
  /// **'Blood pressure diastolic (bottom)'**
  String get onboarding_medical_bp_diastolic_label;

  /// Helper text shown at bottom of medical history page
  ///
  /// In en, this message translates to:
  /// **'This information is private and used only to personalize your coaching.'**
  String get onboarding_medical_history_helper;

  /// Helper text shown on goal setup page
  ///
  /// In en, this message translates to:
  /// **'Set a realistic, measurable goal to track your progress.'**
  String get onboarding_goal_setup_helper;

  /// No description provided for @onboarding_med_condition_prediabetes.
  ///
  /// In en, this message translates to:
  /// **'Prediabetes or insulin resistance'**
  String get onboarding_med_condition_prediabetes;

  /// No description provided for @onboarding_med_condition_type2_diabetes.
  ///
  /// In en, this message translates to:
  /// **'Type 2 diabetes'**
  String get onboarding_med_condition_type2_diabetes;

  /// No description provided for @onboarding_med_condition_hypertension.
  ///
  /// In en, this message translates to:
  /// **'High blood pressure (hypertension)'**
  String get onboarding_med_condition_hypertension;

  /// No description provided for @onboarding_med_condition_high_cholesterol.
  ///
  /// In en, this message translates to:
  /// **'High cholesterol'**
  String get onboarding_med_condition_high_cholesterol;

  /// No description provided for @onboarding_med_condition_high_triglycerides.
  ///
  /// In en, this message translates to:
  /// **'High triglycerides'**
  String get onboarding_med_condition_high_triglycerides;

  /// No description provided for @onboarding_med_condition_obesity.
  ///
  /// In en, this message translates to:
  /// **'Obesity'**
  String get onboarding_med_condition_obesity;

  /// No description provided for @onboarding_med_condition_pcos.
  ///
  /// In en, this message translates to:
  /// **'Polycystic Ovary Syndrome (PCOS)'**
  String get onboarding_med_condition_pcos;

  /// No description provided for @onboarding_med_condition_fatty_liver.
  ///
  /// In en, this message translates to:
  /// **'Fatty liver (NAFLD)'**
  String get onboarding_med_condition_fatty_liver;

  /// No description provided for @onboarding_med_condition_cardiovascular_disease.
  ///
  /// In en, this message translates to:
  /// **'Cardiovascular disease'**
  String get onboarding_med_condition_cardiovascular_disease;

  /// No description provided for @onboarding_med_condition_stroke_tia.
  ///
  /// In en, this message translates to:
  /// **'Stroke or TIA'**
  String get onboarding_med_condition_stroke_tia;

  /// No description provided for @onboarding_med_condition_anxiety.
  ///
  /// In en, this message translates to:
  /// **'Anxiety'**
  String get onboarding_med_condition_anxiety;

  /// No description provided for @onboarding_med_condition_depression.
  ///
  /// In en, this message translates to:
  /// **'Depression'**
  String get onboarding_med_condition_depression;

  /// No description provided for @onboarding_med_condition_ptsd.
  ///
  /// In en, this message translates to:
  /// **'PTSD or trauma-related condition'**
  String get onboarding_med_condition_ptsd;

  /// No description provided for @onboarding_med_condition_bipolar.
  ///
  /// In en, this message translates to:
  /// **'Bipolar disorder'**
  String get onboarding_med_condition_bipolar;

  /// No description provided for @onboarding_med_condition_adhd.
  ///
  /// In en, this message translates to:
  /// **'ADHD'**
  String get onboarding_med_condition_adhd;

  /// No description provided for @onboarding_med_condition_binge_eating.
  ///
  /// In en, this message translates to:
  /// **'Binge eating'**
  String get onboarding_med_condition_binge_eating;

  /// No description provided for @onboarding_med_condition_restrictive_eating.
  ///
  /// In en, this message translates to:
  /// **'Restrictive eating / chronic dieting'**
  String get onboarding_med_condition_restrictive_eating;

  /// No description provided for @onboarding_med_condition_bulimia.
  ///
  /// In en, this message translates to:
  /// **'Bulimia or purging behaviors'**
  String get onboarding_med_condition_bulimia;

  /// No description provided for @onboarding_med_condition_anorexia.
  ///
  /// In en, this message translates to:
  /// **'Anorexia or extremely low weight'**
  String get onboarding_med_condition_anorexia;

  /// No description provided for @onboarding_med_condition_thyroid_disorder.
  ///
  /// In en, this message translates to:
  /// **'Thyroid disorder'**
  String get onboarding_med_condition_thyroid_disorder;

  /// No description provided for @onboarding_med_condition_sleep_apnea.
  ///
  /// In en, this message translates to:
  /// **'Sleep apnea'**
  String get onboarding_med_condition_sleep_apnea;

  /// No description provided for @onboarding_med_condition_chronic_fatigue.
  ///
  /// In en, this message translates to:
  /// **'Chronic fatigue syndrome'**
  String get onboarding_med_condition_chronic_fatigue;

  /// No description provided for @onboarding_med_condition_gerd.
  ///
  /// In en, this message translates to:
  /// **'GERD or acid reflux'**
  String get onboarding_med_condition_gerd;

  /// No description provided for @onboarding_med_condition_chronic_pain.
  ///
  /// In en, this message translates to:
  /// **'Chronic pain / fibromyalgia'**
  String get onboarding_med_condition_chronic_pain;

  /// No description provided for @onboarding_med_condition_arthritis.
  ///
  /// In en, this message translates to:
  /// **'Arthritis'**
  String get onboarding_med_condition_arthritis;

  /// Option label when no medical conditions apply
  ///
  /// In en, this message translates to:
  /// **'None of the above'**
  String get onboarding_med_condition_none;

  /// Action Step category label: Nutrition
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get action_step_category_nutrition;

  /// Action Step category label: Movement
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get action_step_category_movement;

  /// Action Step category label: Sleep
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get action_step_category_sleep;

  /// Action Step category label: Stress management
  ///
  /// In en, this message translates to:
  /// **'Stress management'**
  String get action_step_category_stress;

  /// Action Step category label: Social connection
  ///
  /// In en, this message translates to:
  /// **'Social connection'**
  String get action_step_category_social;

  /// No description provided for @actionStepSuccessCoachMessage.
  ///
  /// In en, this message translates to:
  /// **'Great job! You completed your Action Step—keep building momentum!'**
  String get actionStepSuccessCoachMessage;

  /// No description provided for @actionStepFailureCoachMessage.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry, tomorrow is a new opportunity. You\'ve got this!'**
  String get actionStepFailureCoachMessage;

  /// Snackbar shown when user attempts to submit a second PES entry on the same day
  ///
  /// In en, this message translates to:
  /// **'You\'ve already logged today\'s energy level. Try again tomorrow!'**
  String get pes_duplicate_entry_snackbar;

  /// Placeholder copy when no PES data is available for sparkline
  ///
  /// In en, this message translates to:
  /// **'Your energy trend will appear here after you log a few days.'**
  String get pes_trend_empty_state;

  /// Label for action-step completion button
  ///
  /// In en, this message translates to:
  /// **'I did it'**
  String get checkin_done_button;

  /// Label for action-step skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get checkin_skip_button;

  /// Status label when action step is completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get checkin_status_completed;

  /// Status label when action step is skipped
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get checkin_status_skipped;

  /// Status label when action step is pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get checkin_status_pending;

  /// Accessibility label for the "I did it" button
  ///
  /// In en, this message translates to:
  /// **'Mark today completed'**
  String get checkin_semantics_mark_completed;

  /// Accessibility label for the "Skip" button
  ///
  /// In en, this message translates to:
  /// **'Skip today'**
  String get checkin_semantics_skip_today;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return SEn();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
