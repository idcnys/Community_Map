import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/github_issue_service.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  IssueLabel _selectedLabel = IssueLabel.bug;
  bool _submitting = false;
  String? _deviceInfo;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      String? device;
      if (kIsWeb) {
        // Web: no reliable device info; skip to avoid leaking browser fingerprint
        device = null;
      } else if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        // Only brand + model + Android major version. No serial, ID, or fingerprint.
        final brand = android.brand.isNotEmpty ? android.brand : 'Android';
        final model = android.model.isNotEmpty ? android.model : '';
        final sdkMajor = android.version.release.split('.').first;
        device = '$brand $model · Android $sdkMajor'.trim();
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        // Model name (e.g. "iPhone") + system major version. No identifierForVendor.
        final name = ios.name.isEmpty ? 'iOS' : ios.name;
        final major = ios.systemVersion.split('.').first;
        device = '$name · iOS $major';
      } else {
        // Desktop fallback
        final os = Platform.operatingSystem;
        final ver = Platform.operatingSystemVersion.split(' ').first;
        device = '$os $ver';
      }

      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
        _deviceInfo = device;
      });
    } catch (_) {
      // Non-fatal: issue can still be submitted without device info
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে একটি শিরোনাম লিখুন')),
      );
      return;
    }
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে সমস্যাটি বর্ণনা করুন')),
      );
      return;
    }

    setState(() => _submitting = true);

    final result = await GitHubIssueService().createIssue(
      title: title,
      body: body,
      label: _selectedLabel,
      deviceInfo: _deviceInfo,
      appVersion: _appVersion,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.circleCheckBig, size: 18,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('সমস্যা #${result.issueNumber} তৈরি হয়েছে!')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ব্যর্থ হয়েছে: ${result.error}'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('সমস্যা জানান'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type dropdown
            DropdownButtonFormField<IssueLabel>(
              initialValue: _selectedLabel,
              decoration: InputDecoration(
                labelText: 'ধরন',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: IssueLabel.values.map((label) {
                return DropdownMenuItem(
                  value: label,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconForLabel(label), size: 16),
                      const SizedBox(width: 8),
                      Text(label.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedLabel = v);
              },
            ),

            const SizedBox(height: 20),

            // Title field
            Text(
              'শিরোনাম',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'সমস্যার সংক্ষিপ্ত সারসংক্ষেপ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              textInputAction: TextInputAction.next,
              maxLength: 120,
            ),

            const SizedBox(height: 16),

            // Description field
            Text(
              'বর্ণনা',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyCtrl,
              decoration: InputDecoration(
                hintText: 'কী ঘটেছে, প্রত্যাশিত আচরণ, পুনরুৎপাদনের ধাপ বর্ণনা করুন…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.all(14),
              ),
              maxLines: 10,
              minLines: 5,
              textInputAction: TextInputAction.newline,
            ),

            const SizedBox(height: 16),

            // Auto-attached device info (single subtle line)
            if (_appVersion != null || _deviceInfo != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    if (_appVersion != null) 'v$_appVersion',
                    if (_deviceInfo != null) _deviceInfo,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Submit button (bottom)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.send, size: 18),
                label: Text(_submitting ? 'জমা দেওয়া হচ্ছে…' : 'সমস্যা তৈরি করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForLabel(IssueLabel label) {
    switch (label) {
      case IssueLabel.bug:
        return LucideIcons.bug;
      case IssueLabel.feature:
        return LucideIcons.lightbulb;
      case IssueLabel.question:
        return LucideIcons.circleHelp;
      case IssueLabel.crash:
        return LucideIcons.flame;
    }
  }
}
