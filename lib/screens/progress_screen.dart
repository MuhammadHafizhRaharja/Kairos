import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/progress_provider.dart';
import '../providers/skill_provider.dart';
import '../models/progress_log.dart';
import '../models/challenge.dart';
import '../models/skill.dart';

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
      length: 2,
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
          actions: [
            // Kontrol ukuran font dan view mode dipindahkan ke Halaman Profil
          ],
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                text: skillProv.translate('activity_log'),
                icon: const Icon(Icons.history_edu),
              ),
              Tab(
                text: skillProv.translate('challenges'),
                icon: const Icon(Icons.emoji_events),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            const _SkillFrequencyChart(),
            const Expanded(
              child: TabBarView(
                children: [_ProgressLogsView(), _ChallengesView()],
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(
            bottom: 96.0,
          ), // Hindari tertutup navbar melayang
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
              height: 400,
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
                      children: [_AddLogForm(), _AddChallengeForm()],
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

class _SkillFrequencyChart extends StatelessWidget {
  const _SkillFrequencyChart();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final skillProv = context.watch<SkillProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Hitung frekuensi keahlian
    final Map<int, int> frequencyMap = {};
    for (var log in provider.logs) {
      if (log.skillId != null) {
        frequencyMap[log.skillId!] = (frequencyMap[log.skillId!] ?? 0) + 1;
      }
    }
    for (var challenge in provider.challenges) {
      if (challenge.skillId != null) {
        frequencyMap[challenge.skillId!] =
            (frequencyMap[challenge.skillId!] ?? 0) + 1;
      }
    }

    if (frequencyMap.isEmpty) {
      return const SizedBox.shrink(); // Sembunyikan jika tidak ada data
    }

    // Urutkan berdasarkan frekuensi menurun
    final sortedEntries = frequencyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Ambil top 3
    final topEntries = sortedEntries.take(3).toList();
    final maxFreq = topEntries.first.value;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(
              alpha: isDark ? 0.2 : 0.6,
            ),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 10,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                skillProv.defaultLang == 'id'
                    ? 'Fokus Keahlian'
                    : 'Skill Focus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topEntries.map((entry) {
            final skill = skillProv.skills.firstWhere(
              (s) => s.id == entry.key,
              orElse: () => Skill(
                categoryId: 0,
                name: skillProv.defaultLang == 'id'
                    ? 'Keahlian Dihapus'
                    : 'Deleted Skill',
                createdAt: DateTime.now(),
              ),
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutQuart,
                              height: 10,
                              width: constraints.maxWidth * ratio,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withValues(
                                      alpha: 0.6,
                                    ),
                                    theme.colorScheme.primary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
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
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 120,
        ),
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
              final skill = skillProv.skills.firstWhere(
                (s) => s.id == log.skillId,
              );
              final cat = skillProv.categories.firstWhere(
                (c) => c.id == skill.categoryId,
              );
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
              onTap: () => _showLogDetailModal(
                context,
                log,
                skillColor,
                skillProv,
                provider,
              ),
              onLongPress: () async {
                final confirm = await _showDeleteConfirmationDialog(
                  context,
                  log.title,
                );
                if (confirm && log.id != null) {
                  provider.deleteProgressLog(log.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(skillProv.translate('log_deleted')),
                      ),
                    );
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.skillId != null
                          ? skillProv.skills
                                .firstWhere(
                                  (s) => s.id == log.skillId,
                                  orElse: () => Skill(
                                    categoryId: 0,
                                    name: skillProv.defaultLang == 'id'
                                        ? 'Keahlian Dihapus'
                                        : 'Deleted Skill',
                                    createdAt: DateTime.now(),
                                  ),
                                )
                                .name
                          : (skillProv.defaultLang == 'id'
                                ? 'Global'
                                : 'Global'),
                      style: TextStyle(
                        color: skillColor,
                        fontSize: fontSize * 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(log.date),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: fontSize * 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      skillProv.translate(
                        'duration_minutes',
                        args: [log.durationMinutes.toString()],
                      ),
                      style: TextStyle(
                        color: skillColor,
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize * 0.9,
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

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        Color skillColor = Theme.of(context).colorScheme.primary;
        if (log.skillId != null) {
          try {
            final skill = skillProv.skills.firstWhere(
              (s) => s.id == log.skillId,
            );
            final cat = skillProv.categories.firstWhere(
              (c) => c.id == skill.categoryId,
            );
            skillColor = Color(cat.colorValue);
          } catch (_) {}
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: skillColor.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: skillColor.withValues(alpha: 0.3)),
          ),
          child: InkWell(
            splashColor: skillColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showLogDetailModal(
              context,
              log,
              skillColor,
              skillProv,
              provider,
            ),
            onLongPress: () async {
              final confirm = await _showDeleteConfirmationDialog(
                context,
                log.title,
              );
              if (confirm && log.id != null) {
                provider.deleteProgressLog(log.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(skillProv.translate('log_deleted'))),
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          log.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      if (log.photoPath != null && log.photoPath!.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.image_rounded,
                            color: Colors.blueGrey,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.skillId != null
                        ? skillProv.skills
                              .firstWhere(
                                (s) => s.id == log.skillId,
                                orElse: () => Skill(
                                  categoryId: 0,
                                  name: skillProv.defaultLang == 'id'
                                      ? 'Keahlian Dihapus'
                                      : 'Deleted Skill',
                                  createdAt: DateTime.now(),
                                ),
                              )
                              .name
                        : (skillProv.defaultLang == 'id' ? 'Global' : 'Global'),
                    style: TextStyle(
                      color: skillColor,
                      fontSize: fontSize * 0.85,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    log.note,
                    style: TextStyle(fontSize: fontSize * 0.9),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(log.date),
                        style: TextStyle(
                          fontSize: fontSize * 0.8,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: skillColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          skillProv.translate(
                            'duration_minutes_short',
                            args: [log.durationMinutes.toString()],
                          ),
                          style: TextStyle(
                            fontSize: fontSize * 0.8,
                            color: skillColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 120,
        ),
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
              final skill = skillProv.skills.firstWhere(
                (s) => s.id == challenge.skillId,
              );
              final cat = skillProv.categories.firstWhere(
                (c) => c.id == skill.categoryId,
              );
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
              onTap: () => _showChallengeDetailModal(
                context,
                challenge,
                skillColor,
                skillProv,
                provider,
              ),
              onLongPress: () async {
                final confirm = await _showDeleteConfirmationDialog(
                  context,
                  challenge.title,
                );
                if (confirm && challenge.id != null) {
                  provider.deleteChallenge(challenge.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(skillProv.translate('challenge_deleted')),
                      ),
                    );
                  }
                }
              },
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
                                  skillProv.incrementSkillProgress(
                                    challenge.skillId!,
                                    amount,
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
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
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
                          ? skillProv.skills
                                .firstWhere(
                                  (s) => s.id == challenge.skillId,
                                  orElse: () => Skill(
                                    categoryId: 0,
                                    name: skillProv.defaultLang == 'id'
                                        ? 'Keahlian Dihapus'
                                        : 'Deleted Skill',
                                    createdAt: DateTime.now(),
                                  ),
                                )
                                .name
                          : (skillProv.defaultLang == 'id'
                                ? 'Global'
                                : 'Global'),
                      style: TextStyle(
                        color: skillColor,
                        fontSize: fontSize * 0.85,
                        fontWeight: FontWeight.w600,
                      ),
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
                        color: isCompleted ? Colors.green : Colors.orange,
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

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final isCompleted = challenge.isCompleted == 1;
        Color skillColor = Theme.of(context).colorScheme.primary;
        if (challenge.skillId != null) {
          try {
            final skill = skillProv.skills.firstWhere(
              (s) => s.id == challenge.skillId,
            );
            final cat = skillProv.categories.firstWhere(
              (c) => c.id == skill.categoryId,
            );
            skillColor = Color(cat.colorValue);
          } catch (_) {}
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: skillColor.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: skillColor.withValues(alpha: 0.3)),
          ),
          child: InkWell(
            splashColor: skillColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showChallengeDetailModal(
              context,
              challenge,
              skillColor,
              skillProv,
              provider,
            ),
            onLongPress: () async {
              final confirm = await _showDeleteConfirmationDialog(
                context,
                challenge.title,
              );
              if (confirm && challenge.id != null) {
                provider.deleteChallenge(challenge.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(skillProv.translate('challenge_deleted')),
                    ),
                  );
                }
              }
            },
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
                          skillProv.incrementSkillProgress(
                            challenge.skillId!,
                            amount,
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
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge.skillId != null
                              ? skillProv.skills
                                    .firstWhere(
                                      (s) => s.id == challenge.skillId,
                                      orElse: () => Skill(
                                        categoryId: 0,
                                        name: skillProv.defaultLang == 'id'
                                            ? 'Keahlian Dihapus'
                                            : 'Deleted Skill',
                                        createdAt: DateTime.now(),
                                      ),
                                    )
                                    .name
                              : (skillProv.defaultLang == 'id'
                                    ? 'Global'
                                    : 'Global'),
                          style: TextStyle(
                            color: skillColor,
                            fontSize: fontSize * 0.85,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (challenge.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            challenge.description,
                            style: TextStyle(fontSize: fontSize * 0.9),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 14,
                              color: isCompleted ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              skillProv.defaultLang == 'id'
                                  ? 'Tenggat: ${DateFormat('dd MMM yyyy').format(challenge.targetDate)}'
                                  : 'Due: ${DateFormat('dd MMM yyyy').format(challenge.targetDate)}',
                              style: TextStyle(
                                fontSize: fontSize * 0.8,
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? Colors.green
                                    : Colors.orange,
                              ),
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
        );
      },
    );
  }
}

class _AddLogForm extends StatefulWidget {
  const _AddLogForm();

  @override
  State<_AddLogForm> createState() => _AddLogFormState();
}

class _AddLogFormState extends State<_AddLogForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _durationController = TextEditingController();
  int? _selectedSkillId;
  DateTime _selectedDate = DateTime.now();
  String? _selectedPhotoPath;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _durationController.dispose();
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
          bytes =
              file.bytes ??
              (file.path != null
                  ? io.File(file.path!).readAsBytesSync()
                  : null);
        }
        if (bytes != null) {
          if (kIsWeb && bytes.length > 500 * 1024) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Ukuran gambar terlalu besar! Maksimal 500 KB.',
                  ),
                ),
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

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id'
                    ? 'Judul Aktivitas'
                    : 'Activity Title',
                hintText: skillProv.defaultLang == 'id'
                    ? 'Contoh: Belajar Asynchronous Programming'
                    : 'Example: Learn Asynchronous Programming',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return skillProv.defaultLang == 'id'
                      ? 'Judul tidak boleh kosong'
                      : 'Title cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id' ? 'Catatan' : 'Notes',
                hintText: skillProv.defaultLang == 'id'
                    ? 'Tulis deskripsi progres belajar Anda'
                    : 'Write a description of your learning progress',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id'
                    ? 'Durasi (Menit)'
                    : 'Duration (Minutes)',
                hintText: skillProv.defaultLang == 'id'
                    ? 'Contoh: 30'
                    : 'Example: 30',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return skillProv.defaultLang == 'id'
                      ? 'Durasi tidak boleh kosong'
                      : 'Duration cannot be empty';
                }
                final dur = int.tryParse(value);
                if (dur == null || dur <= 0) {
                  return skillProv.defaultLang == 'id'
                      ? 'Durasi harus berupa angka positif (> 0)'
                      : 'Duration must be a positive number (> 0)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
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
                  label: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Pilih Tanggal'
                        : 'Pick Date',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedPhotoPath != null
                        ? (skillProv.defaultLang == 'id'
                              ? 'Foto terpilih'
                              : 'Photo selected')
                        : (skillProv.defaultLang == 'id'
                              ? 'Tidak ada foto'
                              : 'No photo selected'),
                    style: TextStyle(
                      color: _selectedPhotoPath != null
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(context),
                  icon: const Icon(Icons.image_rounded),
                  label: Text(
                    skillProv.defaultLang == 'id' ? 'Pilih Foto' : 'Pick Photo',
                  ),
                ),
                if (_selectedPhotoPath != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _selectedPhotoPath = null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _selectedSkillId,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id'
                    ? 'Keahlian Terkait'
                    : 'Related Skill',
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Global (Tanpa Keahlian)'
                        : 'Global (No Skill)',
                  ),
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
                  final duration = int.parse(_durationController.text.trim());
                  context.read<ProgressProvider>().addProgressLog(
                    title: _titleController.text.trim(),
                    note: _noteController.text.trim(),
                    durationMinutes: duration,
                    date: _selectedDate,
                    photoPath: _selectedPhotoPath,
                    skillId: _selectedSkillId,
                  );
                  if (_selectedSkillId != null) {
                    // Penambahan progres logis: misal 60 menit = 10% (0.1) progress
                    final progressGained = duration / 600.0;
                    context.read<SkillProvider>().incrementSkillProgress(
                      _selectedSkillId!,
                      progressGained,
                    );
                  }
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(skillProv.translate('add_log_success')),
                      ),
                    );
                  }
                }
              },
              child: Text(
                skillProv.defaultLang == 'id' ? 'Simpan Log' : 'Save Log',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                labelText: skillProv.defaultLang == 'id'
                    ? 'Nama Tantangan'
                    : 'Challenge Name',
                hintText: skillProv.defaultLang == 'id'
                    ? 'Contoh: Selesaikan 3 Coding Challenge'
                    : 'Example: Solve 3 Coding Challenges',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return skillProv.defaultLang == 'id'
                      ? 'Nama tantangan tidak boleh kosong'
                      : 'Challenge name cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id'
                    ? 'Deskripsi'
                    : 'Description',
                hintText: skillProv.defaultLang == 'id'
                    ? 'Tulis rincian tantangan Anda'
                    : 'Write the details of your challenge',
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
                  label: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Pilih Tanggal'
                        : 'Pick Date',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _selectedSkillId,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id'
                    ? 'Keahlian Terkait'
                    : 'Related Skill',
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Global (Tanpa Keahlian)'
                        : 'Global (No Skill)',
                  ),
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
                      SnackBar(
                        content: Text(
                          skillProv.translate('add_challenge_success'),
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(
                skillProv.defaultLang == 'id'
                    ? 'Simpan Tantangan'
                    : 'Save Challenge',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  late final TextEditingController _durationController;
  int? _selectedSkillId;
  late DateTime _selectedDate;
  String? _selectedPhotoPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log.title);
    _noteController = TextEditingController(text: widget.log.note);
    _durationController = TextEditingController(
      text: widget.log.durationMinutes.toString(),
    );
    _selectedSkillId = widget.log.skillId;
    _selectedDate = widget.log.date;
    _selectedPhotoPath = widget.log.photoPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _durationController.dispose();
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
          bytes =
              file.bytes ??
              (file.path != null
                  ? io.File(file.path!).readAsBytesSync()
                  : null);
        }
        if (bytes != null) {
          if (kIsWeb && bytes.length > 500 * 1024) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Ukuran gambar terlalu besar! Maksimal 500 KB.',
                  ),
                ),
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

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id'
                    ? 'Judul Aktivitas'
                    : 'Activity Title',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return skillProv.defaultLang == 'id'
                      ? 'Judul tidak boleh kosong'
                      : 'Title cannot be empty';
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id'
                    ? 'Durasi (Menit)'
                    : 'Duration (Minutes)',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return skillProv.defaultLang == 'id'
                      ? 'Durasi tidak boleh kosong'
                      : 'Duration cannot be empty';
                }
                final dur = int.tryParse(value);
                if (dur == null || dur <= 0) {
                  return skillProv.defaultLang == 'id'
                      ? 'Durasi harus berupa angka positif (> 0)'
                      : 'Duration must be a positive number (> 0)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
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
                  label: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Pilih Tanggal'
                        : 'Pick Date',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedPhotoPath != null
                        ? (skillProv.defaultLang == 'id'
                              ? 'Foto terpilih'
                              : 'Photo selected')
                        : (skillProv.defaultLang == 'id'
                              ? 'Tidak ada foto'
                              : 'No photo selected'),
                    style: TextStyle(
                      color: _selectedPhotoPath != null
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(context),
                  icon: const Icon(Icons.image_rounded),
                  label: Text(
                    skillProv.defaultLang == 'id' ? 'Pilih Foto' : 'Pick Photo',
                  ),
                ),
                if (_selectedPhotoPath != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _selectedPhotoPath = null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _selectedSkillId,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id'
                    ? 'Keahlian Terkait'
                    : 'Related Skill',
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Global (Tanpa Keahlian)'
                        : 'Global (No Skill)',
                  ),
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
                    durationMinutes: int.parse(_durationController.text.trim()),
                    skillId: _selectedSkillId,
                    date: _selectedDate,
                    photoPath: _selectedPhotoPath,
                  );
                  context.read<ProgressProvider>().updateProgressLog(
                    updatedLog,
                  );
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(skillProv.translate('edit_log_success')),
                      ),
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
                labelText: skillProv.defaultLang == 'id'
                    ? 'Nama Tantangan'
                    : 'Challenge Name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return skillProv.defaultLang == 'id'
                      ? 'Nama tantangan tidak boleh kosong'
                      : 'Challenge name cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id'
                    ? 'Deskripsi'
                    : 'Description',
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
                  label: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Pilih Tanggal'
                        : 'Pick Date',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _selectedSkillId,
              decoration: InputDecoration(
                labelText: skillProv.defaultLang == 'id'
                    ? 'Keahlian Terkait'
                    : 'Related Skill',
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    skillProv.defaultLang == 'id'
                        ? 'Global (Tanpa Keahlian)'
                        : 'Global (No Skill)',
                  ),
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
                  context.read<ProgressProvider>().updateChallenge(
                    updatedChallenge,
                  );
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          skillProv.translate('edit_challenge_success'),
                        ),
                      ),
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
// PEMBANTU DIALOG (EDIT & KONFIRMASI HAPUS)
// =============================================================================

void _showEditLogDialog(BuildContext context, ProgressLog log) {
  final skillProv = Provider.of<SkillProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          skillProv.defaultLang == 'id'
              ? 'Edit Log Aktivitas'
              : 'Edit Activity Log',
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
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
        title: Text(
          skillProv.defaultLang == 'id' ? 'Edit Tantangan' : 'Edit Challenge',
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: _EditChallengeForm(challenge: challenge),
        ),
      );
    },
  );
}

Future<bool> _showDeleteConfirmationDialog(
  BuildContext context,
  String title,
) async {
  final skillProv = Provider.of<SkillProvider>(context, listen: false);
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(skillProv.translate('delete_confirm_title')),
            content: Text(
              skillProv.translate('delete_confirm_desc', args: [title]),
            ),
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
      ? skillProv.skills
            .firstWhere(
              (s) => s.id == log.skillId,
              orElse: () => Skill(
                categoryId: 0,
                name: skillProv.defaultLang == 'id'
                    ? 'Keahlian Dihapus'
                    : 'Deleted Skill',
                createdAt: DateTime.now(),
              ),
            )
            .name
      : (skillProv.defaultLang == 'id' ? 'Global' : 'Global');

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
                      Text(
                        log.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${skillProv.translate('nav_skills')}: $skillName',
                        style: TextStyle(
                          color: skillColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
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
                    ? Image.network(
                        log.photoPath!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.memory(
                        base64Decode(log.photoPath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 24),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: skillColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(log.date),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        skillProv.translate(
                          'duration_minutes',
                          args: [log.durationMinutes.toString()],
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              skillProv.defaultLang == 'id'
                  ? 'Catatan Aktivitas'
                  : 'Activity Notes',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              log.note.isEmpty
                  ? (skillProv.defaultLang == 'id'
                        ? 'Tidak ada catatan.'
                        : 'No notes.')
                  : log.note,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: skillColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
      ? skillProv.skills
            .firstWhere(
              (s) => s.id == challenge.skillId,
              orElse: () => Skill(
                categoryId: 0,
                name: skillProv.defaultLang == 'id'
                    ? 'Keahlian Dihapus'
                    : 'Deleted Skill',
                createdAt: DateTime.now(),
              ),
            )
            .name
      : (skillProv.defaultLang == 'id' ? 'Global' : 'Global');
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
                  backgroundColor: isCompleted
                      ? Colors.green.withValues(alpha: 0.15)
                      : skillColor.withValues(alpha: 0.15),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.emoji_events_rounded,
                    color: isCompleted ? Colors.green : skillColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${skillProv.translate('nav_skills')}: $skillName',
                        style: TextStyle(
                          color: skillColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
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
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: skillColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.event_available_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
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
                      Icon(
                        isCompleted
                            ? Icons.task_alt_rounded
                            : Icons.hourglass_top_rounded,
                        size: 16,
                        color: isCompleted ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCompleted
                            ? (skillProv.defaultLang == 'id'
                                  ? 'Tantangan Selesai'
                                  : 'Challenge Completed')
                            : (skillProv.defaultLang == 'id'
                                  ? 'Belum Selesai'
                                  : 'Not Completed'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              skillProv.defaultLang == 'id'
                  ? 'Deskripsi Tantangan'
                  : 'Challenge Description',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description.isEmpty
                  ? (skillProv.defaultLang == 'id'
                        ? 'Tidak ada deskripsi.'
                        : 'No description.')
                  : challenge.description,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: skillColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
