class ReportPostModel {
  final String id;
  final String contactNumber;
  final String reportType; // theft, robbery, threat, fire, etc.
  final String description;
  final double latitude;
  final double longitude;
  final String authorId;
  final String authorName;
  final List<String> sharedGroupIds; // groups that can see contact
  final String origin; // 'public' or 'urgent'
  final String imageUrl;
  final DateTime createdAt;
  final String status; // 'active' or 'solved'
  final Map<String, String> votes; // userId -> 'appropriate' | 'spam'
  final int viewCount;

  ReportPostModel({
    required this.id,
    required this.contactNumber,
    required this.reportType,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.authorId,
    required this.authorName,
    this.sharedGroupIds = const [],
    this.origin = 'public',
    this.imageUrl = '',
    required this.createdAt,
    this.status = 'active',
    this.votes = const {},
    this.viewCount = 0,
  });

  bool get isUrgent => origin == 'urgent';

  bool get isSolved => status == 'solved';

  bool get isArchived =>
      isSolved || DateTime.now().difference(createdAt).inHours > 48;

  int get appropriateCount =>
      votes.values.where((v) => v == 'appropriate').length;

  int get spamCount => votes.values.where((v) => v == 'spam').length;

  /// Whether the given user can see the contact number
  bool canSeeContact(String userId, List<String> userGroupIds) {
    if (authorId == userId) return true;
    return sharedGroupIds.any((gid) => userGroupIds.contains(gid));
  }

  factory ReportPostModel.fromMap(String id, Map<String, dynamic> map) {
    return ReportPostModel(
      id: id,
      contactNumber: map['contactNumber'] ?? '',
      reportType: map['reportType'] ?? 'other',
      description: map['description'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      sharedGroupIds: List<String>.from(map['sharedGroupIds'] ?? []),
      origin: map['origin'] ?? 'public',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'active',
      votes: Map<String, String>.from(map['votes'] ?? {}),
      viewCount: map['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contactNumber': contactNumber,
      'reportType': reportType,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'authorId': authorId,
      'authorName': authorName,
      'sharedGroupIds': sharedGroupIds,
      'origin': origin,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'status': status,
      'votes': votes,
      'viewCount': viewCount,
    };
  }
}

/// Report type options for the dropdown
class ReportTypes {
  static const List<String> options = [
    'Theft',
    'Robbery',
    'Threat',
    'Fire',
    'Accident',
    'Vandalism',
    'Suspicious Activity',
    'Domestic Violence',
    'Missing Person',
    'Other',
  ];

  static const String urgentType = 'Urgent Emergency';
}

/// A comment on a report post
class ReportComment {
  final String id;
  final String reportId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  ReportComment({
    required this.id,
    required this.reportId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory ReportComment.fromMap(String id, Map<String, dynamic> map) {
    return ReportComment(
      id: id,
      reportId: map['reportId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'authorId': authorId,
      'authorName': authorName,
      'text': text,
      'createdAt': createdAt,
    };
  }
}
