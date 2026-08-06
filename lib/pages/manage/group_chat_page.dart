import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/group_chat_service.dart';
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

class _GroupChatPageState extends State<GroupChatPage> {
  final _service = GroupChatService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  int _prevMsgCount = 0;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _service.markGroupAsRead(widget.groupId);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    final error = await _service.sendMessage(widget.groupId, text);
    if (mounted) {
      setState(() => _sending = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
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
              stream: _service.getGroupMessages(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                  itemBuilder: (ctx, i) => _MessageBubble(
                    msg: messages[i],
                    isMine: messages[i]['senderId'] == myUid,
                    theme: theme,
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                );
              },
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
  final ThemeData theme;
  final double maxWidth;

  const _MessageBubble({
    required this.msg,
    required this.isMine,
    required this.theme,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = (msg['createdAt'] as dynamic)?.toDate() ?? DateTime.now();
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: isMine ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
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
            Text(
              msg['text'] ?? '',
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
    );
  }
}
