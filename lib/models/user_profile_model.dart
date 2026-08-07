import 'model_extensions.dart';

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String bio;
  final String phone;
  final String location;
  final String dateOfBirth;
  final String imageUrl;
  final String bloodGroup;
  final String hobby;
  final DateTime createdAt;

  UserProfile({
    this.uid = '',
    this.fullName = '',
    this.email = '',
    this.bio = '',
    this.phone = '',
    this.location = '',
    this.dateOfBirth = '',
    this.imageUrl = '',
    this.bloodGroup = '',
    this.hobby = '',
    required this.createdAt,
  });

  UserProfile copyWith({
    String? fullName,
    String? bio,
    String? phone,
    String? location,
    String? dateOfBirth,
    String? imageUrl,
    String? bloodGroup,
    String? hobby,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      imageUrl: imageUrl ?? this.imageUrl,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      hobby: hobby ?? this.hobby,
      createdAt: createdAt,
    );
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      hobby: map['hobby'] ?? '',
      createdAt: map.parseTimestamp('createdAt'),
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
      'imageUrl': imageUrl,
      'bloodGroup': bloodGroup,
      'hobby': hobby,
      'createdAt': createdAt,
    };
  }
}
