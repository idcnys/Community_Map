import 'package:intl/intl.dart';

/// Shared time-ago formatter used across feed, notifications, and comments.
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d, h:mm a').format(date);
}

/// Full date format for detail views.
String formatFullDate(DateTime date) {
  return DateFormat('MMMM d, yyyy • h:mm a').format(date);
}

/// Short date format for cards and lists.
String formatShortDate(DateTime date) {
  return DateFormat('MMM d, h:mm a').format(date);
}
