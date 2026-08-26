import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'my_groups_tab.dart';
import 'discover_groups_tab.dart';
import 'app_permissions_page.dart';
import 'app_update_page.dart';
import 'report_issue_page.dart';
import '../../services/app_update_service.dart';

class ManagePage extends StatefulWidget {
  const ManagePage({super.key});

  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  bool _updateAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    final info = await AppUpdateService().checkForUpdate();
    if (mounted) {
      setState(() {
        _updateAvailable = info != null;
      });
    }
  }

  void _openUpdatePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AppUpdatePage()),
    );
    // Re-check after returning from update page
    _checkUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('পরিচালনা'),
          automaticallyImplyLeading: false,
          actions: [
            // More menu: App Update + Report Issue
            PopupMenuButton<String>(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(LucideIcons.moreVertical),
                  if (_updateAvailable)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'আরও',
              onSelected: (value) {
                switch (value) {
                  case 'update':
                    _openUpdatePage();
                  case 'report':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportIssuePage()),
                    );
                  case 'permissions':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AppPermissionsPage()),
                    );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'update',
                  child: Row(
                    children: [
                      Icon(LucideIcons.download, size: 18,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 12),
                      Text(_updateAvailable ? 'অ্যাপ আপডেট •' : 'অ্যাপ আপডেট'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, size: 18,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 12),
                      const Text('সমস্যা জানান'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'permissions',
                  child: Row(
                    children: [
                      Icon(LucideIcons.shieldCheck, size: 18,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 12),
                      const Text('অনুমতি'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(LucideIcons.user),
              tooltip: 'প্রোফাইল',
              onPressed: () => context.push('/dashboard/profile'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'আমার গ্রুপ'),
              Tab(text: 'অনুসন্ধান'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MyGroupsTab(),
            DiscoverGroupsTab(),
          ],
        ),
      ),
    );
  }
}
