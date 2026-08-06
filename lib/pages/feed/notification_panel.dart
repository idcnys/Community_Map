
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/community_post_service.dart';
import '../../models/notification_model.dart';

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CommunityPostService();
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return StreamBuilder<List<AppNotificationModel>>(
          stream: service.getMyNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data ?? [];

            return CustomScrollView(
              controller: scrollController,
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => service.markAllNotificationsRead(),
                          child: const Text('Mark all read'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Divider(height: 1)),
                // Notification list
                if (notifications.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('No notifications yet',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildNotificationTile(context, service, notifications[i]),
                      childCount: notifications.length,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    CommunityPostService service,
    AppNotificationModel notif,
  ) {
    IconData icon;
    Color iconColor;

    switch (notif.type) {
      case 'like':
        icon = Icons.thumb_up;
        iconColor = Colors.blue;
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = Colors.green;
        break;
      case 'new_post':
        icon = Icons.article;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.15),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        notif.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: notif.read ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _timeAgo(notif.createdAt),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
      trailing: notif.read
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      onTap: () => service.markNotificationRead(notif.id),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(date);
  }
}
