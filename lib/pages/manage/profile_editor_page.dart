import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/push_notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/profile_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/user_profile_model.dart';
import '../login_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileEditorPage extends StatefulWidget {
  const ProfileEditorPage({super.key});

  @override
  State<ProfileEditorPage> createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends State<ProfileEditorPage> {
  final _profileService = ProfileService();
  final _cloudinary = CloudinaryService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _hobbyCtrl = TextEditingController();
  String _bloodGroup = '';

  bool _loaded = false;
  bool _saving = false;
  bool _uploadingImage = false;
  File? _newAvatar;
  String? _existingAvatarUrl;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _dobCtrl.dispose();
    _hobbyCtrl.dispose();
    super.dispose();
  }

  void _populateFields(UserProfile profile) {
    if (_loaded) return;
    _nameCtrl.text = profile.fullName;
    _bioCtrl.text = profile.bio;
    _phoneCtrl.text = profile.phone;
    _locationCtrl.text = profile.location;
    _dobCtrl.text = profile.dateOfBirth;
    _hobbyCtrl.text = profile.hobby;
    _bloodGroup = profile.bloodGroup;
    _existingAvatarUrl = profile.imageUrl;
    _loaded = true;
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() => _newAvatar = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
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

          return SafeArea(
            child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // ─── AVATAR ─────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: _newAvatar != null
                              ? FileImage(_newAvatar!)
                              : (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty)
                                  ? CachedNetworkImageProvider(_existingAvatarUrl!)
                                  : null,
                          child: (_newAvatar == null &&
                                  (_existingAvatarUrl == null || _existingAvatarUrl!.isEmpty))
                              ? Text(
                                  _nameCtrl.text.isNotEmpty
                                      ? _nameCtrl.text[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: _uploadingImage
                                ? SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary),
                                  )
                                : Icon(LucideIcons.camera, size: 14, color: theme.colorScheme.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Tap to change photo',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(LucideIcons.user),
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
                    prefixIcon: Icon(LucideIcons.info),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(LucideIcons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(LucideIcons.mapPin),
                  ),
                ),
                const SizedBox(height: 16),
                // Date of Birth — disabled, set at signup only
                TextFormField(
                  controller: _dobCtrl,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'DD/MM/YYYY',
                    prefixIcon: const Icon(LucideIcons.cake),
                    helperText: 'Set during signup — cannot be changed',
                  ),
                ),
                const SizedBox(height: 16),
                // Blood Group dropdown
                DropdownButtonFormField<String>(
                  value: _bloodGroup.isEmpty ? null : _bloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: Icon(LucideIcons.droplets),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Select')),
                    DropdownMenuItem(value: 'A+', child: Text('A+')),
                    DropdownMenuItem(value: 'A-', child: Text('A-')),
                    DropdownMenuItem(value: 'B+', child: Text('B+')),
                    DropdownMenuItem(value: 'B-', child: Text('B-')),
                    DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                    DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                    DropdownMenuItem(value: 'O+', child: Text('O+')),
                    DropdownMenuItem(value: 'O-', child: Text('O-')),
                  ],
                  onChanged: (val) => setState(() => _bloodGroup = val ?? ''),
                ),
                const SizedBox(height: 16),
                // Hobby
                TextFormField(
                  controller: _hobbyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hobby',
                    hintText: 'e.g. Reading, Photography, Cycling',
                    prefixIcon: Icon(LucideIcons.heart),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: (_saving || _uploadingImage) ? null : _saveProfile,
                  icon: (_saving || _uploadingImage)
                      ? SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.save),
                  label: Text(_uploadingImage ? 'Uploading photo...' : (_saving ? 'Saving...' : 'Save Changes')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Upload new avatar if selected
    String? newImageUrl;
    if (_newAvatar != null) {
      setState(() => _uploadingImage = true);
      final url = await _cloudinary.uploadImage(
        _newAvatar!,
        folder: 'cmap/profiles',
        onError: (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Avatar upload failed: $err'), backgroundColor: Colors.red),
          );
        },
      );
      setState(() => _uploadingImage = false);
      if (url != null) {
        newImageUrl = url;
      }
    }

    final error = await _profileService.updateProfile(
      fullName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      bloodGroup: _bloodGroup,
      hobby: _hobbyCtrl.text.trim(),
      imageUrl: newImageUrl,
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
    await PushNotificationService().unregisterToken();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
