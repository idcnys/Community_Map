import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/models/report_post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  final baseDate = DateTime(2025, 6, 15, 12, 0);

  ReportPostModel makeReport({
    String origin = 'public',
    String status = 'active',
    DateTime? createdAt,
    Map<String, String> votes = const {},
    List<String> sharedGroupIds = const [],
    String authorId = 'author1',
  }) {
    return ReportPostModel(
      id: 'rpt1',
      reportType: 'Theft',
      description: 'Something stolen',
      latitude: 23.8103,
      longitude: 90.4125,
      authorId: authorId,
      authorName: 'Reporter',
      sharedGroupIds: sharedGroupIds,
      origin: origin,
      createdAt: createdAt ?? baseDate,
      status: status,
      votes: votes,
    );
  }

  group('ReportPostModel', () {
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = <String, dynamic>{
          'contactNumber': '01712345678',
          'reportType': 'Robbery',
          'description': 'Armed robbery',
          'latitude': 23.81,
          'longitude': 90.41,
          'authorId': 'u1',
          'authorName': 'User One',
          'sharedGroupIds': ['g1', 'g2'],
          'origin': 'urgent',
          'imageUrl': 'https://img.com/report.png',
          'audioUrl': 'https://audio.com/report.mp3',
          'createdAt': Timestamp.fromDate(baseDate),
          'status': 'active',
          'votes': {'u2': 'appropriate', 'u3': 'spam'},
          'viewCount': 42,
        };

        final report = ReportPostModel.fromMap('r1', map);

        expect(report.id, 'r1');
        expect(report.contactNumber, '01712345678');
        expect(report.reportType, 'Robbery');
        expect(report.latitude, 23.81);
        expect(report.longitude, 90.41);
        expect(report.sharedGroupIds, ['g1', 'g2']);
        expect(report.origin, 'urgent');
        expect(report.createdAt, baseDate);
        expect(report.votes['u2'], 'appropriate');
        expect(report.viewCount, 42);
      });

      test('uses defaults for missing fields', () {
        final report = ReportPostModel.fromMap('r2', {
          'createdAt': Timestamp.fromDate(baseDate),
        });

        expect(report.contactNumber, '');
        expect(report.reportType, 'other');
        expect(report.latitude, 0.0);
        expect(report.origin, 'public');
        expect(report.status, 'active');
        expect(report.votes, isEmpty);
        expect(report.viewCount, 0);
      });

      test('handles numeric latitude/longitude', () {
        final report = ReportPostModel.fromMap('r3', {
          'latitude': 23,
          'longitude': 90,
          'createdAt': Timestamp.fromDate(baseDate),
        });

        expect(report.latitude, 23.0);
        expect(report.longitude, 90.0);
      });
    });

    group('computed getters', () {
      test('isUrgent returns true for urgent origin', () {
        final report = makeReport(origin: 'urgent');
        expect(report.isUrgent, isTrue);
      });

      test('isUrgent returns false for public origin', () {
        final report = makeReport(origin: 'public');
        expect(report.isUrgent, isFalse);
      });

      test('isSolved returns true for solved status', () {
        final report = makeReport(status: 'solved');
        expect(report.isSolved, isTrue);
      });

      test('isSolved returns false for active status', () {
        final report = makeReport(status: 'active');
        expect(report.isSolved, isFalse);
      });

      test('isArchived returns true when solved', () {
        final report = makeReport(status: 'solved');
        expect(report.isArchived, isTrue);
      });

      test('isArchived returns true when older than 48 hours', () {
        final oldDate = DateTime.now().subtract(const Duration(hours: 49));
        final report = makeReport(createdAt: oldDate);
        expect(report.isArchived, isTrue);
      });

      test('isArchived returns false when recent and active', () {
        final recentDate = DateTime.now().subtract(const Duration(hours: 1));
        final report = makeReport(createdAt: recentDate);
        expect(report.isArchived, isFalse);
      });

      test('appropriateCount counts appropriate votes', () {
        final report = makeReport(votes: {
          'u1': 'appropriate',
          'u2': 'spam',
          'u3': 'appropriate',
        });
        expect(report.appropriateCount, 2);
      });

      test('spamCount counts spam votes', () {
        final report = makeReport(votes: {
          'u1': 'appropriate',
          'u2': 'spam',
          'u3': 'spam',
        });
        expect(report.spamCount, 2);
      });

      test('vote counts return 0 for empty votes', () {
        final report = makeReport();
        expect(report.appropriateCount, 0);
        expect(report.spamCount, 0);
      });
    });

    group('canSeeContact', () {
      test('author can always see contact', () {
        final report = makeReport(authorId: 'me', sharedGroupIds: []);
        expect(report.canSeeContact('me', []), isTrue);
      });

      test('user in shared group can see contact', () {
        final report = makeReport(
          authorId: 'other',
          sharedGroupIds: ['g1', 'g2'],
        );
        expect(report.canSeeContact('user1', ['g2', 'g3']), isTrue);
      });

      test('user not in shared group cannot see contact', () {
        final report = makeReport(
          authorId: 'other',
          sharedGroupIds: ['g1', 'g2'],
        );
        expect(report.canSeeContact('user1', ['g3', 'g4']), isFalse);
      });

      test('user with no groups cannot see contact', () {
        final report = makeReport(
          authorId: 'other',
          sharedGroupIds: ['g1'],
        );
        expect(report.canSeeContact('user1', []), isFalse);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final original = makeReport();
        final copied = original.copyWith(status: 'solved', viewCount: 99);

        expect(copied.status, 'solved');
        expect(copied.viewCount, 99);
        expect(copied.id, original.id);
        expect(copied.reportType, original.reportType);
      });

      test('preserves unchanged fields', () {
        final original = makeReport(votes: {'u1': 'appropriate'});
        final copied = original.copyWith(status: 'solved');

        expect(copied.votes, {'u1': 'appropriate'});
        expect(copied.createdAt, original.createdAt);
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        final report = makeReport();
        final map = report.toMap();

        expect(map['reportType'], 'Theft');
        expect(map['latitude'], 23.8103);
        expect(map['longitude'], 90.4125);
        expect(map['authorId'], 'author1');
        expect(map['status'], 'active');
        expect(map['createdAt'], baseDate);
      });
    });

    group('AuthorOwned mixin', () {
      test('hasAuthor returns true when authorId is set', () {
        final report = makeReport(authorId: 'u1');
        expect(report.hasAuthor, isTrue);
      });

      test('hasAuthor returns false when authorId is empty', () {
        final report = makeReport(authorId: '');
        expect(report.hasAuthor, isFalse);
      });
    });
  });

  group('ReportTypes', () {
    test('options contains expected types', () {
      expect(ReportTypes.options, contains('Theft'));
      expect(ReportTypes.options, contains('Robbery'));
      expect(ReportTypes.options, contains('Other'));
      expect(ReportTypes.options.length, 10);
    });

    test('urgentType is defined', () {
      expect(ReportTypes.urgentType, 'Urgent Emergency');
    });
  });
}
