import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/models/group_model.dart';

void main() {
  final baseDate = DateTime(2025, 6, 15);

  group('GroupModel', () {
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = <String, dynamic>{
          'name': 'Neighborhood Watch',
          'description': 'Local safety group',
          'createdBy': 'u1',
          'createdByName': 'Admin User',
          'createdAt': Timestamp.fromDate(baseDate),
          'memberCount': 25,
          'members': ['u1', 'u2', 'u3'],
          'pendingRequests': ['u4', 'u5'],
        };

        final group = GroupModel.fromMap('g1', map);

        expect(group.id, 'g1');
        expect(group.name, 'Neighborhood Watch');
        expect(group.description, 'Local safety group');
        expect(group.createdBy, 'u1');
        expect(group.createdByName, 'Admin User');
        expect(group.createdAt, baseDate);
        expect(group.memberCount, 25);
        expect(group.members, ['u1', 'u2', 'u3']);
        expect(group.pendingRequests, ['u4', 'u5']);
      });

      test('uses defaults for missing fields', () {
        final group = GroupModel.fromMap('g2', {
          'createdAt': Timestamp.fromDate(baseDate),
        });

        expect(group.name, '');
        expect(group.description, '');
        expect(group.createdBy, '');
        expect(group.memberCount, 0);
        expect(group.members, isEmpty);
        expect(group.pendingRequests, isEmpty);
      });
    });

    group('computed getters', () {
      test('isPublic always returns true', () {
        final group = GroupModel(createdAt: baseDate);
        expect(group.isPublic, isTrue);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final original = GroupModel(
          id: 'g1',
          name: 'Original',
          createdAt: baseDate,
          memberCount: 5,
          members: ['u1'],
        );

        final copied = original.copyWith(
          name: 'Updated',
          memberCount: 10,
          members: ['u1', 'u2'],
        );

        expect(copied.name, 'Updated');
        expect(copied.memberCount, 10);
        expect(copied.members, ['u1', 'u2']);
        expect(copied.id, 'g1');
        expect(copied.createdAt, baseDate);
      });

      test('preserves unchanged fields', () {
        final original = GroupModel(
          id: 'g1',
          name: 'Test',
          description: 'Desc',
          createdBy: 'u1',
          createdAt: baseDate,
        );

        final copied = original.copyWith(name: 'New Name');

        expect(copied.description, 'Desc');
        expect(copied.createdBy, 'u1');
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        final group = GroupModel(
          name: 'Test Group',
          description: 'A group',
          createdBy: 'u1',
          createdByName: 'User',
          createdAt: baseDate,
          memberCount: 3,
          members: ['u1', 'u2', 'u3'],
          pendingRequests: ['u4'],
        );

        final map = group.toMap();

        expect(map['name'], 'Test Group');
        expect(map['memberCount'], 3);
        expect(map['members'], ['u1', 'u2', 'u3']);
        expect(map['pendingRequests'], ['u4']);
      });
    });
  });
}
