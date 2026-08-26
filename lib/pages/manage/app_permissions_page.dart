import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

/// Describes a permission the app uses.
class _PermEntry {
  final String label;
  final String description;
  final IconData icon;
  final Permission permission;

  const _PermEntry({
    required this.label,
    required this.description,
    required this.icon,
    required this.permission,
  });
}

class AppPermissionsPage extends StatefulWidget {
  const AppPermissionsPage({super.key});

  @override
  State<AppPermissionsPage> createState() => _AppPermissionsPageState();
}

class _AppPermissionsPageState extends State<AppPermissionsPage> {
  static const _permissions = [
    _PermEntry(
      label: 'লোকেশন',
      description: 'কাছাকাছি স্থান, রিপোর্ট এবং নেভিগেশনের জন্য ব্যবহৃত হয়।',
      icon: LucideIcons.mapPin,
      permission: Permission.locationWhenInUse,
    ),
    _PermEntry(
      label: 'মাইক্রোফোন',
      description: 'ভয়েস মেসেজ এবং অডিও রেকর্ডিংয়ের জন্য ব্যবহৃত হয়।',
      icon: LucideIcons.mic,
      permission: Permission.microphone,
    ),
    _PermEntry(
      label: 'বিজ্ঞপ্তি',
      description: 'সতর্কতা, উল্লেখ এবং গ্রুপ আপডেটের জন্য ব্যবহৃত হয়।',
      icon: LucideIcons.bell,
      permission: Permission.notification,
    ),
    _PermEntry(
      label: 'প্যাকেজ ইনস্টল',
      description: 'অ্যাপের ভেতরে আপডেট ইনস্টল করতে প্রয়োজন।',
      icon: LucideIcons.packageOpen,
      permission: Permission.requestInstallPackages,
    ),
  ];

  late Map<Permission, PermissionStatus> _statuses;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    final map = <Permission, PermissionStatus>{};
    // Query all permissions concurrently with a timeout to avoid hanging
    // on emulators without Google Play Services.
    final futures = _permissions.map((entry) async {
      try {
        final status = await entry.permission.status.timeout(
          const Duration(seconds: 3),
          onTimeout: () => PermissionStatus.denied,
        );
        map[entry.permission] = status;
      } catch (_) {
        map[entry.permission] = PermissionStatus.denied;
      }
    });
    await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      _statuses = map;
      _loading = false;
    });
  }

  Future<void> _requestPermission(Permission perm) async {
    PermissionStatus status;
    try {
      status = await perm.request().timeout(
        const Duration(seconds: 10),
        onTimeout: () => PermissionStatus.denied,
      );
    } catch (_) {
      status = PermissionStatus.denied;
    }
    if (!mounted) return;
    setState(() {
      _statuses[perm] = status;
    });

    // If permanently denied, open system settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      // Re-check after returning from settings
      await _loadStatuses();
    }
  }

  String _statusLabel(PermissionStatus status) {
    if (status.isGranted) return 'অনুমোদিত';
    if (status.isPermanentlyDenied) return 'স্থায়ীভাবে অস্বীকৃত';
    if (status.isDenied) return 'অনুমতি দেওয়া হয়নি';
    if (status.isRestricted) return 'সীমাবদ্ধ';
    if (status.isLimited) return 'আংশিক';
    return 'অজানা';
  }

  Color _statusColor(PermissionStatus status, ThemeData theme) {
    if (status.isGranted) return Colors.green;
    if (status.isPermanentlyDenied) return theme.colorScheme.error;
    if (status.isDenied) return theme.colorScheme.tertiary;
    return theme.colorScheme.onSurfaceVariant;
  }

  bool _canRequest(PermissionStatus status) {
    return status.isDenied || status == PermissionStatus.permanentlyDenied;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাপের অনুমতি')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatuses,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _permissions.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 72,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final entry = _permissions[index];
                  final status = _statuses[entry.permission] ??
                      PermissionStatus.denied;
                  final canReq = _canRequest(status);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: Icon(entry.icon,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Text(entry.label,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _statusColor(status, theme),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _statusLabel(status),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _statusColor(status, theme),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: canReq
                        ? FilledButton.tonal(
                            onPressed: () =>
                                _requestPermission(entry.permission),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              textStyle: theme.textTheme.labelSmall,
                            ),
                            child: Text(
                              status.isPermanentlyDenied
                                  ? 'সেটিংস খুলুন'
                                  : 'অনুমতি দিন',
                            ),
                          )
                        : null,
                    isThreeLine: true,
                  );
                },
              ),
            ),
    );
  }
}
