
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

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.memberCount = 0,
    this.members = const [],
    this.pendingRequests = const [],
  });

  factory GroupModel.fromMap(String id, Map<String, dynamic> map) {
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      memberCount: map['memberCount'] ?? 0,
      members: List<String>.from(map['members'] ?? []),
      pendingRequests: List<String>.from(map['pendingRequests'] ?? []),
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
    };
  }

  bool get isPublic => true; // All groups are discoverable via search

  GroupModel copyWith({
    String? name,
    String? description,
    int? memberCount,
    List<String>? members,
    List<String>? pendingRequests,
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
    );
  }
}
