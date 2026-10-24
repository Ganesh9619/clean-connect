import 'package:intl/intl.dart';

String money(int dollars) => '\$$dollars';

String formatSlot(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(value.year, value.month, value.day);
  final time = DateFormat('h:mm a').format(value);
  if (day == today) return 'Today, $time';
  if (day == today.add(const Duration(days: 1))) return 'Tomorrow, $time';
  return '${DateFormat('EEE, MMM d').format(value)}, $time';
}

String formatHours(double hours) {
  final whole = hours == hours.roundToDouble();
  return '${whole ? hours.toInt() : hours} hrs';
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}
