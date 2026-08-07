
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/report_post_service.dart';
import '../../services/group_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/report_post_model.dart';
import '../../models/group_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReportPostForm extends StatefulWidget {
  const ReportPostForm({super.key});

  @override
  State<ReportPostForm> createState() => _ReportPostFormState();
}

class _ReportPostFormState extends State<ReportPostForm> {
  final _formKey = GlobalKey<FormState>();
  final _contactCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _reportService = ReportPostService();
  final _groupService = GroupService();
  final _cloudinary = CloudinaryService();
  final _picker = ImagePicker();

  String _reportType = ReportTypes.options[0];
  Position? _currentPosition;
  bool _locating = true;
  bool _submitting = false;
  bool _uploading = false;
  File? _selectedImage;
  List<GroupModel> _myGroups = [];

  @override
  void initState() {
    super.initState();
    _detectLocation();
    _loadGroups();
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

  Future<void> _loadGroups() async {
    try {
      final snap = await _groupService.getMyJoinedGroups().first;
      if (mounted) setState(() => _myGroups = snap);
    } catch (_) {}
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

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Report')),
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
                  labelText: 'Contact Number',
                  prefixIcon: Icon(LucideIcons.phone),
                  helperText:
                      'Only visible to users sharing groups with you',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Contact number is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Report type dropdown
              DropdownButtonFormField<String>(
                value: _reportType,
                decoration: const InputDecoration(
                  labelText: 'Report Type',
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
                  labelText: 'Description',
                  hintText: 'Describe the incident...',
                  prefixIcon: Icon(LucideIcons.fileText),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
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
                  label: const Text('Attach Photo (optional)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
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
                            ? const Text('Detecting location...')
                            : _currentPosition != null
                                ? Text(
                                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                                    'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(fontSize: 13),
                                  )
                                : Text(
                                    'Location unavailable',
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
              if (_myGroups.isNotEmpty) ...[
                Text(
                  'Contact visible to members of:',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _myGroups
                      .map((g) => Chip(
                            label: Text(g.name,
                                style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 32),

              // Submit
              FilledButton.icon(
                onPressed: (_submitting || _uploading || _locating || _currentPosition == null)
                    ? null
                    : _submit,
                icon: (_submitting || _uploading)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(LucideIcons.alertTriangle),
                label: Text(_uploading ? 'Uploading photo...' : 'Submit Report'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.tertiary,
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
            SnackBar(content: Text('Image upload failed: $err'), backgroundColor: Colors.red),
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

    final groupIds = _myGroups.map((g) => g.id).toList();

    final error = await _reportService.createReport(
      contactNumber: _contactCtrl.text.trim(),
      reportType: _reportType,
      description: _descCtrl.text.trim(),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      sharedGroupIds: groupIds,
      imageUrl: imageUrl,
    );

    setState(() => _submitting = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
        Navigator.of(context).pop();
      }
    }
  }
}
