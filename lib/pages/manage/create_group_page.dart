import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/service_providers.dart';
import '../../providers/group_providers.dart';

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _isPrivate = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final error = await ref.read(groupServiceProvider).createGroup(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          isPrivate: _isPrivate,
        );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    // Invalidate group lists so they refresh on return
    ref.invalidate(myJoinedGroupsProvider);
    ref.invalidate(myCreatedGroupsProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'গ্রুপ তৈরি হয়েছে!')),
    );

    if (error == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('গ্রুপ তৈরি করুন'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(60),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.users,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'নতুন গ্রুপ তৈরি করুন',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'একটি নাম এবং বিবরণ দিন',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Group Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'গ্রুপের নাম',
                    prefixIcon: Icon(LucideIcons.tag),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'নাম কমপক্ষে ৩ অক্ষরের হতে হবে'
                      : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'বিবরণ',
                    prefixIcon: Icon(LucideIcons.fileText),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Private toggle
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'প্রাইভেট গ্রুপ',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _isPrivate
                          ? 'শুধুমাত্র আমন্ত্রণে • ডিসকভার থেকে লুকানো'
                          : 'যে কেউ খুঁজে পেতে এবং যোগদানের অনুরোধ করতে পারবে',
                      style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 12),
                    ),
                    secondary: Icon(
                      _isPrivate ? LucideIcons.lock : LucideIcons.globe,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    value: _isPrivate,
                    onChanged: (v) => setState(() => _isPrivate = v),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.plus),
                    label: Text(_isSubmitting ? 'তৈরি হচ্ছে...' : 'গ্রুপ তৈরি করুন'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontFamily: 'EkusheInter', 
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
