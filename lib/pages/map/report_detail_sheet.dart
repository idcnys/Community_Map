import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_post_model.dart';
import '../../models/community_post_model.dart';
import '../../services/report_post_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/audio_player_widget.dart';

class ReportDetailSheet extends StatefulWidget {
  final ReportPostModel report;
  final VoidCallback? onZoomToLocation;
  final double? userLat;
  final double? userLng;

  const ReportDetailSheet({
    super.key,
    required this.report,
    this.onZoomToLocation,
    this.userLat,
    this.userLng,
  });

  @override
  State<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<ReportDetailSheet> {
  final _service = ReportPostService();
  final _commentController = TextEditingController();
  bool _canSeeContact = false;
  bool _loadingContact = true;
  bool _sendingComment = false;
  bool _voting = false;
  double? _userLat;
  double? _userLng;

  bool get _isWithinRange {
    if (_userLat == null || _userLng == null) return false;
    return ReportPostService.isWithinRange(
      userLat: _userLat!,
      userLng: _userLng!,
      targetLat: widget.report.latitude,
      targetLng: widget.report.longitude,
    );
  }

  bool get _isOwnReport => widget.report.authorId == _service.currentUid;

  @override
  void initState() {
    super.initState();
    _userLat = widget.userLat;
    _userLng = widget.userLng;
    _checkContactVisibility();
    _ensureLocation();
    _service.incrementViewCount(widget.report.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _ensureLocation() async {
    if (_userLat != null && _userLng != null) return;
    final position = await ReportPostService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    }
  }

  Future<void> _checkContactVisibility() async {
    try {
      final myGroupIds = await _service.getMyGroupIds();
      final canSee =
          widget.report.canSeeContact(_service.currentUid, myGroupIds);
      if (mounted) {
        setState(() {
          _canSeeContact = canSee;
          _loadingContact = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingContact = false);
    }
  }

  Future<void> _vote(String voteType) async {
    setState(() => _voting = true);
    final error = await _service.voteOnReport(widget.report.id, voteType);
    if (mounted) {
      setState(() => _voting = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingComment = true);
    final error = await _service.addComment(widget.report.id, text);
    if (mounted) {
      setState(() => _sendingComment = false);
      if (error == null) {
        _commentController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: StreamBuilder<ReportPostModel?>(
        stream: _service.getReportStream(widget.report.id),
        builder: (context, reportSnap) {
          final report = reportSnap.data ?? widget.report;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20, 20, 20,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
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

                // Report type header
                Row(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      color: report.isUrgent
                          ? theme.colorScheme.error
                          : theme.colorScheme.tertiary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.reportType,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Reported by ${report.authorName}',
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (report.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'URGENT',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── STATS ROW (views + votes) ─────────────────────
                _buildStatsRow(theme, report),
                const SizedBox(height: 16),

                // Description
                if (report.description.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                ],

                // Report image
                if (report.imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: report.imageUrl,
                      width: double.infinity,
                      maxHeightDiskCache: 350,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 150,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 80,
                        color: theme.colorScheme.errorContainer,
                        child: Center(
                          child: Icon(LucideIcons.imageOff,
                              color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Voice note audio player
                if (report.audioUrl.isNotEmpty) ...[
                  AudioPlayerWidget(audioUrl: report.audioUrl),
                  const SizedBox(height: 16),
                ],

                // Date & time
                _infoRow(
                  LucideIcons.clock,
                  'Reported',
                  DateFormat('MMMM d, yyyy \u2022 h:mm a')
                      .format(report.createdAt),
                ),

                // Location
                _infoRow(
                  LucideIcons.mapPin,
                  'Location',
                  '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                ),

                // Contact number
                const SizedBox(height: 8),
                if (report.contactNumber.isNotEmpty) ...[
                  if (_loadingContact)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Checking access...'),
                    )
                  else if (_canSeeContact)
                    _infoRow(
                        LucideIcons.phone, 'Contact', report.contactNumber)
                  else
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(LucideIcons.lock,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            'Contact hidden (group members only)',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                const SizedBox(height: 16),

                // ─── VOTE SECTION ──────────────────────────────────
                _buildVoteSection(theme, report),
                const SizedBox(height: 16),

                // ─── COMMENT INPUT (within 1km, not own) ──────────
                if (_isWithinRange && !_isOwnReport) ...[
                  _buildCommentInput(theme),
                  const SizedBox(height: 16),
                ] else if (!_isWithinRange && !_isOwnReport) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.mapPinOff,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Move within 1 km to comment on this report.',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── COMMENTS SECTION ──────────────────────────────
                _buildCommentsSection(theme),

                const SizedBox(height: 20),

                // Go to location button
                if (widget.onZoomToLocation != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.onZoomToLocation,
                      icon: const Icon(LucideIcons.crosshair, size: 18),
                      label: const Text('Go to Location'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, ReportPostModel report) {
    return Row(
      children: [
        // Views
        Icon(LucideIcons.eye, size: 16,
            color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text('${report.viewCount}',
            style: TextStyle(
                fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(width: 6),
        Text('views',
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(width: 16),
        // Appropriate count
        Icon(LucideIcons.thumbsUp, size: 16,
            color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text('${report.appropriateCount}',
            style: TextStyle(
                fontSize: 13, color: theme.colorScheme.primary)),
        const SizedBox(width: 16),
        // Spam count
        Icon(LucideIcons.flag, size: 16, color: theme.colorScheme.error),
        const SizedBox(width: 4),
        Text('${report.spamCount}',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.error)),
      ],
    );
  }

  Widget _buildVoteSection(ThemeData theme, ReportPostModel report) {
    final myVote = report.votes[_service.currentUid];

    // Already voted — show confirmation, no buttons
    if (myVote != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: myVote == 'appropriate'
              ? theme.colorScheme.primaryContainer.withAlpha(80)
              : theme.colorScheme.errorContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              myVote == 'appropriate' ? LucideIcons.thumbsUp : LucideIcons.flag,
              size: 18,
              color: myVote == 'appropriate'
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(
              myVote == 'appropriate'
                  ? 'You marked this as appropriate'
                  : 'You marked this as spam',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: myVote == 'appropriate'
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    // Own report — no vote buttons
    if (_isOwnReport) return const SizedBox.shrink();

    // Not within range — hint
    if (!_isWithinRange) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.mapPinOff,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Move within 1 km to vote on this report.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show vote buttons
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Is this report legitimate?',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _voting ? null : () => _vote('appropriate'),
                  icon: const Icon(LucideIcons.thumbsUp, size: 16),
                  label: const Text('Appropriate',
                      style: TextStyle(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _voting ? null : () => _vote('spam'),
                  icon: Icon(LucideIcons.flag,
                      size: 16, color: theme.colorScheme.error),
                  label: Text('Spam',
                      style: TextStyle(
                          fontSize: 13, color: theme.colorScheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              isDense: true,
            ),
            maxLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submitComment(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _sendingComment ? null : _submitComment,
          icon: _sendingComment
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.send, size: 18),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(ThemeData theme) {
    return StreamBuilder<List<CommunityCommentModel>>(
      stream: _service.getComments(widget.report.id),
      builder: (context, snapshot) {
        final comments = snapshot.data ?? [];

        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments (${comments.length})',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...comments.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              c.authorName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('h:mm a').format(c.createdAt ?? DateTime.now()),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.content,
                          style:
                              const TextStyle(fontSize: 14, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
