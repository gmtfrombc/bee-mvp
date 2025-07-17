/// Authentication-related validators consolidated for reuse.
///
/// Each function returns `null` when the input is valid, otherwise an error
/// string that can be fed directly to `TextFormField.validator`.
///
/// Very small email regex – not fully RFC-compliant but adequate for typical
/// sign-up forms.
///
final _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$');

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }

  if (!_emailRegex.hasMatch(value.trim())) {
    return 'Please enter a valid email address';
  }
  return null;
}

String? passwordValidator(String? value, {int minLength = 8}) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }

  if (value.length < minLength) {
    return 'Password must be at least $minLength characters';
  }
  return null;
}
