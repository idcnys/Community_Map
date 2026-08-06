import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final _groupService = GroupService();
  final _firestore = FirebaseFirestore.instance;
  final Map<String, String> _nameCache = {};

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
                        Text(group.description, style: TextStyle(color: Colors.grey.shade700)),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${group.memberCount} members • Created by ${group.createdByName}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
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
                      leading: const Icon(Icons.person_add_alt),
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
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            tooltip: 'Approve',
                            onPressed: () => _approve(context, widget.groupId, requestUid),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
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
                      child: const Icon(Icons.person, size: 20),
                    ),
                    title: FutureBuilder<String>(
                      future: _resolveName(memberUid),
                      builder: (ctx, nameSnap) => Text(
                        nameSnap.data ?? 'Loading...',
                      ),
                    ),
                    subtitle: Text(
                      isOwner ? 'Group Admin' : 'Member',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
