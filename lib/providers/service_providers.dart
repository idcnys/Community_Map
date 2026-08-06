import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/community_post_service.dart';
import '../services/group_service.dart';
import '../services/profile_service.dart';
import '../services/report_post_service.dart';
import '../services/view_count_batcher.dart';
import '../shared/services/user_group_service.dart';

/// Singleton service providers — eliminates per-build instantiation.
final communityPostServiceProvider = Provider<CommunityPostService>((ref) {
  return CommunityPostService();
});

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService();
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final reportPostServiceProvider = Provider<ReportPostService>((ref) {
  return ReportPostService();
});

final userGroupServiceProvider = Provider<UserGroupService>((ref) {
  return UserGroupService();
});

/// View count batcher: accumulates view events, flushes every 10s.
final viewCountBatcherProvider = Provider<ViewCountBatcher>((ref) {
  final service = ref.watch(communityPostServiceProvider);
  final batcher = ViewCountBatcher(service: service);

  // Flush remaining views when provider is disposed (app exit).
  ref.onDispose(() => batcher.dispose());

  return batcher;
});
