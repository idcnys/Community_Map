
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/report_post_service.dart';
import '../../services/group_service.dart';
import '../../models/report_post_model.dart';
import '../../models/group_model.dart';

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

  String _reportType = ReportTypes.options[0];
  Position? _currentPosition;
  bool _locating = true;
  bool _submitting = false;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                  prefixIcon: Icon(Icons.phone),
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
                  prefixIcon: Icon(Icons.category),
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
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
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
                            ? Icons.gps_not_fixed
                            : (_currentPosition != null
                                ? Icons.location_on
                                : Icons.location_off),
                        color: _currentPosition != null
                            ? Colors.green
                            : Colors.grey,
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
                                        color: Colors.red.shade400),
                                  ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
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
                      ?.copyWith(color: Colors.grey.shade600),
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
                onPressed: (_submitting || _locating || _currentPosition == null)
                    ? null
                    : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.report_problem),
                label: const Text('Submit Report'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange.shade700,
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
    if (_currentPosition == null) return;

    setState(() => _submitting = true);

    final groupIds = _myGroups.map((g) => g.id).toList();

    final error = await _reportService.createReport(
      contactNumber: _contactCtrl.text.trim(),
      reportType: _reportType,
      description: _descCtrl.text.trim(),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      sharedGroupIds: groupIds,
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
