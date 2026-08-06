import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_providers.dart';
import '../../providers/service_providers.dart';

class RequestsTab extends ConsumerWidget {
  const RequestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myPendingRequestsProvider);
    final theme = Theme.of(context);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No pending requests', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Your join requests will appear here.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final group = requests[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.hourglass_top),
                title: Text(group.name),
                subtitle: Text('${group.memberCount} members'),
                trailing: OutlinedButton(
                  onPressed: () async {
                    final error = await ref
                        .read(groupServiceProvider)
                        .cancelJoinRequest(group.id);
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  },
                  child: const Text('Cancel'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
