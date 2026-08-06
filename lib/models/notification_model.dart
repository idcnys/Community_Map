
class AppNotificationModel {
  final String id;
  final String type; // 'new_post', 'comment', 'like'
  final String targetUserId; // who receives this notification
  final String actorId; // who triggered it
  final String actorName;
  final String postId;
  final String postTitle;
  final String message;
  final bool read;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    required this.type,
    required this.targetUserId,
    required this.actorId,
    required this.actorName,
    required this.postId,
    this.postTitle = '',
    this.message = '',
    this.read = false,
    required this.createdAt,
  });

  factory AppNotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return AppNotificationModel(
      id: id,
      type: map['type'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? '',
      postId: map['postId'] ?? '',
      postTitle: map['postTitle'] ?? '',
      message: map['message'] ?? '',
      read: map['read'] ?? false,
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'targetUserId': targetUserId,
      'actorId': actorId,
      'actorName': actorName,
      'postId': postId,
      'postTitle': postTitle,
      'message': message,
      'read': read,
      'createdAt': createdAt,
    };
  }
}
