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
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(LucideIcons.compass),
                        title: Text(group.name),
                        subtitle: Text(
                          'Admin: $adminName\n${group.memberCount} members${group.description.isNotEmpty ? '\n${group.description}' : ''}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: hasRequested
                            ? OutlinedButton(
                                onPressed: () => _cancelRequest(group.id),
                                child: const Text('Requested'),
                              )
                            : FilledButton(
                                onPressed: () => _sendRequest(group.id),
                                child: const Text('Join'),
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
