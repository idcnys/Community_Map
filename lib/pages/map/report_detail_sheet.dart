
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_post_model.dart';
import '../../services/report_post_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReportDetailSheet extends StatefulWidget {
  final ReportPostModel report;
  final VoidCallback? onZoomToLocation;

  const ReportDetailSheet({super.key, required this.report, this.onZoomToLocation});

  @override
  State<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<ReportDetailSheet> {
  final _service = ReportPostService();
  bool _canSeeContact = false;
  bool _loadingContact = true;

  @override
  void initState() {
    super.initState();
    _checkContactVisibility();
  }

  Future<void> _checkContactVisibility() async {
    try {
      final myGroupIds = await _service.getMyGroupIds();
      final canSee =
          widget.report.canSeeContact(_service.currentUid, myGroupIds);
      if (mounted) {
        setState(() {
          _canSeeContact = canSee;
          _loadingContact = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingContact = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = widget.report;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Report type header
          Row(
            children: [
              Icon(
                report.isUrgent ? LucideIcons.alertTriangle : LucideIcons.alertTriangle,
                color: report.isUrgent ? theme.colorScheme.error : theme.colorScheme.tertiary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.reportType,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Reported by ${report.authorName}',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // Urgent badge
              if (report.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'URGENT',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Description
          if (report.description.isNotEmpty) ...[
            Text(
              'Description',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              report.description,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
          ],

          // Date & time
          _infoRow(
            LucideIcons.clock,
            'Reported',
            DateFormat('MMMM d, yyyy • h:mm a').format(report.createdAt),
          ),

          // Location
          _infoRow(
            LucideIcons.mapPin,
            'Location',
            '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
          ),

          // Contact number (conditional visibility)
          const SizedBox(height: 8),
          if (report.contactNumber.isNotEmpty) ...[
            if (_loadingContact)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Checking access...'),
              )
            else if (_canSeeContact)
              _infoRow(LucideIcons.phone, 'Contact', report.contactNumber)
            else
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(LucideIcons.lock,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'Contact hidden (group members only)',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 20),

          // Go to location button
          if (widget.onZoomToLocation != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onZoomToLocation,
                icon: const Icon(LucideIcons.crosshair, size: 18),
                label: const Text('Go to Location'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
