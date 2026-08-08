import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/core/utils/time_ago.dart';

void main() {
  group('timeAgo', () {
    test('returns "Just now" for less than 1 minute', () {
      final now = DateTime.now();
      expect(timeAgo(now), 'Just now');
      expect(timeAgo(now.subtract(const Duration(seconds: 30))), 'Just now');
    });

    test('returns minutes for less than 1 hour', () {
      final date = DateTime.now().subtract(const Duration(minutes: 5));
      expect(timeAgo(date), '5m ago');
    });

    test('returns 59m for just under an hour', () {
      final date = DateTime.now().subtract(const Duration(minutes: 59));
      expect(timeAgo(date), '59m ago');
    });

    test('returns hours for less than 24 hours', () {
      final date = DateTime.now().subtract(const Duration(hours: 3));
      expect(timeAgo(date), '3h ago');
    });

    test('returns 23h for just under a day', () {
      final date = DateTime.now().subtract(const Duration(hours: 23));
      expect(timeAgo(date), '23h ago');
    });

    test('returns days for less than 7 days', () {
      final date = DateTime.now().subtract(const Duration(days: 2));
      expect(timeAgo(date), '2d ago');
    });

    test('returns 6d for just under a week', () {
      final date = DateTime.now().subtract(const Duration(days: 6, hours: 23));
      expect(timeAgo(date), '6d ago');
    });

    test('returns formatted date for 7+ days', () {
      final date = DateTime.now().subtract(const Duration(days: 10));
      final result = timeAgo(date);
      // Should be in "MMM d, h:mm a" format, not "Xd ago"
      expect(result, isNot(contains('d ago')));
      expect(result, matches(RegExp(r'[A-Z][a-z]{2} \d{1,2}, \d{1,2}:\d{2} [AP]M')));
    });
  });

  group('formatFullDate', () {
    test('formats date in full format', () {
      final date = DateTime(2025, 3, 15, 14, 30);
      final result = formatFullDate(date);
      expect(result, contains('March'));
      expect(result, contains('15'));
      expect(result, contains('2025'));
    });
  });

  group('formatShortDate', () {
    test('formats date in short format', () {
      final date = DateTime(2025, 3, 15, 14, 30);
      final result = formatShortDate(date);
      expect(result, contains('Mar'));
      expect(result, contains('15'));
    });
  });
}
