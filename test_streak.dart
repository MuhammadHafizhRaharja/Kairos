void main() {
  final logs = [
    DateTime(2026, 6, 17, 10, 0),
    DateTime(2026, 6, 16, 10, 0),
    DateTime(2026, 6, 15, 10, 0),
    DateTime(2026, 6, 14, 10, 0),
    DateTime(2026, 6, 13, 10, 0),
  ];

  final uniqueDays = logs
      .map((l) => DateTime(l.year, l.month, l.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (uniqueDays.isEmpty) { print('0 empty'); return; }
  
  print('First unique day: ${uniqueDays.first}');
  print('Today: $today');
  print('Yesterday: $yesterday');

  if (uniqueDays.first != today && uniqueDays.first != yesterday) {
    print('0 not today/yesterday');
    return;
  }

  int streak = 1;
  for (int i = 1; i < uniqueDays.length; i++) {
    final diff = uniqueDays[i - 1].difference(uniqueDays[i]).inDays;
    print('Diff between ${uniqueDays[i-1]} and ${uniqueDays[i]} is $diff');
    if (diff == 1) {
      streak++;
    } else {
      break;
    }
  }
  print('Streak: $streak');
}
