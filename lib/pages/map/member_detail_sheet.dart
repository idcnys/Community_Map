import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/time_ago.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MemberDetailSheet extends StatefulWidget {
  final String uid;
  final String name;
  const MemberDetailSheet({super.key, required this.uid, required this.name});

  @override
  State<MemberDetailSheet> createState() => _MemberDetailSheetState();
}

class _MemberDetailSheetState extends State<MemberDetailSheet> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      if (mounted) {
        setState(() {
          _profile = doc.exists ? doc.data() : null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = (_profile?['imageUrl'] ?? '').toString();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // Avatar + Name header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withAlpha(60),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: (imageUrl.isNotEmpty)
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Icon(LucideIcons.user, color: Colors.white, size: 26),
                              errorWidget: (context, url, error) => const Icon(LucideIcons.user, color: Colors.white, size: 26),
                            ),
                          )
                        : const Icon(LucideIcons.user, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile?['fullName'] ?? widget.name,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _profile?['email'] ?? '',
                          style: TextStyle(fontFamily: 'EkusheInter', fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Details
              _buildInfoRow(
                icon: LucideIcons.calendar,
                label: 'জন্মতারিখ',
                value: formatDateOfBirth(_profile?['dateOfBirth']),
                theme: theme,
              ),
              const Divider(height: 24),
              _buildInfoRow(
                icon: LucideIcons.clock,
                label: 'সর্বশেষ সক্রিয়',
                value: _formatLastActive(_profile?['lastActive']),
                theme: theme,
              ),
              if ((_profile?['phone'] ?? '').toString().isNotEmpty) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  icon: LucideIcons.phone,
                  label: 'ফোন',
                  value: _profile?['phone'] ?? '',
                  theme: theme,
                ),
              ],
              if ((_profile?['location'] ?? '').toString().isNotEmpty) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  icon: LucideIcons.mapPin,
                  label: 'অবস্থান',
                  value: _profile?['location'] ?? '',
                  theme: theme,
                ),
              ],
              if ((_profile?['bloodGroup'] ?? '').toString().isNotEmpty) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  icon: LucideIcons.droplets,
                  label: 'রক্তের গ্রুপ',
                  value: _profile?['bloodGroup'] ?? '',
                  theme: theme,
                ),
              ],
              if ((_profile?['hobby'] ?? '').toString().isNotEmpty) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  icon: LucideIcons.heart,
                  label: 'শখ',
                  value: _profile?['hobby'] ?? '',
                  theme: theme,
                ),
              ],
              if ((_profile?['bio'] ?? '').toString().isNotEmpty) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  icon: LucideIcons.info,
                  label: 'পরিচিতি',
                  value: _profile?['bio'] ?? '',
                  theme: theme,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        ),
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
              Text(value, style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }


  String _formatLastActive(dynamic ts) {
    if (ts == null) return 'অজানা';
    try {
      final dt = ts is Timestamp ? ts.toDate() : DateTime.parse(ts.toString());
      return timeAgo(dt);
    } catch (_) {
      return 'অজানা';
    }
  }
}
