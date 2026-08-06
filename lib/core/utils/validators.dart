library;

/// Shared form validation logic.

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Please enter your email';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
    return 'Please enter a valid email';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Please enter your password';
  if (value.length < 6) return 'Password must be at least 6 characters';
  return null;
}

String? validateRequired(String? value, {String field = 'This field'}) {
  if (value == null || value.trim().isEmpty) return '$field is required';
  return null;
}

String? validateName(String? value) {
  if (value == null || value.isEmpty) return 'Please enter your full name';
  if (value.trim().length < 3) return 'Name must be at least 3 characters';
  return null;
}
