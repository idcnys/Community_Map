import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared time-ago formatter used across feed, notifications, and comments.
/// All output is in Bengali with Bengali numerals.

const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

const _bnMonths = [
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

/// Convert an integer to Bengali numerals.
String bnNum(int n) =>
    n.toString().split('').map((d) => _bnDigits[int.parse(d)]).join();

/// Time-only format in Bengali (e.g. "পূর্বাহ্ণ ৯:০৫").
String formatTimeBn(DateTime dt) => _bnTime(dt);

String _bnTime(DateTime dt) {
  final hour24 = dt.hour;
  final suffix = hour24 < 12 ? 'পূর্বাহ্ণ' : 'অপরাহ্ণ';
  var hour12 = hour24 % 12;
  if (hour12 == 0) hour12 = 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$suffix ${bnNum(hour12)}:${bnNum(int.parse(minute))}';
}

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'এইমাত্র';
  if (diff.inMinutes < 60) return '${bnNum(diff.inMinutes)} মিনিট আগে';
  if (diff.inHours < 24) return '${bnNum(diff.inHours)} ঘণ্টা আগে';
  if (diff.inDays < 7) return '${bnNum(diff.inDays)} দিন আগে';
  return formatShortDate(date);
}

/// Full date format for detail views.
String formatFullDate(DateTime date) {
  return '${bnNum(date.day)} ${_bnMonths[date.month - 1]}, ${bnNum(date.year)} • ${_bnTime(date)}';
}

/// Short date format for cards and lists.
String formatShortDate(DateTime date) {
  return '${bnNum(date.day)} ${_bnMonths[date.month - 1]}, ${_bnTime(date)}';
}

/// English short month names (e.g. "Aug").
const _enMonthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Format a date-of-birth value into "21 Aug 2005" style.
/// Accepts ISO 8601 strings, `DD/MM/YYYY` strings, Firestore Timestamps,
/// or already-formatted output. Returns 'নির্ধারিত নয়' when empty/invalid.
String formatDateOfBirth(dynamic dob) {
  if (dob == null) return 'নির্ধারিত নয়';

  // Firestore Timestamp
  if (dob is Timestamp) {
    final dt = dob.toDate();
    return '${dt.day} ${_enMonthsShort[dt.month - 1]} ${dt.year}';
  }

  final raw = dob.toString().trim();
  if (raw.isEmpty) return 'নির্ধারিত নয়';

  // Already in "21 Aug 2005" style (contains a short month name)
  if (_enMonthsShort.any((m) => raw.contains(m))) return raw;

  // ISO 8601 (e.g. 2005-08-21T00:00:00.000)
  final iso = DateTime.tryParse(raw);
  if (iso != null && raw.contains('-')) {
    return '${iso.day} ${_enMonthsShort[iso.month - 1]} ${iso.year}';
  }

  // DD/MM/YYYY
  final parts = raw.split('/');
  if (parts.length == 3) {
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day != null && month != null && year != null &&
        month >= 1 && month <= 12) {
      return '$day ${_enMonthsShort[month - 1]} $year';
    }
  }

  return raw;
}
