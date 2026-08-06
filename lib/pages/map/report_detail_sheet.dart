
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_post_model.dart';
import '../../services/report_post_service.dart';

class ReportDetailSheet extends StatefulWidget {
  final ReportPostModel report;

  const ReportDetailSheet({super.key, required this.report});

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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Report type header
          Row(
            children: [
              Icon(
                report.isUrgent ? Icons.warning_amber : Icons.report_problem,
                color: report.isUrgent ? Colors.red : Colors.orange,
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
                      style: TextStyle(color: Colors.grey.shade600),
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.red.shade700,
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
                  ?.copyWith(color: Colors.grey.shade600),
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
            Icons.access_time,
            'Reported',
            DateFormat('MMMM d, yyyy • h:mm a').format(report.createdAt),
          ),

          // Location
          _infoRow(
            Icons.location_on,
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
              _infoRow(Icons.phone, 'Contact', report.contactNumber)
            else
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline,
                        size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      'Contact hidden (group members only)',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 16),
        ],
      ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
