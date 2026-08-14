import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/post_service.dart';
import '../services/notification_service.dart';
import '../services/poll_service.dart';
import '../services/group_service.dart';
import '../services/group_chat_service.dart';
import '../services/profile_service.dart';
import '../services/report_post_service.dart';
import '../services/cloudinary_service.dart';
import '../services/push_notification_service.dart';
import '../services/view_count_batcher.dart';
import '../shared/services/user_group_service.dart';

/// Singleton service providers — eliminates per-build instantiation.

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final postServiceProvider = Provider<PostService>((ref) {
  return PostService(
    notificationService: ref.watch(notificationServiceProvider),
  );
});

final pollServiceProvider = Provider<PollService>((ref) {
  return PollService();
});

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService();
});

final groupChatServiceProvider = Provider<GroupChatService>((ref) {
  return GroupChatService();
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final reportPostServiceProvider = Provider<ReportPostService>((ref) {
  return ReportPostService();
});

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

final userGroupServiceProvider = Provider<UserGroupService>((ref) {
  return UserGroupService();
});

/// View count batcher: accumulates view events, flushes every 10s.
final viewCountBatcherProvider = Provider<ViewCountBatcher>((ref) {
  final service = ref.watch(postServiceProvider);
  final batcher = ViewCountBatcher(service: service);

  // Flush remaining views when provider is disposed (app exit).
  ref.onDispose(() => batcher.dispose());

  return batcher;
});
