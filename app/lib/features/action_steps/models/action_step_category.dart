enum ActionStepCategory { nutrition, movement, sleep, stress, social }

extension ActionStepCategoryX on ActionStepCategory {
  /// Corresponding localization key in `intl_en.arb`.
  String get localizationKey {
    switch (this) {
      case ActionStepCategory.nutrition:
        return 'action_step_category_nutrition';
      case ActionStepCategory.movement:
        return 'action_step_category_movement';
      case ActionStepCategory.sleep:
        return 'action_step_category_sleep';
      case ActionStepCategory.stress:
        return 'action_step_category_stress';
      case ActionStepCategory.social:
        return 'action_step_category_social';
    }
  }
}
