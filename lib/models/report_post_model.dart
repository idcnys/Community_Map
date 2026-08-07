
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
  });

  bool get isUrgent => origin == 'urgent';

  bool get isArchived =>
      DateTime.now().difference(createdAt).inHours > 48;

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
