
import 'package:flutter/material.dart';
import '../../services/report_post_service.dart';
import '../../models/report_post_model.dart';
import '../../core/utils/time_ago.dart';
import 'report_detail_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MapNotificationPanel extends StatelessWidget {
  const MapNotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ReportPostService();
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(LucideIcons.bellRing,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'সর্বশেষ রিপোর্ট',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    'সক্রিয়: < ৪৮ ঘণ্টা',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Reports list
            Expanded(
              child: StreamBuilder<List<ReportPostModel>>(
                stream: service.getLatestReports(limit: 20),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reports = snapshot.data ?? [];
                  if (reports.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.bell,
                              size: 64, color: theme.colorScheme.onSurfaceVariant.withAlpha(150)),
                          const SizedBox(height: 12),
                          Text(
                            'কোনো সক্রিয় রিপোর্ট নেই',
                            style: TextStyle(fontFamily: 'EkusheInter', color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: reports.length,
                    itemBuilder: (ctx, i) {
                      final report = reports[i];
                      return _buildReportTile(context, report);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportTile(BuildContext context, ReportPostModel report) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: report.isUrgent
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.tertiaryContainer,
        child: Icon(
          report.isUrgent ? LucideIcons.alertTriangle : LucideIcons.alertTriangle,
          color: report.isUrgent ? theme.colorScheme.error : theme.colorScheme.tertiary,
          size: 20,
        ),
      ),
      title: Text(
        report.reportType,
        style: const TextStyle(fontFamily: 'EkusheInter', fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            report.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'EkusheInter', fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            '${report.authorName} • ${_timeAgo(report.createdAt)}',
            style: TextStyle(fontFamily: 'EkusheInter', fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      trailing: report.isSolved
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'সমাধান',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : report.isUrgent
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'জরুরি',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
      onTap: () {
        Navigator.of(context).pop(); // close sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => ReportDetailSheet(report: report),
        );
      },
    );
  }

  String _timeAgo(DateTime date) {
    return timeAgo(date);
  }
}
