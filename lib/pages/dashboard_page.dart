import 'package:flutter/material.dart';
import 'feed/feed_page.dart';
import 'map/map_page.dart';
import 'manage/manage_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  // Lazy-loaded pages: only build when first visited, then keep alive.
  final List<bool> _pageInitialized = [true, false, false];
  final List<Widget?> _pages = [const FeedPage(), null, null];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _pages[0]!,
          _pages[1] ?? const SizedBox.shrink(),
          _pages[2] ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            // Lazy init: build page on first visit
            if (!_pageInitialized[index]) {
              _pageInitialized[index] = true;
              switch (index) {
                case 1:
                  _pages[1] = const MapPage();
                case 2:
                  _pages[2] = const ManagePage();
              }
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.newspaper),
            selectedIcon: Icon(LucideIcons.newspaper),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.map),
            selectedIcon: Icon(LucideIcons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.settings),
            selectedIcon: Icon(LucideIcons.settings),
            label: 'Manage',
          ),
        ],
      ),
    );
  }
}
