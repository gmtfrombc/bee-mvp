import 'package:flutter/foundation.dart';
import '../../domain/models/today_feed_content.dart';
import 'today_feed_content_quality_models.dart';

/// Safety monitoring service for Today Feed content
/// Part of the modular content quality system for Epic 1.3 Task T1.3.5.9
class TodayFeedSafetyMonitor {
  // Safety thresholds
  static const double _minSafetyScore = 0.8;
  static const double _criticalSafetyThreshold = 0.6;

  /// Monitor content safety comprehensively
  static SafetyMonitoringResult monitorContentSafety(TodayFeedContent content) {
    try {
      final safetyChecks = <String, bool>{};
      final riskFactors = <String>[];
      final recommendations = <String>[];

      // Medical safety checks
      final medicalSafety = performMedicalSafetyChecks(content);
      safetyChecks['medical_safety'] = medicalSafety.isPassed;
      if (!medicalSafety.isPassed) {
        riskFactors.addAll(medicalSafety.riskFactors);
        recommendations.addAll(medicalSafety.recommendations);
      }

      // Content appropriateness checks
      final appropriatenessCheck = performAppropriatenessChecks(content);
      safetyChecks['appropriateness'] = appropriatenessCheck.isPassed;
      if (!appropriatenessCheck.isPassed) {
        riskFactors.addAll(appropriatenessCheck.riskFactors);
        recommendations.addAll(appropriatenessCheck.recommendations);
      }

      // Misinformation detection
      final misinformationCheck = detectMisinformation(content);
      safetyChecks['misinformation'] = misinformationCheck.isPassed;
      if (!misinformationCheck.isPassed) {
        riskFactors.addAll(misinformationCheck.riskFactors);
        recommendations.addAll(misinformationCheck.recommendations);
      }

      // Language appropriateness check
      final languageCheck = performLanguageAppropriatenessCheck(content);
      safetyChecks['language_appropriateness'] = languageCheck.isPassed;
      if (!languageCheck.isPassed) {
        riskFactors.addAll(languageCheck.riskFactors);
        recommendations.addAll(languageCheck.recommendations);
      }

      // Calculate overall safety score
      final safetyScore =
          safetyChecks.values.where((passed) => passed).length /
          safetyChecks.length;

      return SafetyMonitoringResult(
        contentId: content.id.toString(),
        safetyScore: safetyScore,
        safetyChecks: safetyChecks,
        riskFactors: riskFactors,
        recommendations: recommendations,
        isPassed: safetyScore >= _minSafetyScore && riskFactors.isEmpty,
        monitoredAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Content safety monitoring failed: $e');
      return SafetyMonitoringResult.error(
        contentId: content.id.toString(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Perform comprehensive medical safety checks
  static SafetyCheckResult performMedicalSafetyChecks(
    TodayFeedContent content,
  ) {
    final riskFactors = <String>[];
    final recommendations = <String>[];

    final text = '${content.title} ${content.summary}'.toLowerCase();

    // Prohibited medical terms
    final prohibitedTerms = [
      'diagnose',
      'diagnosis',
      'prescription',
      'prescribe',
      'cure',
      'cures',
      'treatment',
      'treat',
      'medicine',
      'medication',
      'drug',
      'dose',
      'dosage',
    ];

    for (final term in prohibitedTerms) {
      if (text.contains(term)) {
        riskFactors.add('Contains prohibited medical term: $term');
        recommendations.add(
          'Remove medical advice language and use educational tone',
        );
      }
    }

    // Check for directive medical language
    if (RegExp(r'you should|must|always|never').hasMatch(text)) {
      riskFactors.add(
        'Contains directive language that could be interpreted as medical advice',
      );
      recommendations.add('Use softer language like "consider" or "may help"');
    }

    // Check for inappropriate health claims
    final inappropriateClaims = [
      'prevents cancer',
      'cures diabetes',
      'eliminates depression',
      'fixes anxiety',
      'treats arthritis',
      'heals injuries',
      'stops pain',
      'reduces blood pressure',
      'lowers cholesterol',
    ];

    for (final claim in inappropriateClaims) {
      if (text.contains(claim)) {
        riskFactors.add('Contains inappropriate medical claim: $claim');
        recommendations.add('Replace with evidence-based, cautious language');
      }
    }

    // Check for missing appropriate cautious language
    final hasAppropriateTone = RegExp(
      r'consider|may help|research suggests|studies show|generally|typically|some people|might',
    ).hasMatch(text);

    if (!hasAppropriateTone && text.length > 100) {
      riskFactors.add(
        'Content lacks appropriate cautious language for health topics',
      );
      recommendations.add('Add appropriate disclaimers and cautious language');
    }

    // Check for missing consultation advice
    final hasConsultationAdvice = RegExp(
      r'consult|doctor|healthcare|physician|medical professional',
    ).hasMatch(text);

    if (!hasConsultationAdvice && text.length > 150) {
      recommendations.add(
        'Consider adding advice to consult healthcare professionals',
      );
    }

    return SafetyCheckResult(
      isPassed: riskFactors.isEmpty,
      riskFactors: riskFactors,
      recommendations: recommendations,
    );
  }

  /// Perform content appropriateness checks
  static SafetyCheckResult performAppropriatenessChecks(
    TodayFeedContent content,
  ) {
    final riskFactors = <String>[];
    final recommendations = <String>[];

    final text = '${content.title} ${content.summary}'.toLowerCase();

    // Check for inappropriate content
    final inappropriateTerms = [
      'extreme',
      'dangerous',
      'risky',
      'experimental',
      'illegal',
      'harmful',
      'toxic',
      'deadly',
    ];

    for (final term in inappropriateTerms) {
      if (text.contains(term)) {
        riskFactors.add('Contains potentially inappropriate term: $term');
        recommendations.add('Consider more balanced language');
      }
    }

    // Check for sensationalized language
    final sensationalTerms = [
      'shocking',
      'unbelievable',
      'incredible',
      'mind-blowing',
      'life-changing',
      'revolutionary',
      'miraculous',
    ];

    var sensationalCount = 0;
    for (final term in sensationalTerms) {
      if (text.contains(term)) {
        sensationalCount++;
      }
    }

    if (sensationalCount > 2) {
      riskFactors.add('Content contains excessive sensationalized language');
      recommendations.add('Use more measured, evidence-based language');
    }

    // Check for fear-based language
    final fearTerms = [
      'scary',
      'terrifying',
      'alarming',
      'shocking truth',
      'hidden danger',
      'urgent warning',
    ];

    for (final term in fearTerms) {
      if (text.contains(term)) {
        riskFactors.add('Contains fear-based language: $term');
        recommendations.add('Focus on positive, educational messaging');
      }
    }

    return SafetyCheckResult(
      isPassed: riskFactors.isEmpty,
      riskFactors: riskFactors,
      recommendations: recommendations,
    );
  }

  /// Detect potential misinformation
  static SafetyCheckResult detectMisinformation(TodayFeedContent content) {
    final riskFactors = <String>[];
    final recommendations = <String>[];

    final text = '${content.title} ${content.summary}'.toLowerCase();

    // Check for absolute claims without evidence
    if (RegExp(r'proven fact|absolutely|guaranteed|100%').hasMatch(text)) {
      riskFactors.add('Contains absolute claims that may lack evidence');
      recommendations.add(
        'Include appropriate qualifiers and evidence sources',
      );
    }

    // Check for conspiracy-related language
    final conspiracyTerms = [
      'big pharma',
      'cover-up',
      'they don\'t want you to know',
      'secret cure',
      'hidden truth',
    ];

    for (final term in conspiracyTerms) {
      if (text.contains(term)) {
        riskFactors.add('Contains conspiracy-related language: $term');
        recommendations.add('Focus on evidence-based information');
      }
    }

    // Check for unsupported superlatives
    final superlatives = [
      'best',
      'worst',
      'most effective',
      'only way',
      'always works',
      'never fails',
    ];

    var superlativeCount = 0;
    for (final term in superlatives) {
      if (text.contains(term)) {
        superlativeCount++;
      }
    }

    if (superlativeCount > 1) {
      riskFactors.add('Contains excessive unsupported superlative claims');
      recommendations.add('Use more qualified, evidence-based language');
    }

    return SafetyCheckResult(
      isPassed: riskFactors.isEmpty,
      riskFactors: riskFactors,
      recommendations: recommendations,
    );
  }

  /// Perform language appropriateness check
  static SafetyCheckResult performLanguageAppropriatenessCheck(
    TodayFeedContent content,
  ) {
    final riskFactors = <String>[];
    final recommendations = <String>[];

    final text = '${content.title} ${content.summary}'.toLowerCase();

    // Check for technical jargon without explanation
    final technicalTerms = [
      'bioavailability',
      'pharmacokinetics',
      'homeostasis',
      'metabolism',
      'neurotransmitter',
      'antioxidant',
    ];

    var jargonCount = 0;
    for (final term in technicalTerms) {
      if (text.contains(term)) {
        jargonCount++;
      }
    }

    if (jargonCount > 2) {
      riskFactors.add(
        'Contains excessive technical jargon without explanation',
      );
      recommendations.add(
        'Simplify language or provide explanations for technical terms',
      );
    }

    // Check for inclusive language
    final exclusiveTerms = [
      'normal people',
      'everyone knows',
      'obviously',
      'of course',
      'naturally',
    ];

    for (final term in exclusiveTerms) {
      if (text.contains(term)) {
        recommendations.add('Consider more inclusive language');
        break;
      }
    }

    return SafetyCheckResult(
      isPassed: riskFactors.isEmpty,
      riskFactors: riskFactors,
      recommendations: recommendations,
    );
  }

  /// Validate content safety comprehensively
  static Future<SafetyValidationResult> validateContentSafety(
    TodayFeedContent content,
  ) async {
    final monitoringResult = monitorContentSafety(content);

    return SafetyValidationResult(
      safetyScore: monitoringResult.safetyScore,
      issues: monitoringResult.riskFactors,
      warnings: monitoringResult.recommendations,
    );
  }

  /// Check if content requires immediate review based on safety
  static bool requiresImmediateReview(SafetyMonitoringResult result) {
    return result.safetyScore < _criticalSafetyThreshold ||
        result.riskFactors.isNotEmpty;
  }

  /// Generate safety summary for content
  static SafetySummary generateSafetySummary(SafetyMonitoringResult result) {
    final overallRisk =
        result.safetyScore < _criticalSafetyThreshold
            ? SafetyRiskLevel.high
            : result.safetyScore < _minSafetyScore
            ? SafetyRiskLevel.medium
            : SafetyRiskLevel.low;

    return SafetySummary(
      riskLevel: overallRisk,
      safetyScore: result.safetyScore,
      totalChecks: result.safetyChecks.length,
      passedChecks: result.safetyChecks.values.where((passed) => passed).length,
      riskFactorCount: result.riskFactors.length,
      requiresReview: requiresImmediateReview(result),
      summary: _generateSafetySummaryText(result, overallRisk),
    );
  }

  /// Generate safety summary text
  static String _generateSafetySummaryText(
    SafetyMonitoringResult result,
    SafetyRiskLevel riskLevel,
  ) {
    switch (riskLevel) {
      case SafetyRiskLevel.low:
        return 'Content meets safety standards and is appropriate for publication.';
      case SafetyRiskLevel.medium:
        return 'Content has minor safety concerns that should be addressed.';
      case SafetyRiskLevel.high:
        return 'Content has significant safety issues and requires immediate review.';
    }
  }
}

/// Safety risk levels for content assessment
enum SafetyRiskLevel { low, medium, high }

/// Safety summary result
@immutable
class SafetySummary {
  final SafetyRiskLevel riskLevel;
  final double safetyScore;
  final int totalChecks;
  final int passedChecks;
  final int riskFactorCount;
  final bool requiresReview;
  final String summary;

  const SafetySummary({
    required this.riskLevel,
    required this.safetyScore,
    required this.totalChecks,
    required this.passedChecks,
    required this.riskFactorCount,
    required this.requiresReview,
    required this.summary,
  });
}
