import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';

@freezed
abstract class AppNotificationModel with _$AppNotificationModel {
  const AppNotificationModel._();

  const factory AppNotificationModel({
    @Default('') String id,
    @Default('') String type,
    @Default('') String targetUserId,
    @Default('') String actorId,
    @Default('') String actorName,
    @Default('') String postId,
    @Default('') String postTitle,
    @Default('') String message,
    @Default(false) bool read,
    @Default(null) DateTime? createdAt,
  }) = _AppNotificationModel;

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
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
