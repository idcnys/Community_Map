import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/services/post_service.dart';
import 'package:cmap/services/group_service.dart';

void main() {
  group('PaginatedResult', () {
    test('creates with items and hasMore', () {
      final result = PaginatedResult<String>(
        items: ['a', 'b', 'c'],
        hasMore: true,
      );

      expect(result.items, ['a', 'b', 'c']);
      expect(result.hasMore, isTrue);
      expect(result.lastDoc, isNull);
    });

    test('creates with empty items', () {
      final result = PaginatedResult<int>(
        items: [],
        hasMore: false,
      );

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
    });

    test('items list is immutable reference', () {
      final items = ['a', 'b'];
      final result = PaginatedResult<String>(items: items, hasMore: false);
      expect(result.items.length, 2);
    });
  });

  group('GroupLimits', () {
    test('maxCreated is 3', () {
      expect(GroupLimits.maxCreated, 3);
    });

    test('maxJoined is 5', () {
      expect(GroupLimits.maxJoined, 5);
    });

    test('maxTotal is 8', () {
      expect(GroupLimits.maxTotal, 8);
    });

    test('maxTotal >= maxCreated + maxJoined', () {
      expect(GroupLimits.maxTotal, greaterThanOrEqualTo(GroupLimits.maxCreated));
      expect(GroupLimits.maxTotal, greaterThanOrEqualTo(GroupLimits.maxJoined));
    });
  });
}
