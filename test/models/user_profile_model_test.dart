import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/models/user_profile_model.dart';

void main() {
  final baseDate = DateTime(2025, 1, 1);

  group('UserProfile', () {
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = <String, dynamic>{
          'fullName': 'John Doe',
          'email': 'john@example.com',
          'bio': 'Software developer',
          'phone': '01712345678',
          'location': 'Dhaka, Bangladesh',
          'dateOfBirth': '1995-05-15',
          'imageUrl': 'https://img.com/avatar.png',
          'bloodGroup': 'O+',
          'hobby': 'Reading',
          'createdAt': Timestamp.fromDate(baseDate),
        };

        final profile = UserProfile.fromMap('uid1', map);

        expect(profile.uid, 'uid1');
        expect(profile.fullName, 'John Doe');
        expect(profile.email, 'john@example.com');
        expect(profile.bio, 'Software developer');
        expect(profile.phone, '01712345678');
        expect(profile.location, 'Dhaka, Bangladesh');
        expect(profile.dateOfBirth, '1995-05-15');
        expect(profile.bloodGroup, 'O+');
        expect(profile.hobby, 'Reading');
        expect(profile.createdAt, baseDate);
      });

      test('uses defaults for missing fields', () {
        final profile = UserProfile.fromMap('uid2', {
          'createdAt': Timestamp.fromDate(baseDate),
        });

        expect(profile.fullName, '');
        expect(profile.email, '');
        expect(profile.bio, '');
        expect(profile.phone, '');
        expect(profile.bloodGroup, '');
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final original = UserProfile(
          uid: 'u1',
          fullName: 'Original',
          email: 'test@test.com',
          createdAt: baseDate,
        );

        final copied = original.copyWith(
          fullName: 'Updated',
          bio: 'New bio',
        );

        expect(copied.fullName, 'Updated');
        expect(copied.bio, 'New bio');
        expect(copied.uid, 'u1');
        expect(copied.email, 'test@test.com');
      });

      test('preserves uid and email (immutable)', () {
        final original = UserProfile(
          uid: 'u1',
          fullName: 'Test',
          email: 'test@test.com',
          createdAt: baseDate,
        );

        final copied = original.copyWith(fullName: 'Changed');

        expect(copied.uid, 'u1');
        expect(copied.email, 'test@test.com');
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        final profile = UserProfile(
          uid: 'u1',
          fullName: 'Test User',
          email: 'test@test.com',
          bio: 'A bio',
          createdAt: baseDate,
        );

        final map = profile.toMap();

        expect(map['fullName'], 'Test User');
        expect(map['email'], 'test@test.com');
        expect(map['bio'], 'A bio');
        expect(map['createdAt'], baseDate);
      });
    });
  });
}
