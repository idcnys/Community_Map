import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/core/utils/validators.dart';

void main() {
  group('Email validation', () {
    test('valid email returns null', () {
      expect(validateEmail('user@example.com'), isNull);
      expect(validateEmail('a@b.co'), isNull);
      expect(validateEmail('test.name@domain.org'), isNull);
    });

    test('empty email returns error', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail(null), isNotNull);
    });

    test('invalid format returns error', () {
      expect(validateEmail('notanemail'), isNotNull);
      expect(validateEmail('@missing-local.com'), isNotNull);
      expect(validateEmail('missing@.com'), isNotNull);
      expect(validateEmail('no-at-sign'), isNotNull);
    });
  });

  group('Password validation', () {
    test('valid password returns null', () {
      expect(validatePassword('123456'), isNull);
      expect(validatePassword('a'.padRight(6, 'x')), isNull);
      expect(validatePassword('longpassword123'), isNull);
    });

    test('empty password returns error', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword(null), isNotNull);
    });

    test('short password returns error', () {
      expect(validatePassword('12345'), isNotNull);
      expect(validatePassword('abc'), isNotNull);
    });
  });

  group('Name validation', () {
    test('valid name returns null', () {
      expect(validateName('John Doe'), isNull);
      expect(validateName('Abc'), isNull); // exactly 3 chars
      expect(validateName('A longer name'), isNull);
    });

    test('empty name returns error', () {
      expect(validateName(''), isNotNull);
      expect(validateName(null), isNotNull);
    });

    test('short name returns error', () {
      expect(validateName('Ab'), isNotNull); // length 2 < 3
    });
  });

  group('Required field validation', () {
    test('non-empty returns null', () {
      expect(validateRequired('hello'), isNull);
      expect(validateRequired('  x  '), isNull);
    });

    test('empty or whitespace returns error', () {
      expect(validateRequired(''), isNotNull);
      expect(validateRequired(null), isNotNull);
      expect(validateRequired('   '), isNotNull);
    });

    test('custom field name in error message', () {
      final error = validateRequired('', field: 'Description');
      expect(error, contains('Description'));
    });
  });
}
