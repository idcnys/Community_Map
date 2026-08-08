
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/report_post_service.dart';
import '../../models/report_post_model.dart';
import 'report_detail_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ArchivedReportsPage extends StatelessWidget {
  const ArchivedReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ReportPostService();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Archived Reports'),
            Text(
              'Solved or older than 48 hours',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<ReportPostModel>>(
        stream: service.getArchivedReports(),
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
                  Icon(LucideIcons.archive,
                      size: 64, color: theme.colorScheme.onSurfaceVariant.withAlpha(150)),
                  const SizedBox(height: 16),
                  Text(
                    'No archived reports',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (ctx, i) {
              final report = reports[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    report.isUrgent
                        ? LucideIcons.alertTriangle
                        : LucideIcons.alertTriangle,
                    color: report.isUrgent ? theme.colorScheme.error : theme.colorScheme.tertiary,
                  ),
                  title: Text(
                    report.reportType,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${report.authorName} • ${DateFormat('MMM d, h:mm a').format(report.createdAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: report.isSolved
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'SOLVED',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ReportDetailSheet(report: report),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
