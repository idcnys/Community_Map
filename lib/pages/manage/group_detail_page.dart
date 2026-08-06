import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/group_service.dart';
import '../../services/group_chat_service.dart';
import '../../models/group_model.dart';
import '../../core/utils/time_ago.dart';
import 'group_chat_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final _groupService = GroupService();
  final _chatService = GroupChatService();
  final _firestore = FirebaseFirestore.instance;
  final Map<String, String> _nameCache = {};
  final Map<String, DateTime?> _lastActiveCache = {};

  Future<String> _resolveName(String uid) async {
    if (_nameCache.containsKey(uid)) return _nameCache[uid]!;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final name = (doc.data()?['fullName'] as String?) ?? 'Unknown User';
      _nameCache[uid] = name;
      return name;
    } catch (_) {
      return 'Unknown User';
    }
  }

  Future<DateTime?> _resolveLastActive(String uid) async {
    if (_lastActiveCache.containsKey(uid)) return _lastActiveCache[uid];
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final ts = doc.data()?['lastActive'] as Timestamp?;
      final dt = ts?.toDate();
      _lastActiveCache[uid] = dt;
      return dt;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: StreamBuilder<GroupModel?>(
        stream: _groupService.getGroupById(widget.groupId),
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
                      Text(group.name, style: theme.textTheme.titleLarge),
                      if (group.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(group.description, style: TextStyle(color: theme.colorScheme.onSurface)),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${group.memberCount} members \u2022 Created by ${group.createdByName}',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
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
              const SizedBox(height: 16),

              // Pending requests (admin only)
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
                      title: FutureBuilder<String>(
                        future: _resolveName(requestUid),
                        builder: (ctx, nameSnap) => Text(
                          nameSnap.data ?? 'Loading...',
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
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: const Icon(LucideIcons.user, size: 20),
                    ),
                    title: FutureBuilder<String>(
                      future: _resolveName(memberUid),
                      builder: (ctx, nameSnap) => Text(
                        nameSnap.data ?? 'Loading...',
                      ),
                    ),
                    subtitle: FutureBuilder<DateTime?>(
                      future: _resolveLastActive(memberUid),
                      builder: (ctx, activeSnap) {
                        final lastActive = activeSnap.data;
                        final activeText = lastActive != null
                            ? 'Active ${timeAgo(lastActive)}'
                            : 'No activity recorded';
                        return Column(
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
                        );
                      },
                    ),
                    trailing: isOwner
                        ? Chip(
                            label: const Text('Admin'),
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _approve(BuildContext context, String groupId, String userId) async {
    final error = await _groupService.approveMember(groupId, userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Member approved')),
      );
    }
  }

  void _reject(BuildContext context, String groupId, String userId) async {
    final error = await _groupService.rejectMember(groupId, userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Request rejected')),
      );
    }
  }
}
