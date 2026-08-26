import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feed/feed_page.dart';
import 'map/map_page.dart';
import 'manage/manage_page.dart';
import '../../services/group_chat_service.dart';
import '../providers/guest_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentIndex = 0;
  final _chatService = GroupChatService();

  // Lazy-loaded pages: only build when first visited, then keep alive.
  final List<bool> _pageInitialized = [true, false, false];
  final List<Widget?> _pages = [const FeedPage(), null, null];

  @override
  void initState() {
    super.initState();
    // Update last active timestamp
    _chatService.updateLastActive();
  }

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
                  final isGuest = ref.read(isGuestProvider);
                  _pages[2] = isGuest ? const _GuestLockedPage() : const ManagePage();
              }
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.newspaper),
            selectedIcon: Icon(LucideIcons.newspaper),
            label: 'ফিড',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.map),
            selectedIcon: Icon(LucideIcons.map),
            label: 'ম্যাপ',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.settings),
            selectedIcon: Icon(LucideIcons.settings),
            label: 'ম্যানেজ',
          ),
        ],
      ),
    );
  }
}

class _GuestLockedPage extends StatelessWidget {
  const _GuestLockedPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ম্যানেজ'), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.lock, size: 64, color: theme.colorScheme.onSurfaceVariant.withAlpha(120)),
              const SizedBox(height: 20),
              Text(
                'সাইন ইন প্রয়োজন',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'গ্রুপ, প্রোফাইল এবং অনুরোধ পরিচালনা করতে একটি অ্যাকাউন্ট দিয়ে সাইন ইন করুন।',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
