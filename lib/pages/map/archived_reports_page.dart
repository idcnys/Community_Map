
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/report_post_service.dart';
import '../../models/report_post_model.dart';
import 'report_detail_sheet.dart';

class ArchivedReportsPage extends StatelessWidget {
  const ArchivedReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ReportPostService();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Archived Reports'),
            Text(
              'Reports older than 48 hours',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
                  Icon(Icons.archive_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No archived reports',
                    style: TextStyle(color: Colors.grey.shade600),
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
                        ? Icons.warning_amber
                        : Icons.report_problem,
                    color: report.isUrgent ? Colors.red : Colors.orange,
                  ),
                  title: Text(
                    report.reportType,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${report.authorName} • ${DateFormat('MMM d, h:mm a').format(report.createdAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
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
