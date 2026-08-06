
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/feed_providers.dart';
import '../../providers/service_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CommunityPostForm extends ConsumerStatefulWidget {
  const CommunityPostForm({super.key});

  @override
  ConsumerState<CommunityPostForm> createState() => _CommunityPostFormState();
}

class _CommunityPostFormState extends ConsumerState<CommunityPostForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _originType = 'public';
  String? _selectedGroupId;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myGroups = ref.watch(myJoinedGroupsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Create Community Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(LucideIcons.type),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What do you want to share?',
                  prefixIcon: Icon(LucideIcons.fileText),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 24),

              Text(
                'Post Origin',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              RadioListTile<String>(
                title: const Text('Public'),
                subtitle: const Text('Visible to everyone'),
                value: 'public',
                groupValue: _originType,
                onChanged: (v) => setState(() {
                  _originType = v!;
                  _selectedGroupId = null;
                }),
              ),

              RadioListTile<String>(
                title: const Text('Group'),
                subtitle: const Text('Visible to group members only'),
                value: 'group',
                groupValue: _originType,
                onChanged: (v) => setState(() => _originType = v!),
              ),

              if (_originType == 'group') ...[
                const SizedBox(height: 12),
                if (myGroups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'You haven\'t joined any groups yet.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Select Group',
                      prefixIcon: Icon(LucideIcons.users),
                    ),
                    items: myGroups.map((g) {
                      return DropdownMenuItem(value: g.id, child: Text(g.name));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedGroupId = v),
                    validator: (v) => (_originType == 'group' && v == null)
                        ? 'Please select a group'
                        : null,
                  ),
              ],

              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.send),
                label: const Text('Publish Post'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final myGroups = ref.read(myJoinedGroupsProvider).value ?? [];
    String groupId = '';
    String groupName = 'Public';

    if (_originType == 'group' && _selectedGroupId != null) {
      groupId = _selectedGroupId!;
      final group = myGroups.firstWhere((g) => g.id == groupId);
      groupName = group.name;
    }

    final service = ref.read(communityPostServiceProvider);
    final error = await service.createPost(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      originType: _originType,
      groupId: groupId,
      groupName: groupName,
    );

    setState(() => _submitting = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published!')),
        );
        // Invalidate feed to show new post
        ref.invalidate(paginatedFeedProvider);
        context.pop();
      }
    }
  }
}
