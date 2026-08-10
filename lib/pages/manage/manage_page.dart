import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'my_groups_tab.dart';
import 'discover_groups_tab.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ManagePage extends StatelessWidget {
  const ManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage'),
          automaticallyImplyLeading: false,
          actions: [
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
