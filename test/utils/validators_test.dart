import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/core/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('returns error for null', () {
      expect(validateEmail(null), 'Please enter your email');
    });

    test('returns error for empty string', () {
      expect(validateEmail(''), 'Please enter your email');
    });

    test('returns error for invalid email without @', () {
      expect(validateEmail('userexample.com'), 'Please enter a valid email');
    });

    test('returns error for invalid email without domain', () {
      expect(validateEmail('user@'), 'Please enter a valid email');
    });

    test('returns error for invalid email without TLD', () {
      expect(validateEmail('user@domain'), 'Please enter a valid email');
    });

    test('returns null for valid email', () {
      expect(validateEmail('user@example.com'), isNull);
    });

    test('returns null for email with subdomain', () {
      expect(validateEmail('user@mail.example.com'), isNull);
    });

    test('returns null for email with dots in local part', () {
      expect(validateEmail('first.last@example.com'), isNull);
    });
  });

  group('validatePassword', () {
    test('returns error for null', () {
      expect(validatePassword(null), 'Please enter your password');
    });

    test('returns error for empty string', () {
      expect(validatePassword(''), 'Please enter your password');
    });

    test('returns error for password shorter than 6 chars', () {
      expect(validatePassword('12345'), 'Password must be at least 6 characters');
    });

    test('returns null for exactly 6 chars', () {
      expect(validatePassword('123456'), isNull);
    });

    test('returns null for long password', () {
      expect(validatePassword('a' * 100), isNull);
    });
  });

  group('validateRequired', () {
    test('returns error for null', () {
      expect(validateRequired(null), 'This field is required');
    });

    test('returns error for empty string', () {
      expect(validateRequired(''), 'This field is required');
    });

    test('returns error for whitespace-only string', () {
      expect(validateRequired('   '), 'This field is required');
    });

    test('returns null for non-empty string', () {
      expect(validateRequired('hello'), isNull);
    });

    test('uses custom field name', () {
      expect(validateRequired(null, field: 'Title'), 'Title is required');
    });
  });

  group('validateName', () {
    test('returns error for null', () {
      expect(validateName(null), 'Please enter your full name');
    });

    test('returns error for empty string', () {
      expect(validateName(''), 'Please enter your full name');
    });

    test('returns error for name shorter than 3 chars', () {
      expect(validateName('ab'), 'Name must be at least 3 characters');
    });

    test('returns null for exactly 3 chars', () {
      expect(validateName('abc'), isNull);
    });

    test('returns null for normal name', () {
      expect(validateName('John Doe'), isNull);
    });
  });
}
