
import 'package:flutter/material.dart';
import '../../core/utils/time_ago.dart';
import '../../services/community_post_service.dart';
import '../../models/notification_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'comments_page.dart';

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

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.alertCircle, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text('Failed to load notifications',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              );
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
                          Icon(LucideIcons.bell,
                              size: 64, color: theme.colorScheme.onSurfaceVariant.withAlpha(150)),
                          const SizedBox(height: 12),
                          Text('No notifications yet',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
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
    final theme = Theme.of(context);
    IconData icon;
    Color iconColor;

    switch (notif.type) {
      case 'like':
        icon = LucideIcons.thumbsUp;
        iconColor = theme.colorScheme.primary;
        break;
      case 'comment':
        icon = LucideIcons.messageCircle;
        iconColor = theme.colorScheme.primary;
        break;
      case 'new_post':
        icon = LucideIcons.fileText;
        iconColor = theme.colorScheme.tertiary;
        break;
      default:
        icon = LucideIcons.bell;
        iconColor = theme.colorScheme.onSurfaceVariant;
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
        timeAgo(notif.createdAt ?? DateTime.now()),
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
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
      onTap: () {
        service.markNotificationRead(notif.id);
        if (notif.postId.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CommentsPage(postId: notif.postId),
            ),
          );
        }
      },
    );
  }


}
