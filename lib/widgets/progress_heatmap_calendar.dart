import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';

/// Custom Widget: Kalender Heatmap Interaktif
/// Menggunakan library `table_calendar` untuk menampilkan kalender
/// yang diwarnai sesuai intensitas aktivitas harian pengguna.
/// Ini memenuhi kriteria Assessment 3:
/// - Custom Widget yang fungsional (menampilkan data analitik)
/// - Menggunakan library eksternal (table_calendar)
class ProgressHeatmapCalendar extends StatefulWidget {
  const ProgressHeatmapCalendar({super.key});

  @override
  State<ProgressHeatmapCalendar> createState() =>
      _ProgressHeatmapCalendarState();
}

class _ProgressHeatmapCalendarState extends State<ProgressHeatmapCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ProgressProvider>();
    final activityMap = provider.getActivityMap();

    // Cari intensitas max untuk normalisasi
    final maxCount =
        activityMap.values.isEmpty ? 1 : activityMap.values.reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_month_rounded,
                      color: theme.colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Kalender Aktivitas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 30)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
              leftChevronIcon: Icon(Icons.chevron_left_rounded,
                  color: theme.colorScheme.primary),
              rightChevronIcon: Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.primary),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              weekendStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              todayTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              defaultTextStyle: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
              weekendTextStyle: TextStyle(
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            // [PENTING] Bagian ini memodifikasi tampilan kotak-kotak tanggal secara kustom.
            // Fitur inilah yang mengubah kalender biasa menjadi "Heatmap Kalender" (Gamifikasi).
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                // Menyamakan format tanggal agar mengabaikan jam/menit
                final normalizedDay =
                    DateTime(day.year, day.month, day.day);
                
                // Menarik data "Berapa banyak aktivitas di hari ini?" dari Provider
                final count = activityMap[normalizedDay] ?? 0;

                // Jika ada aktivitas, kotak kalender akan diwarnai
                if (count > 0) {
                  // Menghitung rasio intensitas warna (semakin sering belajar = semakin gelap).
                  // Nilai dibatasi (clamp) minimal 0.3 agar tetap terlihat, maksimal 1.0 (warna solid).
                  final intensity = (count / maxCount).clamp(0.3, 1.0);
                  
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      // Menerapkan warna dengan transparansi (alpha) berdasarkan intensitas tadi
                      color: theme.colorScheme.primary
                          .withValues(alpha: intensity * 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          // Jika warnanya gelap (intensitas tinggi), teks diubah jadi putih agar terbaca
                          color: intensity > 0.5
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }
                // Kembalikan null jika tidak ada aktivitas (menggunakan tampilan bawaan kalender)
                return null;
              },
              markerBuilder: (context, day, events) {
                final normalizedDay =
                    DateTime(day.year, day.month, day.day);
                final count = activityMap[normalizedDay] ?? 0;

                if (count > 0) {
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          // Legenda Heatmap
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sedikit',
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45),
                ),
                const SizedBox(width: 6),
                ...List.generate(5, (i) {
                  final intensity = (i + 1) / 5;
                  return Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: intensity * 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                Text(
                  'Banyak',
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45),
                ),
              ],
            ),
          ),
          // Info hari terpilih
          if (_selectedDay != null) ...[
            Builder(builder: (context) {
              final normalizedSelected = DateTime(
                  _selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
              final dayCount = activityMap[normalizedSelected] ?? 0;
              final dayLogs = provider.logs.where((log) {
                final logDay =
                    DateTime(log.date.year, log.date.month, log.date.day);
                return logDay == normalizedSelected;
              }).toList();
              final totalMinutes =
                  dayLogs.fold<int>(0, (sum, log) => sum + log.durationMinutes);

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dayCount > 0
                            ? '$dayCount aktivitas • $totalMinutes menit belajar'
                            : 'Belum ada aktivitas di hari ini',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
