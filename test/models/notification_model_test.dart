import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/models/notification_model.dart';

void main() {
  final baseDate = DateTime(2025, 6, 15, 10, 0);

  group('AppNotificationModel', () {
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = <String, dynamic>{
          'type': 'like',
          'targetUserId': 'user1',
          'actorId': 'user2',
          'actorName': 'Actor',
          'postId': 'post1',
          'postTitle': 'My Post',
          'message': 'liked your post',
          'read': true,
          'createdAt': Timestamp.fromDate(baseDate),
        };

        final notification = AppNotificationModel.fromMap('n1', map);

        expect(notification.id, 'n1');
        expect(notification.type, 'like');
        expect(notification.targetUserId, 'user1');
        expect(notification.actorId, 'user2');
        expect(notification.actorName, 'Actor');
        expect(notification.postId, 'post1');
        expect(notification.postTitle, 'My Post');
        expect(notification.message, 'liked your post');
        expect(notification.read, isTrue);
        expect(notification.createdAt, baseDate);
      });

      test('uses defaults for missing fields', () {
        final notification = AppNotificationModel.fromMap('n2', {});

        expect(notification.type, '');
        expect(notification.targetUserId, '');
        expect(notification.read, isFalse);
      });
    });

    group('copyWith', () {
      test('updates read status', () {
        final original = AppNotificationModel(
          id: 'n1',
          type: 'comment',
          message: 'test',
          read: false,
        );

        final copied = original.copyWith(read: true);

        expect(copied.read, isTrue);
        expect(copied.type, 'comment');
        expect(copied.message, 'test');
      });

      test('updates message', () {
        final original = AppNotificationModel(id: 'n1', message: 'old');
        final copied = original.copyWith(message: 'new');

        expect(copied.message, 'new');
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        final notification = AppNotificationModel(
          type: 'like',
          targetUserId: 'u1',
          actorId: 'u2',
          message: 'test',
          read: false,
          createdAt: baseDate,
        );

        final map = notification.toMap();

        expect(map['type'], 'like');
        expect(map['targetUserId'], 'u1');
        expect(map['read'], isFalse);
        expect(map['createdAt'], isA<Timestamp>());
      });

      test('uses FieldValue.serverTimestamp when createdAt is null', () {
        final notification = AppNotificationModel(type: 'like');
        final map = notification.toMap();
        expect(map['createdAt'], isA<FieldValue>());
      });
    });
  });
}
