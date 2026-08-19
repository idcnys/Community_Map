import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_providers.dart';
import '../../providers/service_providers.dart';
import '../../services/group_service.dart';
import '../../services/group_chat_service.dart';
import '../../models/group_model.dart';
import 'group_detail_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MyGroupsTab extends ConsumerWidget {
  const MyGroupsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myJoinedGroupsProvider);
    final invitesAsync = ref.watch(myInvitesProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: groupsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (groups) {
              final invites = invitesAsync.value ?? [];

              if (groups.isEmpty && invites.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.users, size: 64, color: theme.colorScheme.onSurfaceVariant.withAlpha(150)),
                      const SizedBox(height: 12),
                      Text('No groups yet', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Join or create a group to get started.',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myJoinedGroupsProvider);
                  ref.invalidate(myInvitesProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Pending invites section
                    if (invites.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(LucideIcons.mailOpen, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Invites (${invites.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...invites.map((group) => _InviteTile(group: group)),
                      const SizedBox(height: 16),
                    ],
                    // My groups header
                    if (groups.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(LucideIcons.users, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'My Groups (${groups.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...groups.map((group) => _GroupTile(group: group)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCreateGroupDialog(context, ref),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Create New Group'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Create Group'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Group Name'),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Name must be at least 3 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Private Group'),
                  subtitle: Text(
                    isPrivate
                        ? 'Invite-only • Hidden from discover'
                        : 'Anyone can find and request to join',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: isPrivate,
                  onChanged: (v) => setModalState(() => isPrivate = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(ctx).pop();

                final error = await ref.read(groupServiceProvider).createGroup(
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  isPrivate: isPrivate,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Group created!')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual group tile with unread + pending badges.
class _GroupTile extends StatelessWidget {
  final GroupModel group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isAdmin = group.createdBy == uid;
    final chatService = GroupChatService();
    final pendingCount = group.pendingRequests.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(LucideIcons.users),
        title: Text(group.name),
        subtitle: Text(
          '${group.memberCount} members${isAdmin ? ' • Admin' : ''}${group.isPrivate ? ' • 🔒 Private' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Unread messages badge
            StreamBuilder<int>(
              stream: chatService.getUnreadCount(group.id),
              builder: (context, snapshot) {
                final unread = snapshot.data ?? 0;
                if (unread <= 0) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.messageCircle, size: 11, color: theme.colorScheme.onPrimary),
                      const SizedBox(width: 3),
                      Text(
                        unread > 99 ? '99+' : '$unread',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Pending requests badge (admin only)
            if (isAdmin && pendingCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.userPlus, size: 11, color: theme.colorScheme.onError),
                    const SizedBox(width: 3),
                    Text(
                      '$pendingCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onError,
                      ),
                    ),
                  ],
                ),
              ),
            if (!isAdmin)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'leave') _leaveGroup(context, group.id);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'leave', child: Text('Leave Group')),
                ],
              ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupDetailPage(groupId: group.id),
          ),
        ),
      ),
    );
  }

  void _leaveGroup(BuildContext context, String groupId) async {
    final service = GroupService();
    final error = await service.leaveGroup(groupId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

/// Invite tile — shows pending invite with Accept / Decline buttons.
class _InviteTile extends ConsumerWidget {
  final GroupModel group;
  const _InviteTile({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.mailOpen, size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Invited by ${group.createdByName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                group.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decline(ref, context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _accept(ref, context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _accept(WidgetRef ref, BuildContext context) async {
    final error = await ref.read(groupServiceProvider).acceptInvite(group.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Joined ${group.name}!')),
      );
    }
  }

  void _decline(WidgetRef ref, BuildContext context) async {
    final error = await ref.read(groupServiceProvider).declineInvite(group.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Invite declined')),
      );
    }
  }
}
