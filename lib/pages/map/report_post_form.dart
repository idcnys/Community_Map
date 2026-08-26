
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../core/utils/time_ago.dart';
import '../../widgets/voice_record_button.dart';
import '../../services/supabase_storage_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/report_post_service.dart';
import '../../providers/group_providers.dart';
import '../../services/cloudinary_service.dart';
import '../../models/report_post_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportPostForm extends ConsumerStatefulWidget {
  const ReportPostForm({super.key});

  @override
  ConsumerState<ReportPostForm> createState() => _ReportPostFormState();
}

class _ReportPostFormState extends ConsumerState<ReportPostForm> {
  final _formKey = GlobalKey<FormState>();
  final _contactCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _reportService = ReportPostService();
  final _cloudinary = CloudinaryService();
  final _supabaseStorage = SupabaseStorageService();
  final _picker = ImagePicker();

  String _reportType = ReportTypes.options[0];
  Position? _currentPosition;
  bool _locating = true;
  bool _submitting = false;
  bool _uploading = false;
  File? _selectedImage;
  File? _audioFile;
  bool _uploadingAudio = false;

  @override
  void initState() {
    super.initState();
    _detectLocation();
    _prefillContact();
  }

  /// Auto-fill contact number from user profile if phone is set.
  Future<void> _prefillContact() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final phone = doc.data()?['phone'] as String? ?? '';
      if (phone.isNotEmpty && mounted && _contactCtrl.text.isEmpty) {
        setState(() => _contactCtrl.text = phone);
      }
    } catch (e) { debugPrint('[] error: $e'); }
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    final pos = await ReportPostService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentPosition = pos;
        _locating = false;
      });
    }
  }


  Future<void> _pickImage() async {
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
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  @override
  void dispose() {
    _contactCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myGroups = ref.watch(myJoinedGroupsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('রিপোর্ট জমা দিন')),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contact number
              TextFormField(
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'যোগাযোগ নম্বর',
                  prefixIcon: Icon(LucideIcons.phone),
                  helperText:
                      'শুধুমাত্র আপনার সাথে গ্রুপ শেয়ার করা ব্যবহারকারীদের কাছে দৃশ্যমান',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'যোগাযোগ নম্বর প্রয়োজন'
                    : null,
              ),
              const SizedBox(height: 16),

              // Report type dropdown
              DropdownButtonFormField<String>(
                value: _reportType,
                decoration: const InputDecoration(
                  labelText: 'রিপোর্টের ধরন',
                  prefixIcon: Icon(LucideIcons.layoutGrid),
                ),
                items: ReportTypes.options.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (v) => setState(() => _reportType = v!),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'বিবরণ',
                  hintText: 'ঘটনাটি বর্ণনা করুন...',
                  prefixIcon: Icon(LucideIcons.fileText),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'বিবরণ প্রয়োজন'
                    : null,
              ),
              const SizedBox(height: 16),

              // ─── IMAGE PICKER ─────────────────────────────────────
              if (_selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(32, 32),
                        ),
                        onPressed: () => setState(() => _selectedImage = null),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(LucideIcons.camera),
                  label: const Text('ছবি সংযুক্ত করুন (ঐচ্ছিক)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              const SizedBox(height: 16),

              // ─── VOICE RECORDER ────────────────────────────────────
              VoiceRecordButton(
                existingRecording: _audioFile,
                onRecorded: (file, duration) {
                  setState(() => _audioFile = file);
                },
                onRemoveRecording: () {
                  setState(() => _audioFile = null);
                },
                maxDurationSeconds: 100,
              ),
              const SizedBox(height: 16),

              // Location display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _locating
                            ? LucideIcons.locate
                            : (_currentPosition != null
                                ? LucideIcons.mapPin
                                : LucideIcons.mapPinOff),
                        color: _currentPosition != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _locating
                            ? const Text('অবস্থান সনাক্ত হচ্ছে...')
                            : _currentPosition != null
                                ? Text(
                                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                                    'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 13),
                                  )
                                : Text(
                                    'অবস্থান পাওয়া যাচ্ছে না',
                                    style: TextStyle(
                                        color: theme.colorScheme.error.withAlpha(180)),
                                  ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.refreshCw),
                        onPressed: _detectLocation,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Shared groups info
              if (myGroups.isNotEmpty) ...[
                Text(
                  'যোগাযোগ নম্বর দৃশ্যমান হবে:',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: myGroups
                      .map((g) => Chip(
                            label: Text(g.name,
                                style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 32),

              // Submit
              FilledButton.icon(
                onPressed: (_submitting || _uploading || _uploadingAudio || _locating || _currentPosition == null)
                    ? null
                    : _submit,
                icon: (_submitting || _uploading)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(LucideIcons.alertTriangle),
                label: Text(_uploading ? 'ছবি আপলোড হচ্ছে...' : (_uploadingAudio ? 'ভয়েস আপলোড হচ্ছে...' : 'রিপোর্ট জমা দিন')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) return;

    setState(() => _submitting = true);

    // Upload image first if selected
    String imageUrl = '';
    if (_selectedImage != null) {
      setState(() => _uploading = true);
      final url = await _cloudinary.uploadImage(
        _selectedImage!,
        folder: 'cmap/reports',
        onError: (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ছবি আপলোড ব্যর্থ: $err'), backgroundColor: Colors.red),
          );
        },
      );
      setState(() => _uploading = false);
      if (url == null) {
        setState(() => _submitting = false);
        return;
      }
      imageUrl = url;
    }

    // Upload audio to Supabase if recorded
    String audioUrl = '';
    if (_audioFile != null) {
      setState(() => _uploadingAudio = true);
      final (url, error) = await _supabaseStorage.uploadAudioFile(_audioFile!);
      setState(() => _uploadingAudio = false);
      if (url == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ভয়েস আপলোড ব্যর্থ: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        audioUrl = url;
      }
    }

    final myGroups = ref.read(myJoinedGroupsProvider).value ?? [];
    final groupIds = myGroups.map((g) => g.id).toList();

    final error = await _reportService.createReport(
      contactNumber: _contactCtrl.text.trim(),
      reportType: _reportType,
      description: _descCtrl.text.trim(),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      sharedGroupIds: groupIds,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
    );

    setState(() => _submitting = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('রিপোর্ট সফলভাবে জমা হয়েছে')),
        );
        Navigator.of(context).pop();
      }
    }
  }
}
