// Utilities for validating Action Step input fields.

/// Returns `true` if the [input] contains only positive wording.
/// Rejects phrases with common negative words (case-insensitive).
bool isPositivePhrase(String input) {
  final text = input.toLowerCase();
  const negatives = <String>[
    ' not ',
    "don't",
    'don’t',
    ' no ',
    'never',
    "can't",
    'cannot',
  ];
  return negatives.every((neg) => !text.contains(neg));
}

/// Whether [frequency] is within the allowed 3–7 range.
bool isFrequencyInRange(int frequency) => frequency >= 3 && frequency <= 7;

// ---------------------------------------------------------------------------
// Form-field helpers
// ---------------------------------------------------------------------------

/// Validator for the description field – ensures non-empty & positive.
String? positivePhraseValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Required';
  if (!isPositivePhrase(value)) return 'Please phrase positively';
  return null;
}

/// Validator for frequency chips (3–7).
String? frequencyRangeValidator(int? value) {
  if (value == null) return 'Required';
  if (!isFrequencyInRange(value)) return 'Select 3–7 days';
  return null;
}
