/**
 * Content Safety Validator for Daily Health Content
 * Validates generated content for medical accuracy and safety
 */

interface SafetyValidationResult {
  is_safe: boolean
  safety_score: number
  flagged_issues: string[]
  requires_review: boolean
  confidence_level: 'high' | 'medium' | 'low'
}

export class ContentSafetyValidator {
  // Medical red flags that should be flagged for review
  private static readonly MEDICAL_RED_FLAGS = [
    // Diagnosis claims
    'diagnose',
    'diagnosis',
    'you have',
    'condition is',
    'disease is',
    'disorder is',
    'syndrome is',
    'deficiency is',

    // Treatment claims
    'cure',
    'cures',
    'treatment for',
    'treats',
    'heal',
    'heals',
    'medicine for',
    'drug for',
    'prescription',

    // Medical advice
    'take medication',
    'stop taking',
    'increase dosage',
    'decrease dosage',
    'see a doctor immediately',
    'emergency room',
    'call 911',

    // Dangerous claims
    'guaranteed to',
    'proven to cure',
    'miracle cure',
    'instant relief',
    'no side effects',
    'completely safe',
    'FDA approved',
  ]

  // Wellness-focused positive indicators
  private static readonly WELLNESS_INDICATORS = [
    'consider consulting',
    'speak with your doctor',
    'healthcare professional',
    'general wellness',
    'lifestyle change',
    'healthy habit',
    'balanced approach',
    'gradual improvement',
    'sustainable practice',
    'evidence suggests',
    'research shows',
    'studies indicate',
  ]

  // Forbidden content types for health apps
  private static readonly FORBIDDEN_CONTENT = [
    'supplement recommendation',
    'specific dosage',
    'medical procedure',
    'surgery recommendation',
    'urgent medical',
    'serious condition',
    'life-threatening',
    'blood pressure medication',
    'heart medication',
  ]

  /**
   * Validate generated content for safety and medical accuracy
   */
  static validateContent(
    title: string,
    summary: string,
    topic_category: string,
  ): SafetyValidationResult {
    const content = `${title} ${summary}`.toLowerCase()

    let safety_score = 1.0
    const flagged_issues: string[] = []
    let requires_review = false

    // Check for medical red flags
    const red_flag_matches = this.MEDICAL_RED_FLAGS.filter((flag) =>
      content.includes(flag.toLowerCase())
    )

    if (red_flag_matches.length > 0) {
      safety_score -= 0.3 * red_flag_matches.length
      flagged_issues.push(`Medical red flags detected: ${red_flag_matches.join(', ')}`)
      requires_review = true
    }

    // Check for forbidden content types
    const forbidden_matches = this.FORBIDDEN_CONTENT.filter((forbidden) =>
      content.includes(forbidden.toLowerCase())
    )

    if (forbidden_matches.length > 0) {
      safety_score -= 0.5 * forbidden_matches.length
      flagged_issues.push(`Forbidden content detected: ${forbidden_matches.join(', ')}`)
      requires_review = true
    }

    // Check for wellness indicators (positive signals)
    const wellness_matches = this.WELLNESS_INDICATORS.filter((indicator) =>
      content.includes(indicator.toLowerCase())
    )

    if (wellness_matches.length > 0) {
      safety_score += 0.1 * Math.min(wellness_matches.length, 3) // Cap bonus
    }

    // Topic-specific validation
    const topic_issues = this.validateTopicSpecificContent(content, topic_category)
    if (topic_issues.length > 0) {
      safety_score -= 0.2
      flagged_issues.push(...topic_issues)
      requires_review = true
    }

    // Ensure score bounds
    safety_score = Math.max(0, Math.min(1, safety_score))

    // Determine confidence level
    let confidence_level: 'high' | 'medium' | 'low'
    if (safety_score >= 0.8 && flagged_issues.length === 0) {
      confidence_level = 'high'
    } else if (safety_score >= 0.6 && flagged_issues.length <= 2) {
      confidence_level = 'medium'
    } else {
      confidence_level = 'low'
    }

    return {
      is_safe: safety_score >= 0.6 && !requires_review,
      safety_score,
      flagged_issues,
      requires_review,
      confidence_level,
    }
  }

  /**
   * Topic-specific content validation
   */
  private static validateTopicSpecificContent(content: string, topic: string): string[] {
    const issues: string[] = []

    switch (topic) {
      case 'nutrition':
        if (content.includes('calorie restriction') || content.includes('extreme diet')) {
          issues.push('Potentially dangerous diet advice detected')
        }
        if (content.includes('supplement') && !content.includes('consult')) {
          issues.push('Supplement recommendation without medical consultation warning')
        }
        break

      case 'exercise':
        if (content.includes('intense workout') && !content.includes('gradually')) {
          issues.push('Potentially unsafe exercise intensity without progression warning')
        }
        if (content.includes('pain') && content.includes('push through')) {
          issues.push('Dangerous advice to exercise through pain')
        }
        break

      case 'sleep':
        if (content.includes('sleep medication') || content.includes('sleeping pill')) {
          issues.push('Sleep medication reference requires medical supervision')
        }
        break

      case 'stress':
        if (content.includes('anxiety medication') || content.includes('antidepressant')) {
          issues.push('Mental health medication reference detected')
        }
        break

      case 'prevention':
        if (content.includes('prevent disease') && !content.includes('may help reduce risk')) {
          issues.push('Disease prevention claims too definitive')
        }
        break
    }

    return issues
  }

  /**
   * Generate safe fallback content for flagged content
   */
  static generateSafeFallback(
    topic_category: string,
  ): { title: string; summary: string } {
    const safe_content: Record<string, { title: string; summary: string }> = {
      'nutrition': {
        title: 'Mindful Nutrition: Small Steps Matter',
        summary:
          'Consider adding one colorful vegetable to your meals today. Small, consistent changes in eating habits can support overall wellness over time.',
      },
      'exercise': {
        title: 'Movement for Wellness',
        summary:
          'Try a 5-minute walk or gentle stretch today. Regular movement, even in small amounts, can contribute to overall physical and mental wellbeing.',
      },
      'sleep': {
        title: 'Quality Rest for Better Days',
        summary:
          'Create a calming bedtime routine tonight. Consistent sleep habits may help improve how you feel during the day.',
      },
      'stress': {
        title: 'Managing Daily Stress',
        summary:
          'Take three deep breaths when you feel overwhelmed. Simple stress management techniques can help you navigate challenging moments.',
      },
      'prevention': {
        title: 'Healthy Habits for Wellness',
        summary:
          'Focus on one healthy habit today like drinking water or taking a short walk. Consistent healthy choices may support your overall wellbeing.',
      },
      'lifestyle': {
        title: 'Small Changes, Big Impact',
        summary:
          'Choose one small positive change to make today. Gradual lifestyle improvements can contribute to your overall sense of wellness.',
      },
    }

    return safe_content[topic_category] || safe_content['lifestyle']
  }
}
