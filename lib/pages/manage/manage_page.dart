
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/profile_service.dart';
import '../../services/group_service.dart';
import '../../models/post_model.dart';
import '../../models/group_model.dart';
import '../login_page.dart';

class ManagePage extends StatelessWidget {
  const ManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Profile',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileEditorPage()),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Groups'),
              Tab(text: 'Discover'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyGroupsTab(),
            _DiscoverGroupsTab(),
            _RequestsTab(),
          ],
        ),
      ),
    );
  }
}

// ─── MY GROUPS TAB ──────────────────────────────────────────────────
class _MyGroupsTab extends StatelessWidget {
  const _MyGroupsTab();

  @override
  Widget build(BuildContext context) {
    final groupService = GroupService();
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<GroupModel>>(
            stream: groupService.getMyJoinedGroups(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final groups = snapshot.data ?? [];

              if (groups.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No groups yet', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Join or create a group to get started.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                  final isAdmin = group.createdBy == uid;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.group),
                      title: Text(group.name),
                      subtitle: Text(
                        '${group.memberCount} members${isAdmin ? ' • Admin' : ''}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'leave') _leaveGroup(context, group.id);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'leave', child: Text('Leave Group')),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupDetailPage(groupId: group.id),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // ─── CREATE GROUP BUTTON ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCreateGroupDialog(context),
              icon: const Icon(Icons.add),
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

  void _leaveGroup(BuildContext context, String groupId) async {
    final groupService = GroupService();
    final error = await groupService.leaveGroup(groupId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final groupService = GroupService();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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

              final error = await groupService.createGroup(
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );

              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group created!')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ─── DISCOVER GROUPS TAB ────────────────────────────────────────────
class _DiscoverGroupsTab extends StatefulWidget {
  const _DiscoverGroupsTab();

  @override
  State<_DiscoverGroupsTab> createState() => _DiscoverGroupsTabState();
}

class _DiscoverGroupsTabState extends State<_DiscoverGroupsTab> {
  final _groupService = GroupService();
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

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
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _query = val),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<GroupModel>>(
            stream: _groupService.searchGroups(_query),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allGroups = snapshot.data ?? [];
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              // Filter out groups the user is already a member of
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
    final error = await _groupService.sendJoinRequest(groupId);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _cancelRequest(String groupId) async {
    final error = await _groupService.cancelJoinRequest(groupId);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

// ─── REQUESTS TAB ───────────────────────────────────────────────────
class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    final groupService = GroupService();
    final theme = Theme.of(context);

    return StreamBuilder<List<GroupModel>>(
      stream: groupService.getMyPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

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
                    final error = await GroupService().cancelJoinRequest(group.id);
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

// ─── PROFILE EDITOR PAGE ────────────────────────────────────────────
class ProfileEditorPage extends StatefulWidget {
  const ProfileEditorPage({super.key});

  @override
  State<ProfileEditorPage> createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends State<ProfileEditorPage> {
  final _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  void _populateFields(UserProfile profile) {
    if (_loaded) return;
    _nameCtrl.text = profile.fullName;
    _bioCtrl.text = profile.bio;
    _phoneCtrl.text = profile.phone;
    _locationCtrl.text = profile.location;
    _dobCtrl.text = profile.dateOfBirth;
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _profileService.getProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_loaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;
          if (profile != null) _populateFields(profile);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar preview
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      _nameCtrl.text.isNotEmpty
                          ? _nameCtrl.text[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Name must be at least 3 characters'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _dobCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'DD/MM/YYYY',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                ),
                const SizedBox(height: 32),

                FilledButton.icon(
                  onPressed: _saving ? null : _saveProfile,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final error = await _profileService.updateProfile(
      fullName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop();
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}

// ─── GROUP DETAIL PAGE (Admin: members + approve/reject) ────────────
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
              // ─── GROUP INFO ────────────────────────────────────────
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

              // ─── PENDING REQUESTS (Admin only) ─────────────────────
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

              // ─── MEMBERS LIST ──────────────────────────────────────
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
