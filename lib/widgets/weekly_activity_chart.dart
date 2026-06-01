import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';

/// Widget kustom untuk menampilkan diagram batang aktivitas mingguan (Weekly Activity Bar Chart).
/// Memberikan nuansa visual pelacakan yang premium dan profesional.
class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progressProvider = context.watch<ProgressProvider>();
    final logs = progressProvider.logs;

    // Hitung aktivitas mingguan dari SQLite (Progress logs) untuk minggu berjalan (Senin-Minggu)
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));

    final List<int> dailyDurations = List.generate(7, (index) {
      final dayDate = DateTime(currentMonday.year, currentMonday.month, currentMonday.day).add(Duration(days: index));
      return logs
          .where((log) =>
              log.date.year == dayDate.year &&
              log.date.month == dayDate.month &&
              log.date.day == dayDate.day)
          .fold<int>(0, (sum, log) => sum + log.durationMinutes);
    });

    final int maxDuration = dailyDurations.reduce((a, b) => a > b ? a : b);
    final double divisor = maxDuration > 0 ? maxDuration.toDouble() : 60.0;

    final List<double> activityHeights = dailyDurations.map((d) => d / divisor).toList();
    final List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final int todayIndex = now.weekday - 1; // 0 untuk Senin, dst.

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
              ? theme.dividerColor.withValues(alpha: 0.08)
              : theme.colorScheme.primary.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aktivitas Belajar Mingguan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.bar_chart_rounded,
                  color: theme.colorScheme.secondary,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final heightFactor = activityHeights[index];
                final duration = dailyDurations[index];
                final isToday = index == todayIndex;
                final barColor = isToday
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.3);

                return Column(
                  children: [
                    SizedBox(
                      height: 14,
                      child: Text(
                        duration > 0 ? '${duration}m' : '',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? theme.colorScheme.primary : theme.hintColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 100,
                      width: 14,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.fastOutSlowIn,
                        height: 100 * heightFactor,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [barColor.withValues(alpha: 0.7), barColor],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isToday
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? theme.colorScheme.primary : theme.hintColor,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
