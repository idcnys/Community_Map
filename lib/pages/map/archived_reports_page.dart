
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/time_ago.dart';
import '../../providers/service_providers.dart';
import '../../models/report_post_model.dart';
import 'report_detail_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ArchivedReportsPage extends ConsumerWidget {
  const ArchivedReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final service = ref.read(reportPostServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('আর্কাইভকৃত রিপোর্টসমূহ'),
            Text(
              'সমাধান হয়েছে বা ৪৮ ঘণ্টার বেশি পুরনো',
              style: TextStyle(fontFamily: 'EkusheInter', fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
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
                    'কোনো আর্কাইভকৃত রিপোর্ট নেই',
                    style: TextStyle(fontFamily: 'EkusheInter', color: theme.colorScheme.onSurfaceVariant),
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
                    style: const TextStyle(fontFamily: 'EkusheInter', fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${report.authorName} • ${formatShortDate(report.createdAt)}',
                    style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 12),
                  ),
                  trailing: report.isSolved
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'সমাধান হয়েছে',
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
