import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/service_providers.dart';

import '../../models/group_model.dart';
import '../../core/utils/time_ago.dart';
import 'group_chat_page.dart';
import 'group_invite_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  final _firestore = FirebaseFirestore.instance;
  final Map<String, String> _nameCache = {};
  final Map<String, String> _memberAvatars = {};
  final Map<String, DateTime?> _lastActiveCache = {};

  Future<Map<String, dynamic>> _resolveMemberInfo(String uid) async {
    if (_nameCache.containsKey(uid) && _memberAvatars.containsKey(uid) && _lastActiveCache.containsKey(uid)) {
      return {'name': _nameCache[uid]!, 'avatar': _memberAvatars[uid]!, 'lastActive': _lastActiveCache[uid]};
    }
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      final name = (data?['fullName'] as String?) ?? 'Unknown User';
      final imageUrl = (data?['imageUrl'] as String?) ?? '';
      final ts = data?['lastActive'] as Timestamp?;
      final lastActive = ts?.toDate();
      _nameCache[uid] = name;
      _memberAvatars[uid] = imageUrl;
      _lastActiveCache[uid] = lastActive;
      return {'name': name, 'avatar': imageUrl, 'lastActive': lastActive};
    } catch (_) {
      return {'name': 'Unknown User', 'avatar': '', 'lastActive': null};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: StreamBuilder<GroupModel?>(
        stream: ref.read(groupServiceProvider).getGroupById(widget.groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final group = snapshot.data;
          if (group == null) {
            return const Center(child: Text('Group not found.'));
          }

          final isAdmin = group.createdBy == uid;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Group info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(group.name, style: theme.textTheme.titleLarge),
                          ),
                          if (isAdmin)
                            IconButton(
                              icon: const Icon(LucideIcons.pencil, size: 18),
                              tooltip: 'Edit group',
                              onPressed: () => _showEditDialog(group),
                            ),
                        ],
                      ),
                      if (group.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(group.description, style: TextStyle(color: theme.colorScheme.onSurface)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${group.memberCount} members \u2022 Created by ${group.createdByName}',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                          if (group.isPrivate) ...[
                            const SizedBox(width: 8),
                            Icon(LucideIcons.lock, size: 12, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text('Private', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Group Chat button
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GroupChatPage(groupId: widget.groupId, groupName: group.name),
                  ));
                },
                icon: const Icon(LucideIcons.messageCircle, size: 18),
                label: const Text('Group Chat'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              const SizedBox(height: 10),

              // Invite button (admin of private group only)
              if (isAdmin && group.isPrivate)
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GroupInvitePage(group: group),
                  )),
                  icon: const Icon(LucideIcons.userPlus, size: 18),
                  label: const Text('Invite Members'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              const SizedBox(height: 16),

              // Pending invites (admin of private group)
              if (isAdmin && group.isPrivate && group.invites.isNotEmpty) ...[
                Text(
                  'Pending Invites (${group.invites.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...group.invites.map((inviteUid) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: const Icon(LucideIcons.mail),
                      title: FutureBuilder<Map<String, dynamic>>(
                        future: _resolveMemberInfo(inviteUid),
                        builder: (ctx, infoSnap) => Text(
                          (infoSnap.data?['name'] as String?) ?? 'Loading...',
                        ),
                      ),
                      subtitle: const Text('Invite pending'),
                      trailing: IconButton(
                        icon: Icon(LucideIcons.x, color: theme.colorScheme.error),
                        tooltip: 'Cancel invite',
                        onPressed: () => _cancelInvite(inviteUid),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Pending requests (admin only, public groups)
              if (isAdmin && group.pendingRequests.isNotEmpty) ...[
                Text(
                  'Pending Requests (${group.pendingRequests.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...group.pendingRequests.map((requestUid) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: const Icon(LucideIcons.userPlus),
                      title: FutureBuilder<Map<String, dynamic>>(
                        future: _resolveMemberInfo(requestUid),
                        builder: (ctx, infoSnap) => Text(
                          (infoSnap.data?['name'] as String?) ?? 'Loading...',
                        ),
                      ),
                      subtitle: const Text('Wants to join'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(LucideIcons.checkCircle, color: theme.colorScheme.primary),
                            tooltip: 'Approve',
                            onPressed: () => _approve(context, widget.groupId, requestUid),
                          ),
                          IconButton(
                            icon: Icon(LucideIcons.xCircle, color: theme.colorScheme.error),
                            tooltip: 'Reject',
                            onPressed: () => _reject(context, widget.groupId, requestUid),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Members list
              Text(
                'Members (${group.members.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...group.members.map((memberUid) {
                final isOwner = memberUid == group.createdBy;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _resolveMemberInfo(memberUid),
                    builder: (ctx, infoSnap) {
                      final info = infoSnap.data;
                      final name = (info?['name'] as String?) ?? 'Loading...';
                      final avatarUrl = (info?['avatar'] as String?) ?? '';
                      final lastActive = info?['lastActive'] as DateTime?;
                      final activeText = lastActive != null
                          ? 'Active ${timeAgo(lastActive)}'
                          : 'No activity recorded';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: (avatarUrl.isNotEmpty)
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Icon(LucideIcons.user, size: 20),
                                    errorWidget: (_, __, ___) => const Icon(LucideIcons.user, size: 20),
                                  ),
                                )
                              : const Icon(LucideIcons.user, size: 20),
                        ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOwner ? 'Group Admin' : 'Member',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              activeText,
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.primary.withAlpha(180)),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isOwner)
                              Chip(
                                label: const Text('Admin'),
                                visualDensity: VisualDensity.compact,
                              ),
                            if (isAdmin && memberUid != uid)
                              PopupMenuButton<String>(
                                icon: const Icon(LucideIcons.moreVertical, size: 20),
                                onSelected: (value) {
                                  if (value == 'remove') {
                                    _confirmRemoveMember(context, memberUid, name);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.userMinus, size: 18, color: theme.colorScheme.error),
                                        const SizedBox(width: 8),
                                        Text('Remove', style: TextStyle(color: theme.colorScheme.error)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(GroupModel group) {
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              final error = await ref.read(groupServiceProvider).updateGroup(
                groupId: widget.groupId,
                name: name,
                description: descController.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error ?? 'Group updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, String memberUid, String memberName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove "$memberName" from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              _removeMember(memberUid);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeMember(String memberUid) async {
    final error = await ref.read(groupServiceProvider).removeMember(widget.groupId, memberUid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Member removed')),
      );
    }
  }

  void _approve(BuildContext context, String groupId, String userId) async {
    final error = await ref.read(groupServiceProvider).approveMember(groupId, userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Member approved')),
      );
    }
  }

  void _reject(BuildContext context, String groupId, String userId) async {
    final error = await ref.read(groupServiceProvider).rejectMember(groupId, userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Request rejected')),
      );
    }
  }

  void _cancelInvite(String userId) async {
    final error = await ref.read(groupServiceProvider).cancelInvite(widget.groupId, userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Invite cancelled')),
      );
    }
  }

}
