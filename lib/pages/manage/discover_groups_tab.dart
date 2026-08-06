import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_providers.dart';
import '../../providers/service_providers.dart';

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
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
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
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: discoverGroups.length,
                itemBuilder: (context, index) {
                  final group = discoverGroups[index];
                  final hasRequested = group.pendingRequests.contains(uid);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.explore_outlined),
                      title: Text(group.name),
                      subtitle: Text(
                        '${group.memberCount} members${group.description.isNotEmpty ? '\n${group.description}' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: group.description.isNotEmpty,
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
