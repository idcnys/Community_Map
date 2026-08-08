import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/models/community_post_model.dart';

void main() {
  group('CommunityPostModel', () {
    group('fromMap', () {
      test('parses all fields correctly', () {
        final now = DateTime(2025, 6, 15, 10, 30);
        final map = <String, dynamic>{
          'title': 'Test Post',
          'description': 'A test description',
          'authorId': 'user123',
          'authorName': 'Test User',
          'authorImageUrl': 'https://img.com/avatar.png',
          'originType': 'group',
          'groupId': 'grp456',
          'groupName': 'Test Group',
          'likeCount': 5,
          'commentCount': 3,
          'viewCount': 100,
          'repostCount': 1,
          'originalPostId': 'orig789',
          'originalAuthorName': 'Original Author',
          'imageUrl': 'https://img.com/post.png',
          'isPoll': true,
          'pollOptions': ['Option A', 'Option B'],
          'pollType': 'multiple',
          'pollVotes': {
            'Option A': ['user1', 'user2'],
            'Option B': ['user3'],
          },
          'createdAt': Timestamp.fromDate(now),
        };

        final post = CommunityPostModel.fromMap('post1', map);

        expect(post.id, 'post1');
        expect(post.title, 'Test Post');
        expect(post.description, 'A test description');
        expect(post.authorId, 'user123');
        expect(post.authorName, 'Test User');
        expect(post.originType, 'group');
        expect(post.groupId, 'grp456');
        expect(post.groupName, 'Test Group');
        expect(post.likeCount, 5);
        expect(post.commentCount, 3);
        expect(post.viewCount, 100);
        expect(post.repostCount, 1);
        expect(post.originalPostId, 'orig789');
        expect(post.isPoll, isTrue);
        expect(post.pollOptions, ['Option A', 'Option B']);
        expect(post.pollType, 'multiple');
        expect(post.pollVotes['Option A'], ['user1', 'user2']);
        expect(post.createdAt, now);
      });

      test('uses defaults for missing fields', () {
        final post = CommunityPostModel.fromMap('post2', {});

        expect(post.id, 'post2');
        expect(post.title, '');
        expect(post.description, '');
        expect(post.authorId, '');
        expect(post.originType, 'public');
        expect(post.groupName, 'Public');
        expect(post.likeCount, 0);
        expect(post.isPoll, isFalse);
        expect(post.pollOptions, isEmpty);
        expect(post.pollVotes, isEmpty);
      });
    });

    group('computed getters', () {
      test('isPublic returns true for public originType', () {
        final post = CommunityPostModel(originType: 'public');
        expect(post.isPublic, isTrue);
      });

      test('isPublic returns false for group originType', () {
        final post = CommunityPostModel(originType: 'group');
        expect(post.isPublic, isFalse);
      });

      test('isRepost returns true when originalPostId is set', () {
        final post = CommunityPostModel(originalPostId: 'orig1');
        expect(post.isRepost, isTrue);
      });

      test('isRepost returns false when originalPostId is empty', () {
        final post = CommunityPostModel();
        expect(post.isRepost, isFalse);
      });

      test('totalPollVotes sums all votes', () {
        final post = CommunityPostModel(pollVotes: {
          'A': ['u1', 'u2'],
          'B': ['u3'],
          'C': [],
        });
        expect(post.totalPollVotes, 3);
      });

      test('totalPollVotes returns 0 for empty votes', () {
        final post = CommunityPostModel();
        expect(post.totalPollVotes, 0);
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = CommunityPostModel(
          id: 'p1',
          title: 'Original',
          likeCount: 0,
        );

        final copied = original.copyWith(title: 'Updated', likeCount: 10);

        expect(copied.id, 'p1');
        expect(copied.title, 'Updated');
        expect(copied.likeCount, 10);
      });

      test('preserves unchanged fields', () {
        final original = CommunityPostModel(
          id: 'p1',
          title: 'Title',
          description: 'Desc',
          authorId: 'auth1',
        );

        final copied = original.copyWith(title: 'New Title');

        expect(copied.description, 'Desc');
        expect(copied.authorId, 'auth1');
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        final now = DateTime(2025, 6, 15);
        final post = CommunityPostModel(
          title: 'Test',
          authorId: 'u1',
          createdAt: now,
        );

        final map = post.toMap();

        expect(map['title'], 'Test');
        expect(map['authorId'], 'u1');
        expect(map['createdAt'], isA<Timestamp>());
      });

      test('uses FieldValue.serverTimestamp when createdAt is null', () {
        final post = CommunityPostModel(title: 'Test');
        final map = post.toMap();
        expect(map['createdAt'], isA<FieldValue>());
      });
    });
  });

  group('CommunityCommentModel', () {
    test('fromMap parses content field', () {
      final map = <String, dynamic>{
        'content': 'Hello world',
        'authorId': 'u1',
        'authorName': 'User',
        'parentId': 'post1',
        'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
      };

      final comment = CommunityCommentModel.fromMap('c1', map);

      expect(comment.id, 'c1');
      expect(comment.content, 'Hello world');
      expect(comment.parentId, 'post1');
    });

    test('fromMap falls back to text field', () {
      final map = <String, dynamic>{
        'text': 'Fallback text',
        'authorId': 'u1',
        'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
      };

      final comment = CommunityCommentModel.fromMap('c2', map);
      expect(comment.content, 'Fallback text');
    });

    test('fromMap falls back to reportId for parentId', () {
      final map = <String, dynamic>{
        'content': 'A comment',
        'reportId': 'rpt1',
        'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
      };

      final comment = CommunityCommentModel.fromMap('c3', map);
      expect(comment.parentId, 'rpt1');
    });
  });
}
