import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_providers.dart';
import '../../providers/service_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DiscoverGroupsTab extends ConsumerStatefulWidget {
  const DiscoverGroupsTab({super.key});

  @override
  ConsumerState<DiscoverGroupsTab> createState() => _DiscoverGroupsTabState();
}

class _DiscoverGroupsTabState extends ConsumerState<DiscoverGroupsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(searchGroupsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search groups...',
              prefixIcon: const Icon(LucideIcons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () {
                  _searchCtrl.clear();
                  ref.read(groupSearchQueryProvider.notifier).setQuery('');
                },
              ),
            ),
            onChanged: (val) {
              ref.read(groupSearchQueryProvider.notifier).setQuery(val);
            },
          ),
        ),
        Expanded(
          child: groupsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (allGroups) {
              final discoverGroups = allGroups
                  .where((g) => !g.members.contains(uid))
                  .toList();

              if (discoverGroups.isEmpty) {
                return Center(
                  child: Text(
                    'No groups to discover.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(searchGroupsProvider);
                  // Wait for the stream to emit new data
                  await ref.read(searchGroupsProvider.future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: discoverGroups.length,
                  itemBuilder: (context, index) {
                    final group = discoverGroups[index];
                    final hasRequested = group.pendingRequests.contains(uid);
                    final adminName = group.createdByName.isNotEmpty
                        ? group.createdByName
                        : 'Unknown';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row: icon + name + action button
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer.withAlpha(80),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    LucideIcons.compass,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    group.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                hasRequested
                                    ? OutlinedButton(
                                        onPressed: () => _cancelRequest(group.id),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          textStyle: const TextStyle(fontSize: 13),
                                        ),
                                        child: const Text('Requested'),
                                      )
                                    : FilledButton(
                                        onPressed: () => _sendRequest(group.id),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          textStyle: const TextStyle(fontSize: 13),
                                        ),
                                        child: const Text('Join'),
                                      ),
                              ],
                            ),
                            // Description (if any)
                            if (group.description.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                group.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // Meta row: admin + member count
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(LucideIcons.user, size: 13, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  adminName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Icon(LucideIcons.users, size: 13, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  '${group.memberCount} members',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _sendRequest(String groupId) async {
    final error = await ref.read(groupServiceProvider).sendJoinRequest(groupId);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _cancelRequest(String groupId) async {
    final error = await ref.read(groupServiceProvider).cancelJoinRequest(groupId);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
