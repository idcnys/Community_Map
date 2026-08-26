import 'model_extensions.dart';

class ReportPostModel with AuthorOwned {
  final String id;
  final String contactNumber;
  final String reportType;
  final String description;
  final double latitude;
  final double longitude;
  @override
  final String authorId;
  @override
  final String authorName;
  final List<String> sharedGroupIds;
  final String origin;
  final String imageUrl;
  final String audioUrl;
  final DateTime createdAt;
  final String status;
  final Map<String, String> votes;
  final int viewCount;

  ReportPostModel({
    this.id = '',
    this.contactNumber = '',
    this.reportType = 'other',
    this.description = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.authorId = '',
    this.authorName = '',
    this.sharedGroupIds = const [],
    this.origin = 'public',
    this.imageUrl = '',
    this.audioUrl = '',
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

  bool canSeeContact(String userId, List<String> userGroupIds) {
    if (authorId == userId) return true;
    return sharedGroupIds.any((gid) => userGroupIds.contains(gid));
  }

  ReportPostModel copyWith({
    String? status,
    int? viewCount,
    Map<String, String>? votes,
    String? imageUrl,
    String? audioUrl,
  }) {
    return ReportPostModel(
      id: id,
      contactNumber: contactNumber,
      reportType: reportType,
      description: description,
      latitude: latitude,
      longitude: longitude,
      authorId: authorId,
      authorName: authorName,
      sharedGroupIds: sharedGroupIds,
      origin: origin,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      createdAt: createdAt,
      status: status ?? this.status,
      votes: votes ?? this.votes,
      viewCount: viewCount ?? this.viewCount,
    );
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
      audioUrl: map['audioUrl'] ?? '',
      createdAt: map.parseTimestamp('createdAt'),
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
      'audioUrl': audioUrl,
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
    'চুরি',
    'ডাকাতি',
    'হুমকি',
    'আগুন',
    'দুর্ঘটনা',
    'ধ্বংসযজ্ঞ',
    'সন্দেহজনক কার্যকলাপ',
    'পারিবারিক সহিংসতা',
    'নিখোঁজ ব্যক্তি',
    'অন্যান্য',
  ];

  static const String urgentType = 'Urgent Emergency';
}
