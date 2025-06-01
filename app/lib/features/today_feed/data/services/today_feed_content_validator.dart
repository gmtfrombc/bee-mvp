import 'package:flutter/foundation.dart';
import '../../domain/models/today_feed_content.dart';
import 'today_feed_content_quality_models.dart';

/// Content validation service for format, readability, and engagement analysis
/// Part of the modular content quality system for Epic 1.3 Task T1.3.5.9
class TodayFeedContentValidator {
  // Validation thresholds
  static const double _minReadabilityScore = 0.6;
  static const double _minEngagementScore = 0.5;
  static const double _minFormatScore = 0.7;

  /// Validate content format and structure
  static FormatValidationResult validateFormat(TodayFeedContent content) {
    final issues = <String>[];
    final warnings = <String>[];
    double formatScore = 1.0;

    // Title validation
    if (content.title.isEmpty) {
      issues.add('Title is required');
      formatScore -= 0.5;
    } else if (content.title.length > 60) {
      issues.add('Title exceeds 60 character limit (${content.title.length})');
      formatScore -= 0.3;
    } else if (content.title.length < 10) {
      warnings.add('Title is short - consider expanding for better engagement');
      formatScore -= 0.1;
    }

    // Summary validation
    if (content.summary.isEmpty) {
      issues.add('Summary is required');
      formatScore -= 0.5;
    } else if (content.summary.length > 200) {
      issues.add(
        'Summary exceeds 200 character limit (${content.summary.length})',
      );
      formatScore -= 0.3;
    } else if (content.summary.length < 50) {
      warnings.add('Summary is short - consider expanding for clarity');
      formatScore -= 0.1;
    }

    // Check for proper punctuation
    if (content.summary.isNotEmpty &&
        !RegExp(r'[.!?]$').hasMatch(content.summary)) {
      warnings.add('Summary should end with proper punctuation');
      formatScore -= 0.05;
    }

    // Check for balanced content structure
    final titleWordCount = content.title.split(RegExp(r'\s+')).length;
    if (titleWordCount > 12) {
      warnings.add('Title is lengthy - consider making it more concise');
      formatScore -= 0.05;
    }

    // Check for appropriate capitalization
    if (content.title == content.title.toUpperCase()) {
      warnings.add('Title is all caps - consider proper title case');
      formatScore -= 0.05;
    }

    return FormatValidationResult(
      formatScore: formatScore.clamp(0.0, 1.0),
      issues: issues,
      warnings: warnings,
    );
  }

  /// Calculate readability score using simplified metrics
  static double calculateReadabilityScore(TodayFeedContent content) {
    final text = '${content.title} ${content.summary}';

    // Simple readability metrics
    final words = text.split(RegExp(r'\s+'));
    final sentences = text.split(RegExp(r'[.!?]+'));

    if (sentences.isEmpty || words.isEmpty) return 0.0;

    final avgWordsPerSentence = words.length / sentences.length;

    // Base score
    double score = 0.8;

    // Penalty for overly complex sentences
    if (avgWordsPerSentence > 20) score -= 0.3;
    if (avgWordsPerSentence > 25) score -= 0.2;

    // Bonus for good length
    if (avgWordsPerSentence >= 12 && avgWordsPerSentence <= 18) score += 0.2;

    // Check for complex words (>7 characters)
    final complexWords = words.where((word) => word.length > 7).length;
    final complexWordRatio = complexWords / words.length;

    if (complexWordRatio > 0.3) score -= 0.2;
    if (complexWordRatio > 0.5) score -= 0.3;

    // Bonus for good sentence variety
    final sentenceLengths =
        sentences
            .map((s) => s.split(RegExp(r'\s+')).length)
            .where((len) => len > 0)
            .toList();

    if (sentenceLengths.length > 1) {
      final avgLength =
          sentenceLengths.reduce((a, b) => a + b) / sentenceLengths.length;
      final variance =
          sentenceLengths
              .map((len) => (len - avgLength) * (len - avgLength))
              .reduce((a, b) => a + b) /
          sentenceLengths.length;

      if (variance > 4) score += 0.1; // Good sentence variety
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate engagement potential score
  static double calculateEngagementScore(TodayFeedContent content) {
    double score = 0.5; // Base score

    final title = content.title.toLowerCase();
    final summary = content.summary.toLowerCase();
    final combinedText = '$title $summary';

    // Engagement indicators
    final engagementWords = [
      'secret',
      'discover',
      'surprising',
      'amazing',
      'simple',
      'easy',
      'effective',
      'proven',
      'research',
      'study',
      'new',
      'breakthrough',
      'hidden',
      'revealed',
      'unlock',
      'powerful',
      'quick',
      'instant',
    ];

    for (final word in engagementWords) {
      if (combinedText.contains(word)) {
        score += 0.08;
      }
    }

    // Question marks indicate curiosity
    if (title.contains('?') || summary.contains('?')) score += 0.1;

    // Numbers often increase engagement
    if (RegExp(r'\d+').hasMatch(title)) score += 0.1;

    // Check for actionable language
    final actionWords = [
      'how to',
      'ways to',
      'tips',
      'tricks',
      'guide',
      'steps',
    ];
    for (final phrase in actionWords) {
      if (combinedText.contains(phrase)) {
        score += 0.1;
        break;
      }
    }

    // Personal pronouns increase engagement
    if (RegExp(r'\b(you|your|yourself)\b').hasMatch(combinedText)) {
      score += 0.08;
    }

    // Emotional words
    final emotionalWords = [
      'love',
      'hate',
      'fear',
      'worry',
      'excited',
      'frustrated',
      'happy',
      'sad',
      'angry',
      'surprised',
      'curious',
    ];

    for (final word in emotionalWords) {
      if (combinedText.contains(word)) {
        score += 0.05;
      }
    }

    // Penalty for overly complex language
    final avgWordLength =
        combinedText
            .split(RegExp(r'\s+'))
            .map((word) => word.length)
            .fold(0, (sum, length) => sum + length) /
        combinedText.split(RegExp(r'\s+')).length;

    if (avgWordLength > 6) score -= 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Validate content comprehensively
  static ContentValidationSummary validateContent(TodayFeedContent content) {
    final formatResult = validateFormat(content);
    final readabilityScore = calculateReadabilityScore(content);
    final engagementScore = calculateEngagementScore(content);

    final allIssues = <String>[];
    final allWarnings = <String>[];

    // Add format issues and warnings
    allIssues.addAll(formatResult.issues);
    allWarnings.addAll(formatResult.warnings);

    // Add readability issues
    if (readabilityScore < _minReadabilityScore) {
      allIssues.add(
        'Content readability below threshold (${readabilityScore.toStringAsFixed(2)})',
      );
    }

    // Add engagement warnings
    if (engagementScore < _minEngagementScore) {
      allWarnings.add(
        'Content engagement potential below optimal (${engagementScore.toStringAsFixed(2)})',
      );
    }

    // Calculate overall validation score
    final overallScore = _calculateOverallValidationScore(
      formatScore: formatResult.formatScore,
      readabilityScore: readabilityScore,
      engagementScore: engagementScore,
    );

    return ContentValidationSummary(
      isValid: allIssues.isEmpty && overallScore >= 0.7,
      overallScore: overallScore,
      formatResult: formatResult,
      readabilityScore: readabilityScore,
      engagementScore: engagementScore,
      issues: allIssues,
      warnings: allWarnings,
      recommendations: _generateValidationRecommendations(
        formatResult,
        readabilityScore,
        engagementScore,
        overallScore,
      ),
    );
  }

  /// Generate validation recommendations
  static List<String> _generateValidationRecommendations(
    FormatValidationResult formatResult,
    double readabilityScore,
    double engagementScore,
    double overallScore,
  ) {
    final recommendations = <String>[];

    if (formatResult.formatScore < _minFormatScore) {
      recommendations.add('Improve content format and structure');
    }

    if (readabilityScore < _minReadabilityScore) {
      recommendations.add(
        'Simplify language and sentence structure for better readability',
      );
    }

    if (engagementScore < _minEngagementScore) {
      recommendations.add(
        'Add more engaging elements like questions or actionable language',
      );
    }

    if (overallScore < 0.5) {
      recommendations.add(
        'Content requires significant improvement before publication',
      );
    } else if (overallScore < 0.7) {
      recommendations.add(
        'Consider minor improvements to enhance content quality',
      );
    } else if (overallScore >= 0.8) {
      recommendations.add('Content meets high quality standards');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Content validation completed successfully');
    }

    return recommendations;
  }

  /// Calculate overall validation score with weighted factors
  static double _calculateOverallValidationScore({
    required double formatScore,
    required double readabilityScore,
    required double engagementScore,
  }) {
    // Weighted scoring: format (40%), readability (35%), engagement (25%)
    return (formatScore * 0.4) +
        (readabilityScore * 0.35) +
        (engagementScore * 0.25);
  }
}

/// Content validation summary result
@immutable
class ContentValidationSummary {
  final bool isValid;
  final double overallScore;
  final FormatValidationResult formatResult;
  final double readabilityScore;
  final double engagementScore;
  final List<String> issues;
  final List<String> warnings;
  final List<String> recommendations;

  const ContentValidationSummary({
    required this.isValid,
    required this.overallScore,
    required this.formatResult,
    required this.readabilityScore,
    required this.engagementScore,
    required this.issues,
    required this.warnings,
    required this.recommendations,
  });
}
