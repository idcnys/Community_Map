import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/feed_providers.dart';
import '../../providers/group_providers.dart';
import '../../providers/service_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PollForm extends ConsumerStatefulWidget {
  const PollForm({super.key});

  @override
  ConsumerState<PollForm> createState() => _PollFormState();
}

class _PollFormState extends ConsumerState<PollForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  String _pollType = 'single';
  String _originType = 'public';
  String? _selectedGroupId;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionCtrls.length >= 6) return;
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionCtrls.length <= 2) return;
    setState(() {
      _optionCtrls[index].dispose();
      _optionCtrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myGroups = ref.watch(myJoinedGroupsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Create Poll')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Poll Question',
                  prefixIcon: Icon(LucideIcons.helpCircle),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Question is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(LucideIcons.fileText),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Poll type
              Text('Vote Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'single', label: Text('Single Choice'), icon: Icon(LucideIcons.circleDot, size: 16)),
                  ButtonSegment(value: 'multi', label: Text('Multiple Choice'), icon: Icon(LucideIcons.checkSquare, size: 16)),
                ],
                selected: {_pollType},
                onSelectionChanged: (sel) => setState(() => _pollType = sel.first),
              ),
              const SizedBox(height: 24),

              // Options
              Text('Options (min 2, max 6)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...List.generate(_optionCtrls.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _optionCtrls[i],
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                            isDense: true,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      if (_optionCtrls.length > 2)
                        IconButton(
                          icon: Icon(LucideIcons.xCircle, color: theme.colorScheme.error, size: 20),
                          onPressed: () => _removeOption(i),
                        ),
                    ],
                  ),
                );
              }),
              if (_optionCtrls.length < 6)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Add Option'),
                ),
              const SizedBox(height: 24),

              // Origin
              Text('Post Origin', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Public'),
                subtitle: const Text('Visible to everyone'),
                value: 'public',
                groupValue: _originType,
                onChanged: (v) => setState(() { _originType = v!; _selectedGroupId = null; }),
              ),
              RadioListTile<String>(
                title: const Text('Group'),
                subtitle: const Text('Visible to group members only'),
                value: 'group',
                groupValue: _originType,
                onChanged: (v) => setState(() => _originType = v!),
              ),
              if (_originType == 'group') ...[
                const SizedBox(height: 8),
                if (myGroups.isEmpty)
                  Text('You haven\'t joined any groups yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
                else
                  DropdownButtonFormField<String>(
                    value: _selectedGroupId,
                    decoration: const InputDecoration(labelText: 'Select Group'),
                    items: myGroups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                    onChanged: (v) => setState(() => _selectedGroupId = v),
                    validator: (v) => (_originType == 'group' && v == null) ? 'Select a group' : null,
                  ),
              ],

              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(LucideIcons.barChart2),
                label: const Text('Create Poll'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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
      groupName = myGroups.firstWhere((g) => g.id == groupId).name;
    }

    final service = ref.read(pollServiceProvider);
    final error = await service.createPollPost(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      pollOptions: _optionCtrls.map((c) => c.text.trim()).toList(),
      pollType: _pollType,
      originType: _originType,
      groupId: groupId,
      groupName: groupName,
    );

    setState(() => _submitting = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poll created!')));
        ref.invalidate(paginatedFeedProvider);
        context.pop();
      }
    }
  }
}
