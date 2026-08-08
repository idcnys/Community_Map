import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/models/model_extensions.dart';

void main() {
  group('FirestoreMapX', () {
    group('parseTimestamp', () {
      test('parses Timestamp correctly', () {
        final date = DateTime(2025, 6, 15, 10, 30);
        final map = <String, dynamic>{
          'createdAt': Timestamp.fromDate(date),
        };

        expect(map.parseTimestamp('createdAt'), date);
      });

      test('returns fallback when key is missing', () {
        final fallback = DateTime(2025, 1, 1);
        final map = <String, dynamic>{};

        expect(map.parseTimestamp('createdAt', fallback: fallback), fallback);
      });

      test('returns DateTime.now() when key missing and no fallback', () {
        final map = <String, dynamic>{};
        final result = map.parseTimestamp('createdAt');

        // Should be very close to now
        expect(
          DateTime.now().difference(result).inSeconds,
          lessThan(2),
        );
      });

      test('returns fallback when value is not a Timestamp', () {
        final fallback = DateTime(2025, 1, 1);
        final map = <String, dynamic>{
          'createdAt': 'not a timestamp',
        };

        expect(map.parseTimestamp('createdAt', fallback: fallback), fallback);
      });

      test('returns fallback when value is null', () {
        final fallback = DateTime(2025, 1, 1);
        final map = <String, dynamic>{
          'createdAt': null,
        };

        expect(map.parseTimestamp('createdAt', fallback: fallback), fallback);
      });
    });

    group('toTimestampValue', () {
      test('converts DateTime to Timestamp', () {
        final date = DateTime(2025, 6, 15);
        final map = <String, dynamic>{};
        final result = map.toTimestampValue(date);

        expect(result, isA<Timestamp>());
        expect((result as Timestamp).toDate(), date);
      });

      test('returns FieldValue.serverTimestamp for null', () {
        final map = <String, dynamic>{};
        final result = map.toTimestampValue(null);

        expect(result, isA<FieldValue>());
      });
    });
  });

  group('AuthorOwned mixin', () {
    test('hasAuthor is true with non-empty authorId', () {
      final obj = _TestAuthorOwned(authorId: 'u1', authorName: 'User');
      expect(obj.hasAuthor, isTrue);
    });

    test('hasAuthor is false with empty authorId', () {
      final obj = _TestAuthorOwned(authorId: '', authorName: 'User');
      expect(obj.hasAuthor, isFalse);
    });
  });
}

class _TestAuthorOwned with AuthorOwned {
  @override
  final String authorId;
  @override
  final String authorName;

  _TestAuthorOwned({required this.authorId, required this.authorName});
}
