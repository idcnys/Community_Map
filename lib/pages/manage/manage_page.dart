import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'my_groups_tab.dart';
import 'discover_groups_tab.dart';
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
          title: const Text('Manage'),
          automaticallyImplyLeading: false,
          actions: [
            // Update button with optional badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.download),
                  tooltip: 'App Update',
                  onPressed: _openUpdatePage,
                ),
                if (_updateAvailable)
                  Positioned(
                    right: 6,
                    top: 6,
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
            IconButton(
              icon: const Icon(LucideIcons.bug),
              tooltip: 'Report Issue',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportIssuePage()),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.user),
              tooltip: 'Profile',
              onPressed: () => context.push('/dashboard/profile'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Groups'),
              Tab(text: 'Discover'),
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
