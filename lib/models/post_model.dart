
class PostModel {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String targetGroupId; // 'public' or a group ID
  final String targetGroupName;
  final List<String> tags;
  final DateTime createdAt;
  final int commentCount;
  final Map<String, int> reactions; // {'like': 3, 'love': 1, ...}

  PostModel({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.targetGroupId,
    required this.targetGroupName,
    this.tags = const [],
    required this.createdAt,
    this.commentCount = 0,
    this.reactions = const {},
  });

  bool get isPublic => targetGroupId == 'public';

  int get totalReactions => reactions.values.fold(0, (a, b) => a + b);

  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      targetGroupId: map['targetGroupId'] ?? 'public',
      targetGroupName: map['targetGroupName'] ?? 'Public',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      commentCount: map['commentCount'] ?? 0,
      reactions: Map<String, int>.from(map['reactions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'targetGroupId': targetGroupId,
      'targetGroupName': targetGroupName,
      'tags': tags,
      'createdAt': createdAt,
      'commentCount': commentCount,
      'reactions': reactions,
    };
  }
}

class CommentModel {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  factory CommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommentModel(
      id: id,
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String bio;
  final String phone;
  final String location;
  final String dateOfBirth;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.bio = '',
    this.phone = '',
    this.location = '',
    this.dateOfBirth = '',
    required this.createdAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'bio': bio,
      'phone': phone,
      'location': location,
      'dateOfBirth': dateOfBirth,
      'createdAt': createdAt,
    };
  }
}
