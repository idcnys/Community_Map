import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_post_model.dart';
import '../../services/report_post_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ReportPostService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ReportPostModel>>(
        stream: service.getMyReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.fileX,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No reports yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportCard(
                report: report,
                service: service,
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final ReportPostModel report;
  final ReportPostService service;

  const _ReportCard({required this.report, required this.service});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _showComments = false;
  bool _solving = false;

  ReportPostModel get report => widget.report;
  ReportPostService get service => widget.service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: type + status badge
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: report.isSolved
                        ? Colors.green
                        : report.isUrgent
                            ? theme.colorScheme.error
                            : theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.reportType,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (report.isSolved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SOLVED',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  )
                else if (report.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'URGENT',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            if (report.description.isNotEmpty) ...[
              Text(
                report.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Date + location
            Row(
              children: [
                Icon(LucideIcons.clock,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(report.createdAt),
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                Icon(LucideIcons.mapPin,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Vote counts
            if (report.votes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(LucideIcons.thumbsUp,
                        size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('${report.appropriateCount} appropriate',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 12),
                    Icon(LucideIcons.flag,
                        size: 14, color: theme.colorScheme.error),
                    const SizedBox(width: 4),
                    Text('${report.spamCount} spam',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),

            // Comments toggle + section (single stream for both)
            _buildCommentsSection(theme),

            const SizedBox(height: 10),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Mark as Solved (only if not already solved)
                if (!report.isSolved) ...[
                  TextButton.icon(
                    onPressed: _solving ? null : () => _confirmSolve(context),
                    icon: _solving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.checkCircle, size: 16),
                    label: const Text('Solved'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                // Edit description
                TextButton.icon(
                  onPressed: () => _editDescription(context),
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                // Delete
                TextButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(ThemeData theme) {
    return StreamBuilder<List<ReportComment>>(
      stream: service.getComments(report.id),
      builder: (context, snapshot) {
        final comments = snapshot.data ?? [];
        final count = comments.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle row
            InkWell(
              onTap: () => setState(() => _showComments = !_showComments),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.messageCircle,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      count > 0
                          ? '$count comment${count > 1 ? 's' : ''}'
                          : 'No comments',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showComments
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            // Expanded comments list
            if (_showComments) ...[
              if (comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No comments yet.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Column(
                  children: comments
                      .map((c) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withAlpha(128),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      c.authorName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(c.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.text,
                                  style: const TextStyle(fontSize: 14, height: 1.3),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
            ],
          ],
        );
      },
    );
  }

  void _confirmSolve(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Solved'),
        content: const Text(
            'Mark this report as solved? It will be archived and no longer visible on the active map.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _solving = true);
              final error = await service.markAsSolved(report.id);
              if (mounted) {
                setState(() => _solving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Report marked as solved'),
                    backgroundColor: error != null ? Colors.red : null,
                  ),
                );
              }
            },
            child: const Text('Mark Solved'),
          ),
        ],
      ),
    );
  }

  void _editDescription(BuildContext context) {
    final controller = TextEditingController(text: report.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Description'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe the incident...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newDesc = controller.text.trim();
              Navigator.of(ctx).pop();
              final error =
                  await service.updateDescription(report.id, newDesc);
              if (context.mounted && error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text(
            'Are you sure you want to delete this report? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final error = await service.deleteReport(report.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Report deleted'),
                    backgroundColor: error != null ? Colors.red : null,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
