library;

/// Shared form validation logic.

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'আপনার ইমেইল লিখুন';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
    return 'সঠিক ইমেইল ঠিকানা লিখুন';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'আপনার পাসওয়ার্ড লিখুন';
  if (value.length < 6) return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
  return null;
}

String? validateRequired(String? value, {String field = 'এই ঘরটি'}) {
  if (value == null || value.trim().isEmpty) {
    return '$field অবশ্যই পূরণ করতে হবে';
  }
  return null;
}

String? validateName(String? value) {
  if (value == null || value.isEmpty) return 'আপনার পূর্ণ নাম লিখুন';
  if (value.trim().length < 3) return 'নাম কমপক্ষে ৩ অক্ষরের হতে হবে';
  return null;
}
