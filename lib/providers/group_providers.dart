import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import 'service_providers.dart';

/// Search query state for discover tab.
final groupSearchQueryProvider = NotifierProvider<GroupSearchNotifier, String>(
  GroupSearchNotifier.new,
);

class GroupSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

/// Search results for discover tab.
final searchGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final service = ref.watch(groupServiceProvider);
  final query = ref.watch(groupSearchQueryProvider);
  return service.searchGroups(query);
});

/// User's created groups.
final myCreatedGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final service = ref.watch(groupServiceProvider);
  return service.getMyCreatedGroups();
});

/// User's joined groups.
final myJoinedGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final service = ref.watch(groupServiceProvider);
  return service.getMyJoinedGroups();
});

/// User's pending join requests.
final myPendingRequestsProvider = StreamProvider<List<GroupModel>>((ref) {
  final service = ref.watch(groupServiceProvider);
  return service.getMyPendingRequests();
});

/// Single group by ID.
final groupByIdProvider = StreamProvider.family<GroupModel?, String>((ref, groupId) {
  final service = ref.watch(groupServiceProvider);
  return service.getGroupById(groupId);
});

/// User's pending invites (private groups they've been invited to).
final myInvitesProvider = StreamProvider<List<GroupModel>>((ref) {
  final service = ref.watch(groupServiceProvider);
  return service.getMyInvites();
});
