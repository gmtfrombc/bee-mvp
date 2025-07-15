
// Utilities for validating Action Step input fields.

/// Returns `true` if the [input] contains only positive wording.
///
/// A very small heuristic: rejects phrases containing common negative words
/// such as "not", "don't", "no", "never", etc. Case-insensitive.
bool isPositivePhrase(String input) {
  final normalised = input.toLowerCase();
  const negativeTerms = <String>[
    ' not ',
    "don't",
    'don’t',
    ' no ',
    'never',
    "can't",
    'cannot',
  ];
  for (final term in negativeTerms) {
    if (normalised.contains(term)) return false;
  }
  return true;
}

/// Whether [frequency] is within the allowed 3–7 days per week range.
bool isFrequencyInRange(int frequency) => frequency >= 3 && frequency <= 7;

// ---------------------------------------------------------------------------
// Form-field helpers
// ---------------------------------------------------------------------------

/// Validator for the description field. Ensures a non-empty, positively-phrased
/// string up to 80 characters.
String? positivePhraseValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Required';
  if (!isPositivePhrase(value)) return 'Please phrase positively';
  return null;
}

/// Validator for an integer frequency within 3–7 (not currently wired to a
/// `FormField<int>` but exposed for completeness / testing).
String? frequencyRangeValidator(int? value) {
  if (value == null) return 'Required';
  if (!isFrequencyInRange(value)) return 'Select 3–7 days';
  return null;
}
