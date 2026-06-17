import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/progress_provider.dart';
import '../providers/skill_provider.dart';
import '../models/progress_log.dart';
import '../models/challenge.dart';
import '../models/skill.dart';
import '../widgets/interactive_duration_slider.dart';
import '../widgets/progress_heatmap_calendar.dart';
import '../widgets/celebration_dialog.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final skillProv = context.watch<SkillProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            skillProv.translate('progress_journal'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: skillProv.translate('activity_log'), icon: const Icon(Icons.history_edu)),
              Tab(text: skillProv.translate('challenges'), icon: const Icon(Icons.emoji_events)),
              Tab(
                text: skillProv.defaultLang == 'id' ? 'Analitik' : 'Analytics',
                icon: const Icon(Icons.insights_rounded),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProgressLogsView(),
            _ChallengesView(),
            _AnalyticsView(),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 96.0),
          child: FloatingActionButton(
            onPressed: () => _showAddDialog(context),
            backgroundColor: theme.colorScheme.primary,
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final skillProv = Provider.of<SkillProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            title: Text(skillProv.translate('add_new')),
            content: SizedBox(
              width: double.maxFinite,
              height: 480,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: skillProv.translate('log')),
                      Tab(text: skillProv.translate('challenges')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        _AddLogForm(),
                        _AddChallengeForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// TAB 3: ANALITIK (NEW - Assessment 3)
// =============================================================================
class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final streak = provider.calculateCurrentStreak();
    final challengeStats = provider.getChallengeStats();
    final last7Days = provider.getLast7DaysDuration();
    final totalLogs = provider.logs.length;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // === Stat Cards Row ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.orange,
                    label: 'Streak',
                    value: '$streak hari',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.history_edu_rounded,
                    iconColor: theme.colorScheme.primary,
                    label: 'Total Log',
                    value: '$totalLogs',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.emoji_events_rounded,
                    iconColor: Colors.amber,
                    label: 'Selesai',
                    value: '${challengeStats['completed']}/${challengeStats['total']}',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // === Grafik Garis 7 Hari (fl_chart) ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.show_chart_rounded,
                            color: theme.colorScheme.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Durasi Belajar 7 Hari Terakhir',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: last7Days.every((e) => e.value == 0)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart_rounded,
                                    size: 48,
                                    color: theme.hintColor.withValues(alpha: 0.3)),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada data minggu ini',
                                  style: TextStyle(color: theme.hintColor),
                                ),
                              ],
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 30,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.05),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= last7Days.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final day = last7Days[index].key;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          DateFormat('E').format(day).substring(0, 2),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white54 : Colors.black45,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '${value.toInt()}m',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? Colors.white38 : Colors.black38,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    last7Days.length,
                                    (i) => FlSpot(i.toDouble(), last7Days[i].value),
                                  ),
                                  isCurved: true,
                                  curveSmoothness: 0.35,
                                  color: theme.colorScheme.primary,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, bar, index) {
                                      return FlDotCirclePainter(
                                        radius: 4,
                                        color: theme.colorScheme.primary,
                                        strokeWidth: 2,
                                        strokeColor: Colors.white,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        theme.colorScheme.primary.withValues(alpha: 0.3),
                                        theme.colorScheme.primary.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (spot) =>
                                      theme.colorScheme.primary.withValues(alpha: 0.9),
                                  getTooltipItems: (spots) {
                                    return spots.map((spot) {
                                      return LineTooltipItem(
                                        '${spot.y.toInt()} menit',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // === Heatmap Calendar (Custom Widget) ===
          const ProgressHeatmapCalendar(),

          const SizedBox(height: 24),

          // === Skill Focus Chart ===
          const _SkillFrequencyChart(),

          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SKILL FREQUENCY CHART (Moved from original)
// =============================================================================
class _SkillFrequencyChart extends StatelessWidget {
  const _SkillFrequencyChart();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final skillProv = context.watch<SkillProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Map<int, int> frequencyMap = {};
    for (var log in provider.logs) {
      if (log.skillId != null) {
        frequencyMap[log.skillId!] = (frequencyMap[log.skillId!] ?? 0) + 1;
      }
    }
    for (var challenge in provider.challenges) {
      if (challenge.skillId != null) {
        frequencyMap[challenge.skillId!] = (frequencyMap[challenge.skillId!] ?? 0) + 1;
      }
    }

    if (frequencyMap.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = frequencyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(5).toList();
    final maxFreq = topEntries.first.value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: isDark ? 0.2 : 0.6),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.insights_rounded, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                skillProv.defaultLang == 'id' ? 'Fokus Keahlian' : 'Skill Focus',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topEntries.map((entry) {
            final skill = skillProv.skills.firstWhere(
              (s) => s.id == entry.key,
              orElse: () => Skill(categoryId: 0, name: skillProv.defaultLang == 'id' ? 'Keahlian Dihapus' : 'Deleted Skill', createdAt: DateTime.now()),
            );
            final ratio = maxFreq > 0 ? entry.value / maxFreq : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      skill.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: ratio),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOutQuart,
                              builder: (context, value, child) {
                                return Container(
                                  height: 10,
                                  width: constraints.maxWidth * value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [theme.colorScheme.primary.withValues(alpha: 0.6), theme.colorScheme.primary],
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${entry.value}',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1: PROGRESS LOGS (Dengan Slidable)
// =============================================================================
class _ProgressLogsView extends StatelessWidget {
  const _ProgressLogsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final skillProv = context.watch<SkillProvider>();
    final logs = provider.logs;
    final fontSize = provider.fontSize;

    if (logs.isEmpty) {
      return Center(child: Text(skillProv.translate('no_logs')));
    }

    if (provider.viewMode == 'Grid') {
      return GridView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          Color skillColor = Theme.of(context).colorScheme.primary;
          if (log.skillId != null) {
            try {
              final skill = skillProv.skills.firstWhere((s) => s.id == log.skillId);
              final cat = skillProv.categories.firstWhere((c) => c.id == skill.categoryId);
              skillColor = Color(cat.colorValue);
            } catch (_) {}
          }

          return Card(
            elevation: 0,
            color: skillColor.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: skillColor.withValues(alpha: 0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              splashColor: skillColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showLogDetailModal(context, log, skillColor, skillProv, provider),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.skillId != null
                          ? skillProv.skills.firstWhere((s) => s.id == log.skillId, orElse: () => Skill(categoryId: 0, name: 'Deleted', createdAt: DateTime.now())).name
                          : 'Global',
                      style: TextStyle(color: skillColor, fontSize: fontSize * 0.8, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(log.date),
                      style: TextStyle(color: Colors.grey, fontSize: fontSize * 0.8),
                    ),
                    const Spacer(),
                    Text(
                      skillProv.translate('duration_minutes', args: [log.durationMinutes.toString()]),
                      style: TextStyle(color: skillColor, fontWeight: FontWeight.bold, fontSize: fontSize * 0.9),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // List View dengan Slidable
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        Color skillColor = Theme.of(context).colorScheme.primary;
        if (log.skillId != null) {
          try {
            final skill = skillProv.skills.firstWhere((s) => s.id == log.skillId);
            final cat = skillProv.categories.firstWhere((c) => c.id == skill.categoryId);
            skillColor = Color(cat.colorValue);
          } catch (_) {}
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Slidable(
              key: ValueKey(log.id),
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (context) async {
                      final confirm = await _showDeleteConfirmationDialog(context, log.title);
                      if (confirm && log.id != null) {
                        provider.deleteProgressLog(log.id!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(skillProv.translate('log_deleted'))),
                          );
                        }
                      }
                    },
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_rounded,
                    label: skillProv.defaultLang == 'id' ? 'Hapus' : 'Delete',
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                  ),
                ],
              ),
              startActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      _showEditLogDialog(context, log);
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  ),
                ],
              ),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: skillColor.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: skillColor.withValues(alpha: 0.3)),
                ),
                child: InkWell(
                  splashColor: skillColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showLogDetailModal(context, log, skillColor, skillProv, provider),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(log.title,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            ),
                            if (log.photoPath != null && log.photoPath!.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.image_rounded, color: Colors.blueGrey, size: 20),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          log.skillId != null
                              ? skillProv.skills.firstWhere((s) => s.id == log.skillId, orElse: () => Skill(categoryId: 0, name: 'Deleted', createdAt: DateTime.now())).name
                              : 'Global',
                          style: TextStyle(color: skillColor, fontSize: fontSize * 0.85, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(log.note, style: TextStyle(fontSize: fontSize * 0.9), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm').format(log.date),
                              style: TextStyle(fontSize: fontSize * 0.8, color: Colors.grey),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: skillColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                skillProv.translate('duration_minutes_short', args: [log.durationMinutes.toString()]),
                                style: TextStyle(fontSize: fontSize * 0.8, color: skillColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// TAB 2: CHALLENGES (Dengan Slidable + Celebration)
// =============================================================================
class _ChallengesView extends StatelessWidget {
  const _ChallengesView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final skillProv = context.watch<SkillProvider>();
    final challenges = provider.challenges;
    final fontSize = provider.fontSize;

    if (challenges.isEmpty) {
      return Center(child: Text(skillProv.translate('no_challenges')));
    }

    if (provider.viewMode == 'Grid') {
      return GridView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          final isCompleted = challenge.isCompleted == 1;

          Color skillColor = Theme.of(context).colorScheme.primary;
          if (challenge.skillId != null) {
            try {
              final skill = skillProv.skills.firstWhere((s) => s.id == challenge.skillId);
              final cat = skillProv.categories.firstWhere((c) => c.id == skill.categoryId);
              skillColor = Color(cat.colorValue);
            } catch (_) {}
          }

          return Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: skillColor.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: skillColor.withValues(alpha: 0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              splashColor: skillColor.withValues(alpha: 0.2),
              onTap: () => _showChallengeDetailModal(context, challenge, skillColor, skillProv, provider),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isCompleted,
                            activeColor: Colors.green,
                            onChanged: (val) {
                              if (val != null) {
                                provider.updateChallenge(
                                  challenge.copyWith(isCompleted: val ? 1 : 0),
                                );
                                if (challenge.skillId != null) {
                                  final amount = val ? 0.2 : -0.2;
                                  skillProv.incrementSkillProgress(challenge.skillId!, amount);
                                }
                                if (val) {
                                  CelebrationDialog.show(context,
                                    title: '🎉 Tantangan Selesai!',
                                    message: '"${challenge.title}" berhasil diselesaikan!',
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      challenge.skillId != null
                          ? skillProv.skills.firstWhere((s) => s.id == challenge.skillId, orElse: () => Skill(categoryId: 0, name: 'Deleted', createdAt: DateTime.now())).name
                          : 'Global',
                      style: TextStyle(color: skillColor, fontSize: fontSize * 0.85, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skillProv.defaultLang == 'id'
                          ? 'Tenggat: ${DateFormat('dd MMM yyyy').format(challenge.targetDate)}'
                          : 'Due: ${DateFormat('dd MMM yyyy').format(challenge.targetDate)}',
                      style: TextStyle(
                          fontSize: fontSize * 0.8,
                          color: isCompleted ? Colors.green : Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // List View dengan Slidable
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final isCompleted = challenge.isCompleted == 1;
        Color skillColor = Theme.of(context).colorScheme.primary;
        if (challenge.skillId != null) {
          try {
            final skill = skillProv.skills.firstWhere((s) => s.id == challenge.skillId);
            final cat = skillProv.categories.firstWhere((c) => c.id == skill.categoryId);
            skillColor = Color(cat.colorValue);
          } catch (_) {}
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Slidable(
              key: ValueKey(challenge.id),
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (context) async {
                      final confirm = await _showDeleteConfirmationDialog(context, challenge.title);
                      if (confirm && challenge.id != null) {
                        provider.deleteChallenge(challenge.id!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(skillProv.translate('challenge_deleted'))),
                          );
                        }
                      }
                    },
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_rounded,
                    label: skillProv.defaultLang == 'id' ? 'Hapus' : 'Delete',
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                  ),
                ],
              ),
              startActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      if (!isCompleted) {
                        provider.updateChallenge(
                          challenge.copyWith(isCompleted: 1),
                        );
                        if (challenge.skillId != null) {
                          skillProv.incrementSkillProgress(challenge.skillId!, 0.2);
                        }
                        CelebrationDialog.show(context,
                          title: '🎉 Tantangan Selesai!',
                          message: '"${challenge.title}" berhasil diselesaikan!',
                        );
                      } else {
                        _showEditChallengeDialog(context, challenge);
                      }
                    },
                    backgroundColor: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Colors.green,
                    foregroundColor: Colors.white,
                    icon: isCompleted ? Icons.edit_rounded : Icons.check_rounded,
                    label: isCompleted ? 'Edit' : (skillProv.defaultLang == 'id' ? 'Selesai' : 'Done'),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  ),
                ],
              ),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: skillColor.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: skillColor.withValues(alpha: 0.3)),
                ),
                child: InkWell(
                  splashColor: skillColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showChallengeDetailModal(context, challenge, skillColor, skillProv, provider),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: isCompleted,
                          activeColor: Colors.green,
                          onChanged: (val) {
                            if (val != null) {
                              provider.updateChallenge(
                                challenge.copyWith(isCompleted: val ? 1 : 0),
                              );
                              if (challenge.skillId != null) {
                                final amount = val ? 0.2 : -0.2;
                                skillProv.incrementSkillProgress(challenge.skillId!, amount);
                              }
                              if (val) {
                                CelebrationDialog.show(context,
                                  title: '🎉 Tantangan Selesai!',
                                  message: '"${challenge.title}" berhasil diselesaikan!',
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                challenge.skillId != null
                                    ? skillProv.skills.firstWhere((s) => s.id == challenge.skillId, orElse: () => Skill(categoryId: 0, name: 'Deleted', createdAt: DateTime.now())).name
                                    : 'Global',
                                style: TextStyle(color: skillColor, fontSize: fontSize * 0.85, fontWeight: FontWeight.w600),
                              ),
                              if (challenge.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(challenge.description,
                                    style: TextStyle(fontSize: fontSize * 0.9), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.event_available_rounded, size: 14, color: isCompleted ? Colors.green : Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    skillProv.defaultLang == 'id'
                                        ? 'Tenggat: ${DateFormat('dd MMM yyyy').format(challenge.targetDate)}'
                                        : 'Due: ${DateFormat('dd MMM yyyy').format(challenge.targetDate)}',
                                    style: TextStyle(
                                        fontSize: fontSize * 0.8,
                                        fontWeight: FontWeight.w600,
                                        color: isCompleted ? Colors.green : Colors.orange),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// ADD LOG FORM (Dengan InteractiveDurationSlider)
// =============================================================================
class _AddLogForm extends StatefulWidget {
  const _AddLogForm();

  @override
  State<_AddLogForm> createState() => _AddLogFormState();
}

class _AddLogFormState extends State<_AddLogForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  int _durationMinutes = 30;
  int? _selectedSkillId;
  DateTime _selectedDate = DateTime.now();
  String? _selectedPhotoPath;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null) {
        final file = result.files.single;
        Uint8List? bytes;
        if (kIsWeb) {
          bytes = file.bytes;
        } else {
          bytes = file.bytes ?? (file.path != null ? io.File(file.path!).readAsBytesSync() : null);
        }
        if (bytes != null) {
          if (kIsWeb && bytes.length > 500 * 1024) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ukuran gambar terlalu besar! Maksimal 500 KB.')),
              );
            }
            return;
          }
          final base64String = base64Encode(bytes);
          setState(() {
            _selectedPhotoPath = base64String;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillProvider>().skills;
    final skillProv = context.watch<SkillProvider>();
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Judul Aktivitas' : 'Activity Title',
                hintText: skillProv.defaultLang == 'id' ? 'Contoh: Belajar Asynchronous Programming' : 'Example: Learn Asynchronous Programming',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return skillProv.defaultLang == 'id' ? 'Judul tidak boleh kosong' : 'Title cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Catatan' : 'Notes',
                hintText: skillProv.defaultLang == 'id' ? 'Tulis deskripsi progres belajar Anda' : 'Write a description of your learning progress',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // === Interactive Duration Slider (Custom Widget + Art + Gesture) ===
            Text(
              skillProv.defaultLang == 'id' ? 'Durasi Belajar' : 'Study Duration',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            InteractiveDurationSlider(
              initialMinutes: _durationMinutes,
              maxMinutes: 180,
              accentColor: theme.colorScheme.primary,
              onChanged: (minutes) {
                setState(() {
                  _durationMinutes = minutes;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Tanggal: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'
                        : 'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(skillProv.defaultLang == 'id' ? 'Pilih Tanggal' : 'Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedPhotoPath != null
                        ? (skillProv.defaultLang == 'id' ? 'Foto terpilih' : 'Photo selected')
                        : (skillProv.defaultLang == 'id' ? 'Tidak ada foto' : 'No photo selected'),
                    style: TextStyle(
                      color: _selectedPhotoPath != null ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(context),
                  icon: const Icon(Icons.image_rounded),
                  label: Text(skillProv.defaultLang == 'id' ? 'Pilih Foto' : 'Pick Photo'),
                ),
                if (_selectedPhotoPath != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _selectedPhotoPath = null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(initialValue: _selectedSkillId,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Keahlian Terkait' : 'Related Skill',
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(skillProv.defaultLang == 'id' ? 'Global (Tanpa Keahlian)' : 'Global (No Skill)'),
                ),
                ...skills.map((skill) {
                  return DropdownMenuItem<int?>(
                    value: skill.id,
                    child: Text(skill.name),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSkillId = val;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<ProgressProvider>().addProgressLog(
                        title: _titleController.text.trim(),
                        note: _noteController.text.trim(),
                        durationMinutes: _durationMinutes,
                        date: _selectedDate,
                        photoPath: _selectedPhotoPath,
                        skillId: _selectedSkillId,
                      );
                  if (_selectedSkillId != null) {
                    final progressGained = _durationMinutes / 600.0;
                    context.read<SkillProvider>().incrementSkillProgress(_selectedSkillId!, progressGained);
                  }
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(skillProv.translate('add_log_success'))),
                    );
                  }
                }
              },
              child: Text(skillProv.defaultLang == 'id' ? 'Simpan Log' : 'Save Log'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ADD CHALLENGE FORM
// =============================================================================
class _AddChallengeForm extends StatefulWidget {
  const _AddChallengeForm();

  @override
  State<_AddChallengeForm> createState() => _AddChallengeFormState();
}

class _AddChallengeFormState extends State<_AddChallengeForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  int? _selectedSkillId;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillProvider>().skills;
    final skillProv = context.watch<SkillProvider>();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Nama Tantangan' : 'Challenge Name',
                hintText: skillProv.defaultLang == 'id' ? 'Contoh: Selesaikan 3 Coding Challenge' : 'Example: Solve 3 Coding Challenges',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return skillProv.defaultLang == 'id' ? 'Nama tantangan tidak boleh kosong' : 'Challenge name cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Deskripsi' : 'Description',
                hintText: skillProv.defaultLang == 'id' ? 'Tulis rincian tantangan Anda' : 'Write the details of your challenge',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Tenggat: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'
                        : 'Due: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(skillProv.defaultLang == 'id' ? 'Pilih Tanggal' : 'Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(initialValue: _selectedSkillId,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Keahlian Terkait' : 'Related Skill',
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(skillProv.defaultLang == 'id' ? 'Global (Tanpa Keahlian)' : 'Global (No Skill)'),
                ),
                ...skills.map((skill) {
                  return DropdownMenuItem<int?>(
                    value: skill.id,
                    child: Text(skill.name),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSkillId = val;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<ProgressProvider>().addChallenge(
                        title: _titleController.text.trim(),
                        description: _descController.text.trim(),
                        targetDate: _selectedDate,
                        skillId: _selectedSkillId,
                      );
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(skillProv.translate('add_challenge_success'))),
                    );
                  }
                }
              },
              child: Text(skillProv.defaultLang == 'id' ? 'Simpan Tantangan' : 'Save Challenge'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EDIT LOG FORM
// =============================================================================
class _EditLogForm extends StatefulWidget {
  final ProgressLog log;
  const _EditLogForm({required this.log});

  @override
  State<_EditLogForm> createState() => _EditLogFormState();
}

class _EditLogFormState extends State<_EditLogForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late int _durationMinutes;
  int? _selectedSkillId;
  late DateTime _selectedDate;
  String? _selectedPhotoPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log.title);
    _noteController = TextEditingController(text: widget.log.note);
    _durationMinutes = widget.log.durationMinutes;
    _selectedSkillId = widget.log.skillId;
    _selectedDate = widget.log.date;
    _selectedPhotoPath = widget.log.photoPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null) {
        final file = result.files.single;
        Uint8List? bytes;
        if (kIsWeb) {
          bytes = file.bytes;
        } else {
          bytes = file.bytes ?? (file.path != null ? io.File(file.path!).readAsBytesSync() : null);
        }
        if (bytes != null) {
          if (kIsWeb && bytes.length > 500 * 1024) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ukuran gambar terlalu besar! Maksimal 500 KB.')),
              );
            }
            return;
          }
          final base64String = base64Encode(bytes);
          setState(() {
            _selectedPhotoPath = base64String;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillProvider>().skills;
    final skillProv = context.watch<SkillProvider>();
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Judul Aktivitas' : 'Activity Title',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return skillProv.defaultLang == 'id' ? 'Judul tidak boleh kosong' : 'Title cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Catatan' : 'Notes',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Interactive Duration Slider for editing too
            Text(
              skillProv.defaultLang == 'id' ? 'Durasi Belajar' : 'Study Duration',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            InteractiveDurationSlider(
              initialMinutes: _durationMinutes.clamp(5, 180),
              maxMinutes: 180,
              accentColor: theme.colorScheme.primary,
              onChanged: (minutes) {
                setState(() {
                  _durationMinutes = minutes;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Tanggal: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'
                        : 'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(skillProv.defaultLang == 'id' ? 'Pilih Tanggal' : 'Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedPhotoPath != null
                        ? (skillProv.defaultLang == 'id' ? 'Foto terpilih' : 'Photo selected')
                        : (skillProv.defaultLang == 'id' ? 'Tidak ada foto' : 'No photo selected'),
                    style: TextStyle(
                      color: _selectedPhotoPath != null ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(context),
                  icon: const Icon(Icons.image_rounded),
                  label: Text(skillProv.defaultLang == 'id' ? 'Pilih Foto' : 'Pick Photo'),
                ),
                if (_selectedPhotoPath != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _selectedPhotoPath = null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(initialValue: _selectedSkillId,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Keahlian Terkait' : 'Related Skill',
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(skillProv.defaultLang == 'id' ? 'Global (Tanpa Keahlian)' : 'Global (No Skill)'),
                ),
                ...skills.map((skill) {
                  return DropdownMenuItem<int?>(
                    value: skill.id,
                    child: Text(skill.name),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSkillId = val;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final updatedLog = widget.log.copyWith(
                    title: _titleController.text.trim(),
                    note: _noteController.text.trim(),
                    durationMinutes: _durationMinutes,
                    skillId: _selectedSkillId,
                    date: _selectedDate,
                    photoPath: _selectedPhotoPath,
                  );
                  context.read<ProgressProvider>().updateProgressLog(updatedLog);
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(skillProv.translate('edit_log_success'))),
                    );
                  }
                }
              },
              child: Text(skillProv.translate('save')),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EDIT CHALLENGE FORM
// =============================================================================
class _EditChallengeForm extends StatefulWidget {
  final Challenge challenge;
  const _EditChallengeForm({required this.challenge});

  @override
  State<_EditChallengeForm> createState() => _EditChallengeFormState();
}

class _EditChallengeFormState extends State<_EditChallengeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late DateTime _selectedDate;
  int? _selectedSkillId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.challenge.title);
    _descController = TextEditingController(text: widget.challenge.description);
    _selectedDate = widget.challenge.targetDate;
    _selectedSkillId = widget.challenge.skillId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillProvider>().skills;
    final skillProv = context.watch<SkillProvider>();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Nama Tantangan' : 'Challenge Name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return skillProv.defaultLang == 'id' ? 'Nama tantangan tidak boleh kosong' : 'Challenge name cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Deskripsi' : 'Description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Tenggat: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'
                        : 'Due: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(skillProv.defaultLang == 'id' ? 'Pilih Tanggal' : 'Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(initialValue: _selectedSkillId,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Keahlian Terkait' : 'Related Skill',
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(skillProv.defaultLang == 'id' ? 'Global (Tanpa Keahlian)' : 'Global (No Skill)'),
                ),
                ...skills.map((skill) {
                  return DropdownMenuItem<int?>(
                    value: skill.id,
                    child: Text(skill.name),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSkillId = val;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final updatedChallenge = widget.challenge.copyWith(
                    title: _titleController.text.trim(),
                    description: _descController.text.trim(),
                    targetDate: _selectedDate,
                    skillId: _selectedSkillId,
                  );
                  context.read<ProgressProvider>().updateChallenge(updatedChallenge);
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(skillProv.translate('edit_challenge_success'))),
                    );
                  }
                }
              },
              child: Text(skillProv.translate('save')),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DIALOG HELPERS
// =============================================================================

void _showEditLogDialog(BuildContext context, ProgressLog log) {
  final skillProv = Provider.of<SkillProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(skillProv.defaultLang == 'id' ? 'Edit Log Aktivitas' : 'Edit Activity Log'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: _EditLogForm(log: log),
        ),
      );
    },
  );
}

void _showEditChallengeDialog(BuildContext context, Challenge challenge) {
  final skillProv = Provider.of<SkillProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(skillProv.defaultLang == 'id' ? 'Edit Tantangan' : 'Edit Challenge'),
        content: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: _EditChallengeForm(challenge: challenge),
        ),
      );
    },
  );
}

Future<bool> _showDeleteConfirmationDialog(BuildContext context, String title) async {
  final skillProv = Provider.of<SkillProvider>(context, listen: false);
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(skillProv.translate('delete_confirm_title')),
            content: Text(skillProv.translate('delete_confirm_desc', args: [title])),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(skillProv.translate('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(skillProv.translate('delete')),
              ),
            ],
          );
        },
      ) ??
      false;
}

void _showLogDetailModal(
  BuildContext context,
  ProgressLog log,
  Color skillColor,
  SkillProvider skillProv,
  ProgressProvider provider,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final skillName = log.skillId != null
      ? skillProv.skills.firstWhere((s) => s.id == log.skillId, orElse: () => Skill(categoryId: 0, name: 'Deleted', createdAt: DateTime.now())).name
      : 'Global';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: skillColor.withValues(alpha: 0.15),
                  child: Icon(Icons.history_edu, color: skillColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        '${skillProv.translate('nav_skills')}: $skillName',
                        style: TextStyle(color: skillColor, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditLogDialog(context, log);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (log.photoPath != null && log.photoPath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: log.photoPath!.startsWith('http')
                    ? Image.network(log.photoPath!, height: 200, width: double.infinity, fit: BoxFit.cover)
                    : Image.memory(base64Decode(log.photoPath!), height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: skillColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(DateFormat('EEEE, dd MMM yyyy').format(log.date), style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        skillProv.translate('duration_minutes', args: [log.durationMinutes.toString()]),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              skillProv.defaultLang == 'id' ? 'Catatan Aktivitas' : 'Activity Notes',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              log.note.isEmpty ? (skillProv.defaultLang == 'id' ? 'Tidak ada catatan.' : 'No notes.') : log.note,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: skillColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_rounded),
              label: Text(skillProv.defaultLang == 'id' ? 'Tutup' : 'Close'),
            ),
          ],
        ),
      );
    },
  );
}

void _showChallengeDetailModal(
  BuildContext context,
  Challenge challenge,
  Color skillColor,
  SkillProvider skillProv,
  ProgressProvider provider,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final skillName = challenge.skillId != null
      ? skillProv.skills.firstWhere((s) => s.id == challenge.skillId, orElse: () => Skill(categoryId: 0, name: 'Deleted', createdAt: DateTime.now())).name
      : 'Global';
  final isCompleted = challenge.isCompleted == 1;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isCompleted ? Colors.green.withValues(alpha: 0.15) : skillColor.withValues(alpha: 0.15),
                  child: Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.emoji_events_rounded,
                    color: isCompleted ? Colors.green : skillColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        '${skillProv.translate('nav_skills')}: $skillName',
                        style: TextStyle(color: skillColor, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditChallengeDialog(context, challenge);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: skillColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_available_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        skillProv.defaultLang == 'id'
                            ? 'Tenggat: ${DateFormat('dd MMM yyyy').format(challenge.targetDate)}'
                            : 'Due: ${DateFormat('dd MMM yyyy').format(challenge.targetDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(isCompleted ? Icons.task_alt_rounded : Icons.hourglass_top_rounded, size: 16, color: isCompleted ? Colors.green : Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        isCompleted
                            ? (skillProv.defaultLang == 'id' ? 'Tantangan Selesai' : 'Challenge Completed')
                            : (skillProv.defaultLang == 'id' ? 'Belum Selesai' : 'Not Completed'),
                        style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              skillProv.defaultLang == 'id' ? 'Deskripsi Tantangan' : 'Challenge Description',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description.isEmpty ? (skillProv.defaultLang == 'id' ? 'Tidak ada deskripsi.' : 'No description.') : challenge.description,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: skillColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_rounded),
              label: Text(skillProv.defaultLang == 'id' ? 'Tutup' : 'Close'),
            ),
          ],
        ),
      );
    },
  );
}
