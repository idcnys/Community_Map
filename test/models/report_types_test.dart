import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/models/report_post_model.dart';

void main() {
  group('ReportTypes', () {
    test('options is not empty', () {
      expect(ReportTypes.options, isNotEmpty);
    });

    test('options contains at least 10 types', () {
      expect(ReportTypes.options.length, greaterThanOrEqualTo(10));
    });

    test('urgentType is a separate constant not in options', () {
      expect(ReportTypes.options, isNot(contains(ReportTypes.urgentType)));
      expect(ReportTypes.urgentType, 'Urgent Emergency');
    });

    test('options are unique (no duplicates)', () {
      final unique = ReportTypes.options.toSet();
      expect(unique.length, ReportTypes.options.length);
    });

    test('all options are non-empty strings', () {
      for (final option in ReportTypes.options) {
        expect(option.trim(), isNotEmpty);
      }
    });

    test('urgentType is non-empty', () {
      expect(ReportTypes.urgentType.trim(), isNotEmpty);
    });
  });

  group('ReportPostModel', () {
    test('default constructor has sensible defaults', () {
      final report = ReportPostModel(createdAt: DateTime(2025, 1, 1));
      expect(report.id, '');
      expect(report.reportType, 'other');
      expect(report.imageUrl, '');
      expect(report.audioUrl, '');
      expect(report.sharedGroupIds, isEmpty);
      expect(report.viewCount, 0);
    });

    test('reportType can be set', () {
      final report = ReportPostModel(
        createdAt: DateTime(2025, 1, 1),
        reportType: ReportTypes.urgentType,
      );
      expect(report.reportType, ReportTypes.urgentType);
    });

    test('sharedGroupIds stores list', () {
      final report = ReportPostModel(
        createdAt: DateTime(2025, 1, 1),
        sharedGroupIds: const ['g1', 'g2'],
      );
      expect(report.sharedGroupIds, ['g1', 'g2']);
    });

    test('status defaults to active', () {
      final report = ReportPostModel(createdAt: DateTime(2025, 1, 1));
      expect(report.status, 'active');
    });

    test('votes defaults to empty map', () {
      final report = ReportPostModel(createdAt: DateTime(2025, 1, 1));
      expect(report.votes, isEmpty);
    });
  });
}
