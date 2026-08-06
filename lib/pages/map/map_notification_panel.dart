
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/report_post_service.dart';
import '../../models/report_post_model.dart';
import 'report_detail_sheet.dart';

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
                  Icon(Icons.notifications_active,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Latest Reports',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    'Active: < 48 hrs',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
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
                          Icon(Icons.notifications_none,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No active reports',
                            style: TextStyle(color: Colors.grey.shade600),
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
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: report.isUrgent
            ? Colors.red.shade50
            : Colors.orange.shade50,
        child: Icon(
          report.isUrgent ? Icons.warning_amber : Icons.report_problem,
          color: report.isUrgent ? Colors.red.shade700 : Colors.orange.shade700,
          size: 20,
        ),
      ),
      title: Text(
        report.reportType,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            report.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            '${report.authorName} • ${_timeAgo(report.createdAt)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
      trailing: report.isUrgent
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'URGENT',
                style: TextStyle(
                  color: Colors.red.shade700,
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
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(date);
  }
}
