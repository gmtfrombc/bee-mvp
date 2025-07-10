/// Medical history conditions selectable during onboarding (Section 6).
///
/// Generated from `docs/MVP_ROADMAP/1-11 Onboarding/medical_history_survey.md`.
/// Each enum value represents a single checkbox option shown to the user.
/// Keep display labels in ARB localization files; the map below provides
/// English fall-backs for early development and unit testing.
///
/// This file purposefully avoids Flutter imports so that it can be reused in
/// models, services, and tests without additional dependencies.
library;

/// Enumeration of supported medical conditions.
enum MedicalCondition {
  // Metabolic & Cardiovascular Health
  prediabetes,
  type2Diabetes,
  hypertension, // High blood pressure
  highCholesterol,
  highTriglycerides,
  obesity,
  pcos, // Polycystic Ovary Syndrome
  fattyLiver, // Non-alcoholic fatty liver disease
  cardiovascularDisease,
  strokeOrTIA,

  // Mental & Emotional Health
  anxiety,
  depression,
  ptsd,
  bipolarDisorder,
  adhd,

  // Disordered Eating Patterns
  bingeEating,
  restrictiveEating,
  bulimia,
  anorexia,

  // Other Common Conditions
  thyroidDisorder,
  sleepApnea,
  chronicFatigueSyndrome,
  gerd,
  chronicPain,
  arthritis,

  // Special value representing no listed conditions
  none,
}

/// English display strings for each [MedicalCondition].
///
/// NOTE: These should be duplicated into ARB localization files and kept in
/// sync. The map is `const` to allow compile-time optimisation in tests.
const Map<MedicalCondition, String> kMedicalConditionLabels = {
  // Metabolic & Cardiovascular Health
  MedicalCondition.prediabetes: 'Prediabetes or insulin resistance',
  MedicalCondition.type2Diabetes: 'Type 2 diabetes',
  MedicalCondition.hypertension: 'High blood pressure (hypertension)',
  MedicalCondition.highCholesterol: 'High cholesterol',
  MedicalCondition.highTriglycerides: 'High triglycerides',
  MedicalCondition.obesity: 'Obesity',
  MedicalCondition.pcos: 'Polycystic Ovary Syndrome (PCOS)',
  MedicalCondition.fattyLiver: 'Fatty liver (NAFLD)',
  MedicalCondition.cardiovascularDisease: 'Cardiovascular disease',
  MedicalCondition.strokeOrTIA: 'Stroke or TIA',

  // Mental & Emotional Health
  MedicalCondition.anxiety: 'Anxiety',
  MedicalCondition.depression: 'Depression',
  MedicalCondition.ptsd: 'PTSD or trauma-related condition',
  MedicalCondition.bipolarDisorder: 'Bipolar disorder',
  MedicalCondition.adhd: 'ADHD',

  // Disordered Eating Patterns
  MedicalCondition.bingeEating: 'Binge eating',
  MedicalCondition.restrictiveEating: 'Restrictive eating / chronic dieting',
  MedicalCondition.bulimia: 'Bulimia or purging behaviors',
  MedicalCondition.anorexia: 'Anorexia or extremely low weight',

  // Other Common Conditions
  MedicalCondition.thyroidDisorder: 'Thyroid disorder',
  MedicalCondition.sleepApnea: 'Sleep apnea',
  MedicalCondition.chronicFatigueSyndrome: 'Chronic fatigue syndrome',
  MedicalCondition.gerd: 'GERD or acid reflux',
  MedicalCondition.chronicPain: 'Chronic pain / fibromyalgia',
  MedicalCondition.arthritis: 'Arthritis',

  // None
  MedicalCondition.none: 'None of the above',
};
