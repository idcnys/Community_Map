
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;

  Stream<UserProfile?> getProfile() {
    return _firestore
        .collection('users')
        .doc(currentUid)
        .snapshots()
        .map((snap) =>
            snap.exists ? UserProfile.fromMap(snap.id, snap.data()!) : null);
  }

  Future<String?> updateProfile({
    required String fullName,
    String bio = '',
    String phone = '',
    String location = '',
    String dateOfBirth = '',
    String bloodGroup = '',
    String hobby = '',
    String? imageUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(currentUid).update({
        'fullName': fullName,
        'bio': bio,
        'phone': phone,
        'location': location,
        'dateOfBirth': dateOfBirth,
        'bloodGroup': bloodGroup,
        'hobby': hobby,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
      // Also update Firebase Auth display name
      await _auth.currentUser?.updateDisplayName(fullName);
      return null;
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }
}
