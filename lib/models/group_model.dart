import 'model_extensions.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final int memberCount;
  final List<String> members;
  final List<String> pendingRequests;
  final bool isPrivate;
  final List<String> invites;

  GroupModel({
    this.id = '',
    this.name = '',
    this.description = '',
    this.createdBy = '',
    this.createdByName = '',
    required this.createdAt,
    this.memberCount = 0,
    this.members = const [],
    this.pendingRequests = const [],
    this.isPrivate = false,
    this.invites = const [],
  });

  bool get isPublic => !isPrivate;

  GroupModel copyWith({
    String? name,
    String? description,
    int? memberCount,
    List<String>? members,
    List<String>? pendingRequests,
    bool? isPrivate,
    List<String>? invites,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      memberCount: memberCount ?? this.memberCount,
      members: members ?? this.members,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      isPrivate: isPrivate ?? this.isPrivate,
      invites: invites ?? this.invites,
    );
  }

  factory GroupModel.fromMap(String id, Map<String, dynamic> map) {
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: map.parseTimestamp('createdAt'),
      memberCount: map['memberCount'] ?? 0,
      members: List<String>.from(map['members'] ?? []),
      pendingRequests: List<String>.from(map['pendingRequests'] ?? []),
      isPrivate: (map['isPrivate'] as bool?) ?? false,
      invites: List<String>.from((map['invites'] as List<dynamic>?) ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt,
      'memberCount': memberCount,
      'members': members,
      'pendingRequests': pendingRequests,
      'isPrivate': isPrivate,
      'invites': invites,
    };
  }
}
