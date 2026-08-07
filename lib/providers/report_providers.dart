import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_post_model.dart';
import 'service_providers.dart';

/// Active reports (within 48 hours, not solved) for the map.
final activeReportsProvider = StreamProvider<List<ReportPostModel>>((ref) {
  final service = ref.watch(reportPostServiceProvider);
  return service.getActiveReports();
});

/// Archived reports.
final archivedReportsProvider = StreamProvider<List<ReportPostModel>>((ref) {
  final service = ref.watch(reportPostServiceProvider);
  return service.getArchivedReports();
});

/// User's own reports.
final myReportsProvider = StreamProvider<List<ReportPostModel>>((ref) {
  final service = ref.watch(reportPostServiceProvider);
  return service.getMyReports();
});

/// Whether user has an active report (for anti-spam cooldown).
/// Solved reports don't count as active.
final hasActiveReportProvider = Provider<bool>((ref) {
  final myReports = ref.watch(myReportsProvider).value ?? [];
  final cutoff = DateTime.now().subtract(const Duration(hours: 48));
  return myReports.any((r) => r.createdAt.isAfter(cutoff) && !r.isSolved);
});

/// Latest reports for notification panel.
final latestReportsProvider = StreamProvider<List<ReportPostModel>>((ref) {
  final service = ref.watch(reportPostServiceProvider);
  return service.getLatestReports();
});
