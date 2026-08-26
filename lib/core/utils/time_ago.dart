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
    n.toString().split('').map((d) => _bnDigits[int.parse(d)!]).join();

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
