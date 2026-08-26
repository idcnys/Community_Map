import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/group_model.dart';
import '../../providers/service_providers.dart';

class GroupInvitePage extends ConsumerStatefulWidget {
  final GroupModel group;
  const GroupInvitePage({super.key, required this.group});

  @override
  ConsumerState<GroupInvitePage> createState() => _GroupInvitePageState();
}

class _GroupInvitePageState extends ConsumerState<GroupInvitePage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final Set<String> _justInvited = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ref.read(groupServiceProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('সদস্য আমন্ত্রণ', style: TextStyle(fontFamily: 'EkusheInter', fontSize: 18)),
            Text(
              widget.group.name,
              style: TextStyle(fontFamily: 'EkusheInter', fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'নাম দিয়ে খুঁজুন...',
                hintStyle: const TextStyle(fontFamily: 'EkusheInter', fontSize: 14),
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.xCircle, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Results
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.search, size: 48,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(80)),
                        const SizedBox(height: 12),
                        Text(
                          'ব্যবহারকারী খুঁজতে নাম লিখুন',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ছোট/বড় হাতের অক্ষর ভেদাভেদ নেই',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<List<Map<String, String>>>(
                    stream: service.searchUsers(_searchQuery),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final users = snap.data!;
                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.userX, size: 48,
                                  color: theme.colorScheme.onSurfaceVariant.withAlpha(80)),
                              const SizedBox(height: 12),
                              Text(
                                '"$_searchQuery"-এর সাথে কোনো ব্যবহারকারী পাওয়া যায়নি',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withAlpha(40),
                        ),
                        itemBuilder: (_, i) {
                          final user = users[i];
                          final uid = user['uid']!;
                          final name = user['fullName']!;
                          final imageUrl = user['imageUrl'] ?? '';
                          final isMember = widget.group.members.contains(uid);
                          final isInvited =
                              widget.group.invites.contains(uid) || _justInvited.contains(uid);
                          final isSelf = uid == currentUid;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage:
                                      imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
                                  child: imageUrl.isEmpty
                                      ? Icon(LucideIcons.user, size: 20,
                                          color: theme.colorScheme.onSurfaceVariant)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                _buildTrailing(
                                  theme: theme,
                                  service: service,
                                  uid: uid,
                                  name: name,
                                  isSelf: isSelf,
                                  isMember: isMember,
                                  isInvited: isInvited,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailing({
    required ThemeData theme,
    required dynamic service,
    required String uid,
    required String name,
    required bool isSelf,
    required bool isMember,
    required bool isInvited,
  }) {
    if (isSelf) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('আপনি', style: theme.textTheme.labelSmall),
      );
    }

    if (isMember) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'সদস্য',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    if (isInvited) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.check, size: 12, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              'আমন্ত্রিত',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
        ),
      );
    }

    return FilledButton.tonalIcon(
      onPressed: () async {
        final error = await service.sendInvite(widget.group.id, uid);
        if (error == null) {
          setState(() => _justInvited.add(uid));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? '$name-কে আমন্ত্রণ পাঠানো হয়েছে')),
          );
        }
      },
      icon: const Icon(LucideIcons.plus, size: 14),
      label: const Text('আমন্ত্রণ', style: TextStyle(fontFamily: 'EkusheInter', fontSize: 12)),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
