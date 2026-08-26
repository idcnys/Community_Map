import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/time_ago.dart';
import '../../providers/service_providers.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'comments_page.dart';

import '../../models/report_post_model.dart';
import '../map/report_detail_sheet.dart';

class NotificationPanel extends ConsumerWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(notificationServiceProvider);
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
                    Text('বিজ্ঞপ্তি লোড করতে ব্যর্থ হয়েছে',
                        style: TextStyle(fontFamily: 'EkusheInter', color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}',
                        style: TextStyle(fontFamily: 'EkusheInter', fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            return CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'বিজ্ঞপ্তি',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => service.markAllRead(),
                              child: const Text('সব পড়া হয়েছে'),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                              ),
                              onPressed: notifications.isEmpty
                                  ? null
                                  : () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('সব বিজ্ঞপ্তি মুছে ফেলবেন?'),
                                          content: const Text(
                                            'এটি আপনার সব বিজ্ঞপ্তি স্থায়ীভাবে মুছে ফেলবে।',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: const Text('বাতিল'),
                                            ),
                                            FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: theme.colorScheme.error,
                                              ),
                                              onPressed: () {
                                                Navigator.of(ctx).pop();
                                                service.clearAll();
                                              },
                                              child: const Text('সব মুছুন'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                              child: const Text('সব মুছুন'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Divider(height: 1)),
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
                          Text('এখনও কোনো বিজ্ঞপ্তি নেই',
                              style: TextStyle(fontFamily: 'EkusheInter', color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildNotificationTile(context, ref, service, notifications[i]),
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
    WidgetRef ref,
    NotificationService service,
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
      case 'mention':
        icon = LucideIcons.atSign;
        iconColor = Colors.blue;
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
      onTap: () async {
        service.markRead(notif.id);

        if (notif.type == 'mention') {
          // GC mention notification -> open GroupDetailPage
          // postId field stores groupId for mention notifications
          if (notif.postId.isEmpty) return;
          Navigator.of(context).pop(); // close notification sheet
          router.go('/dashboard/group/${notif.postId}');
        } else if (notif.type == 'new_report') {
          // Map report notification -> open ReportDetailSheet
          if (notif.postId.isEmpty) return;
          final reportService = ref.read(reportPostServiceProvider);
          final report = await reportService.getReportById(notif.postId);
          if (report == null || !context.mounted) return;
          Navigator.of(context).pop(); // close notification sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => ReportDetailSheet(report: report),
          );
        } else {
          // Feed post notification -> open CommentsPage
          if (notif.postId.isEmpty) return;
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
