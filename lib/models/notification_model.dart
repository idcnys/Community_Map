import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_extensions.dart';

class AppNotificationModel {
  final String id;
  final String type;
  final String targetUserId;
  final String actorId;
  final String actorName;
  final String postId;
  final String postTitle;
  final String message;
  final bool read;
  final DateTime? createdAt;

  AppNotificationModel({
    this.id = '',
    this.type = '',
    this.targetUserId = '',
    this.actorId = '',
    this.actorName = '',
    this.postId = '',
    this.postTitle = '',
    this.message = '',
    this.read = false,
    this.createdAt,
  });

  AppNotificationModel copyWith({
    bool? read,
    String? message,
  }) {
    return AppNotificationModel(
      id: id,
      type: type,
      targetUserId: targetUserId,
      actorId: actorId,
      actorName: actorName,
      postId: postId,
      postTitle: postTitle,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

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
      createdAt: map.parseTimestamp('createdAt'),
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
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
