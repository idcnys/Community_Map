import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/push_notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/profile_service.dart';
import '../../core/utils/time_ago.dart';
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
  String _dobIso = '';
  final _hobbyCtrl = TextEditingController();
  String _bloodGroup = '';

  bool _loaded = false;
  bool _saving = false;
  bool _uploadingImage = false;
  bool _editing = false;
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
    _dobIso = profile.dateOfBirth;
    _dobCtrl.text = formatDateOfBirth(profile.dateOfBirth);
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
              title: const Text('ক্যামেরা'),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('গ্যালারি'),
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

  bool get _dobEditable => _dobCtrl.text.trim().isEmpty;

  Future<void> _selectDob() async {
    if (!_dobEditable) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobIso = picked.toIso8601String();
        _dobCtrl.text = formatDateOfBirth(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'প্রোফাইল সম্পাদনা' : 'প্রোফাইল'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            tooltip: 'লগ আউট',
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
            child: _editing ? _buildEditForm(theme) : _buildDetailsView(theme),
          );
        },
      ),
    );
  }

  // ─── READ-ONLY DETAILS VIEW ────────────────────────────────────
  Widget _buildDetailsView(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        _buildAvatar(theme, interactive: false),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _nameCtrl.text.trim().isEmpty ? 'নাম সেট করা হয়নি' : _nameCtrl.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        if (_bioCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              _bioCtrl.text.trim(),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'EkusheInter', fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
        const SizedBox(height: 32),
        _detailTile(LucideIcons.phone, 'ফোন', _phoneCtrl.text.trim()),
        _detailTile(LucideIcons.mapPin, 'লোকেশন', _locationCtrl.text.trim()),
        _detailTile(LucideIcons.cake, 'জন্মতারিখ', formatDateOfBirth(_dobCtrl.text.trim())),
        _detailTile(LucideIcons.droplets, 'রক্তের গ্রুপ', _bloodGroup),
        _detailTile(LucideIcons.heart, 'শখ', _hobbyCtrl.text.trim()),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => setState(() => _editing = true),
          icon: const Icon(LucideIcons.pencil),
          label: const Text('সম্পাদনা করুন'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _detailTile(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final display = value.trim().isEmpty ? '—' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontFamily: 'EkusheInter', fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  display,
                  style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── EDIT FORM VIEW ────────────────────────────────────────────
  Widget _buildEditForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildAvatar(theme, interactive: true),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'ছবি পরিবর্তন করতে ট্যাপ করুন',
              style: TextStyle(fontFamily: 'EkusheInter', fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'পুরো নাম',
              prefixIcon: Icon(LucideIcons.user),
            ),
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'নাম কমপক্ষে ৩ অক্ষরের হতে হবে'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'বায়ো',
              prefixIcon: Icon(LucideIcons.info),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'ফোন',
              prefixIcon: Icon(LucideIcons.phone),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'লোকেশন',
              prefixIcon: Icon(LucideIcons.mapPin),
            ),
          ),
          const SizedBox(height: 16),
          // Date of Birth — editable once if empty (e.g. Google sign-in)
          TextFormField(
            controller: _dobCtrl,
            readOnly: true,
            enabled: _dobEditable,
            onTap: _selectDob,
            decoration: InputDecoration(
              labelText: 'জন্মতারিখ',
              hintText: 'DD/MM/YYYY',
              prefixIcon: const Icon(LucideIcons.cake),
              suffixIcon: _dobEditable
                  ? const Icon(LucideIcons.chevronDown)
                  : null,
              helperText: _dobEditable
                  ? 'সেট করতে ট্যাপ করুন — শুধুমাত্র একবার সেট করা যাবে'
                  : 'পরিবর্তন করা যাবে না',
            ),
          ),
          const SizedBox(height: 16),
          // Blood Group dropdown
          DropdownButtonFormField<String>(
            value: _bloodGroup.isEmpty ? null : _bloodGroup,
            decoration: const InputDecoration(
              labelText: 'রক্তের গ্রুপ',
              prefixIcon: Icon(LucideIcons.droplets),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('নির্বাচন করুন')),
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
              labelText: 'শখ',
              hintText: 'যেমন: পড়া, ফটোগ্রাফি, সাইক্লিং',
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
            label: Text(_uploadingImage ? 'ছবি আপলোড হচ্ছে...' : (_saving ? 'সংরক্ষণ হচ্ছে...' : 'পরিবর্তন সংরক্ষণ করুন')),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHARED AVATAR ─────────────────────────────────────────────
  Widget _buildAvatar(ThemeData theme, {required bool interactive}) {
    final avatar = CircleAvatar(
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
              style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 36, fontWeight: FontWeight.bold),
            )
          : null,
    );

    if (!interactive) {
      return Center(child: avatar);
    }

    return Center(
      child: GestureDetector(
        onTap: _pickAvatar,
        child: Stack(
          children: [
            avatar,
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
            SnackBar(content: Text('ছবি আপলোড ব্যর্থ হয়েছে: $err'), backgroundColor: Colors.red),
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
      dateOfBirth: _dobIso,
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
        const SnackBar(content: Text('প্রোফাইল সফলভাবে আপডেট হয়েছে')),
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
