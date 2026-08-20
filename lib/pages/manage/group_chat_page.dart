import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/group_chat_service.dart';
import '../../services/notification_service.dart';
import '../../services/cloudinary_service.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/utils/time_ago.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  const GroupChatPage({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

/// A mention range tracking an atomic @FullName span in the text.
class _MentionRange {
  final int start;
  final int end;
  final String uid;
  final String name;
  _MentionRange(this.start, this.end, this.uid, this.name);

  bool contains(int pos) => pos > start && pos < end;
  int get length => end - start;
}

/// Custom controller that renders @mentions with highlighted style.
class _MentionTextController extends TextEditingController {
  List<_MentionRange> mentionRanges = [];
  Color mentionColor = Colors.blue;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = value.text;
    if (mentionRanges.isEmpty) {
      return TextSpan(text: text, style: style);
    }
    final children = <InlineSpan>[];
    int lastEnd = 0;
    // Sort ranges by start to process left-to-right
    final sorted = List<_MentionRange>.from(mentionRanges)
      ..sort((a, b) => a.start.compareTo(b.start));
    for (final range in sorted) {
      if (range.start > lastEnd) {
        children.add(TextSpan(text: text.substring(lastEnd, range.start)));
      }
      children.add(TextSpan(
        text: text.substring(range.start, range.end),
        style: TextStyle(
          color: mentionColor,
          fontWeight: FontWeight.w600,
          backgroundColor: mentionColor.withAlpha(30),
        ),
      ));
      lastEnd = range.end;
    }
    if (lastEnd < text.length) {
      children.add(TextSpan(text: text.substring(lastEnd)));
    }
    return TextSpan(children: children, style: style);
  }
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _service = GroupChatService();
  final _msgCtrl = _MentionTextController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  bool _sending = false;
  int _prevMsgCount = 0;
  bool _isInitialLoad = true;
  File? _pendingImage;
  bool _uploadingImage = false;

  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  // ─── @mention state ─────────────────────────────────────────────
  List<Map<String, String>> _memberInfo = []; // [{uid, name, imageUrl}]
  List<Map<String, String>> _mentionSuggestions = []; // filtered matches
  bool _showMentions = false;
  int _mentionStartIndex = -1; // position of '@' in text
  bool _suppressListener = false; // prevent re-entrant listener calls

  @override
  void initState() {
    super.initState();
    _messagesStream = _service.getGroupMessages(widget.groupId);
    _service.markGroupAsRead(widget.groupId);
    _msgCtrl.addListener(_onTextChanged);
    _loadMemberNames();
  }

  @override
  void dispose() {
    _msgCtrl.removeListener(_onTextChanged);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMemberNames() async {
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();
      final members = List<String>.from(groupDoc.data()?['members'] ?? []);
      final info = await _service.getMemberMentionInfo(members, excludeUid: myUid);
      if (mounted) setState(() => _memberInfo = info);
    } catch (_) {}
  }

  /// Rebuild mention ranges after text changes — remove any whose text no longer matches.
  void _syncMentionRanges(String text) {
    _msgCtrl.mentionRanges.removeWhere((r) {
      if (r.end > text.length) return true;
      final span = text.substring(r.start, r.end);
      return span != '@${r.name}';
    });
  }

  void _onTextChanged() {
    if (_suppressListener) return;

    final text = _msgCtrl.text;
    final selection = _msgCtrl.selection;

    // Sync ranges — remove any that got partially edited
    _syncMentionRanges(text);

    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      if (_showMentions) setState(() => _showMentions = false);
      return;
    }

    final cursorPos = selection.baseOffset;

    // If cursor is inside an existing mention, delete the whole mention
    final hitRange = _msgCtrl.mentionRanges.where((r) => r.contains(cursorPos)).firstOrNull;
    if (hitRange != null) {
      _suppressListener = true;
      final before = text.substring(0, hitRange.start);
      final after = text.substring(hitRange.end);
      final newText = '$before$after';
      final newCursor = hitRange.start;
      _msgCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
      _syncMentionRanges(newText);
      _suppressListener = false;
      setState(() => _showMentions = false);
      return;
    }

    // Find '@' before cursor starting a new word (not inside existing mention)
    int atPos = -1;
    for (var i = cursorPos - 1; i >= 0; i--) {
      final ch = text[i];
      if (ch == '@') {
        if (i == 0 || text[i - 1] == ' ' || text[i - 1] == '\n') {
          // Make sure this @ isn't part of an existing mention
          final inExisting = _msgCtrl.mentionRanges.any((r) => i >= r.start && i < r.end);
          if (!inExisting) {
            atPos = i;
            break;
          }
        }
      } else if (ch == ' ' || ch == '\n') {
        break;
      }
    }

    if (atPos < 0) {
      if (_showMentions) setState(() => _showMentions = false);
      return;
    }

    final query = text.substring(atPos + 1, cursorPos).toLowerCase();
    final filtered = _memberInfo
        .where((m) => (m['name'] ?? '').toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase()));

    setState(() {
      _mentionStartIndex = atPos;
      _mentionSuggestions = filtered;
      _showMentions = filtered.isNotEmpty;
    });
  }

  void _insertMention(Map<String, String> member) {
    final name = member['name'] ?? '';
    final uid = member['uid'] ?? '';
    final text = _msgCtrl.text;
    final cursorPos = _msgCtrl.selection.baseOffset;
    final mentionText = '@$name';

    final before = text.substring(0, _mentionStartIndex);
    final after = text.substring(cursorPos);
    final newText = '$before$mentionText $after';
    final mentionEnd = before.length + mentionText.length;

    _suppressListener = true;
    _msgCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: mentionEnd + 1), // after trailing space
    );

    // Register the atomic mention range
    _msgCtrl.mentionRanges.add(_MentionRange(before.length, mentionEnd, uid, name));
    _suppressListener = false;

    setState(() => _showMentions = false);
  }

  void _scrollToBottom({bool instant = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      if (instant) {
        _scrollCtrl.jumpTo(target);
      } else {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _pendingImage = File(picked.path));
      }
    } catch (_) {}
  }

  void _clearPendingImage() {
    setState(() => _pendingImage = null);
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    final hasImage = _pendingImage != null;
    if (text.isEmpty && !hasImage) return;

    // Collect UIDs from tracked atomic mention ranges only
    final mentionedUids = _msgCtrl.mentionRanges.map((r) => r.uid).toSet().toList();

    _msgCtrl.clear();
    _msgCtrl.mentionRanges.clear();
    final imageToSend = _pendingImage;
    setState(() {
      _sending = true;
      _showMentions = false;
      _pendingImage = null;
    });

    // Upload image first if present
    String? imageUrl;
    if (imageToSend != null) {
      setState(() => _uploadingImage = true);
      imageUrl = await _cloudinary.uploadImage(
        imageToSend,
        folder: 'cmap/chat',
        onError: (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload failed: $err'), backgroundColor: Colors.red),
            );
          }
        },
      );
      if (mounted) setState(() => _uploadingImage = false);
    }

    final error = await _service.sendMessage(widget.groupId, text, imageUrl: imageUrl);
    if (mounted) {
      setState(() => _sending = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else if (mentionedUids.isNotEmpty) {
        // Fire mention notifications (non-blocking) — using exact UIDs
        NotificationService().notifyMentionedByUid(
          groupId: widget.groupId,
          groupName: widget.groupName,
          targetUids: mentionedUids,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName, style: const TextStyle(fontSize: 16)),
            Text('Group Chat', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.mapPin),
            tooltip: 'Share my location',
            onPressed: () async {
              final pos = await _shareMyLocation();
              if (pos && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location shared to group')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                  return const SizedBox.shrink();
                }
                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.messageCircle, size: 48, color: theme.colorScheme.onSurfaceVariant.withAlpha(120)),
                        const SizedBox(height: 8),
                        Text('No messages yet. Say hi!', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                // Only scroll on initial load or when message count changes
                final newCount = messages.length;
                if (_isInitialLoad || newCount != _prevMsgCount) {
                  _scrollToBottom(instant: _isInitialLoad);
                  _isInitialLoad = false;
                }
                _prevMsgCount = newCount;

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMine = msg['senderId'] == myUid;
                    // Look up sender avatar from member info
                    String senderAvatar = '';
                    if (!isMine) {
                      final member = _memberInfo.where((m) => m['uid'] == msg['senderId']).firstOrNull;
                      senderAvatar = member?['imageUrl'] ?? '';
                    }
                    return _MessageBubble(
                      key: ValueKey(msg['id']),
                      msg: msg,
                      isMine: isMine,
                      senderAvatarUrl: senderAvatar,
                      theme: theme,
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    );
                  },
                );
              },
            ),
          ),
          // @mention suggestions panel
          if (_showMentions)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, -2)),
                ],
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _mentionSuggestions.length,
                itemBuilder: (ctx, i) {
                  final member = _mentionSuggestions[i];
                  final name = member['name'] ?? '';
                  final imageUrl = member['imageUrl'] ?? '';
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      child: imageUrl.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSecondaryContainer),
                            )
                          : null,
                    ),
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    onTap: () => _insertMention(member),
                  );
                },
              ),
            ),
          // Pending image preview
          if (_pendingImage != null)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              color: theme.colorScheme.surface,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _pendingImage!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: _clearPendingImage,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: theme.colorScheme.error,
                          child: Icon(LucideIcons.x, size: 12, color: theme.colorScheme.onError),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, -1)),
                ],
              ),
              child: Row(
                children: [
                  // Image attach button
                  IconButton(
                    icon: _uploadingImage
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(LucideIcons.image, size: 22, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: _uploadingImage ? null : _pickImage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: 'Attach image',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: _sending
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                          : Icon(LucideIcons.send, size: 18, color: theme.colorScheme.onPrimary),
                      onPressed: _sending ? null : _send,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _shareMyLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final error = await _service.shareLocationToGroup(widget.groupId, pos.latitude, pos.longitude);
      return error == null;
    } catch (_) {
      return false;
    }
  }
}

/// Extracted message bubble as a separate widget to avoid full list rebuild.
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMine;
  final String senderAvatarUrl;
  final ThemeData theme;
  final double maxWidth;

  const _MessageBubble({
    super.key,
    required this.msg,
    required this.isMine,
    required this.senderAvatarUrl,
    required this.theme,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = (msg['createdAt'] as dynamic)?.toDate() ?? DateTime.now();
    final text = msg['text'] as String? ?? '';
    final imageUrl = msg['imageUrl'] as String? ?? '';
    final hasImage = imageUrl.isNotEmpty;

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );

    final showAvatar = !isMine;
    final senderName = msg['senderName'] ?? '?';
    final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for others' messages
          if (showAvatar) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.secondaryContainer,
              backgroundImage: senderAvatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(senderAvatarUrl)
                  : null,
              child: senderAvatarUrl.isEmpty
                  ? Text(initial, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSecondaryContainer))
                  : null,
            ),
            const SizedBox(width: 6),
          ],
          // Bubble
          Flexible(
            child: Align(
              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isMine ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: bubbleRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image — edge-to-edge, tappable for fullscreen
                    if (hasImage)
                      GestureDetector(
                        onTap: () => _openFullscreenImage(context, imageUrl),
                        child: ClipRRect(
                          borderRadius: bubbleRadius,
                          child: SizedBox(
                            width: double.infinity,
                            height: 200,
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: isMine ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (_, _, _) => Container(
                                color: isMine ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                                child: Icon(LucideIcons.imageOff, size: 32, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Text + metadata with padding
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMine)
                            Text(
                              msg['senderName'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          if (text.isNotEmpty)
                            Text(
                              text,
                              style: TextStyle(
                                color: isMine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            timeAgo(createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMine
                                  ? theme.colorScheme.onPrimary.withAlpha(180)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _openFullscreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          extendBodyBehindAppBar: true,
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, _, _) => const Icon(
                  LucideIcons.imageOff, size: 48, color: Colors.white54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
