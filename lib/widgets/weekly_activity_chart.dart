import 'package:flutter/material.dart';

/// Widget kustom untuk menampilkan diagram batang aktivitas mingguan (Weekly Activity Bar Chart).
/// Memberikan nuansa visual pelacakan yang premium dan profesional.
class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Data aktivitas mingguan (simulasi statis untuk visualisasi performa)
    final List<double> activityHeights = [0.35, 0.6, 0.45, 0.8, 0.55, 0.9, 0.4];
    final List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final int todayIndex = DateTime.now().weekday - 1; // 0 untuk Senin, dst.

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.05),
          width: 1,
        ),
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
                final isToday = index == todayIndex;
                final barColor = isToday
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.3);

                return Column(
                  children: [
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
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isToday
                            ? theme.colorScheme.primary
                            : theme.hintColor,
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
