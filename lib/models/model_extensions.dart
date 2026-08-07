import 'package:cloud_firestore/cloud_firestore.dart';

/// Extension on Firestore document maps for consistent timestamp parsing.
extension FirestoreMapX on Map<String, dynamic> {
  /// Safely parse a Firestore Timestamp field into [DateTime].
  DateTime parseTimestamp(String key, {DateTime? fallback}) {
    final val = this[key];
    if (val is Timestamp) return val.toDate();
    return fallback ?? DateTime.now();
  }

  /// Convert a DateTime field back to Firestore Timestamp for writes.
  Object toTimestampValue(DateTime? date) {
    if (date == null) return FieldValue.serverTimestamp();
    return Timestamp.fromDate(date);
  }
}

/// Mixin for models that have an author.
mixin AuthorOwned {
  String get authorId;
  String get authorName;

  bool get hasAuthor => authorId.isNotEmpty;
}
