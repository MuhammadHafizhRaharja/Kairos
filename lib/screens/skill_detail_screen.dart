import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../models/skill.dart';
import '../models/skill_category.dart';
import '../widgets/interactive_progress_card.dart';

/// Halaman Detail Kategori yang berisi daftar keahlian (Skills) di dalamnya.
/// Menggunakan gesture Dismissible (Swipe-to-Delete) dan kustom widget InteractiveProgressCard.
/// Mendukung pencarian, filter level, dan pengurutan dinamis.
class SkillDetailScreen extends StatefulWidget {
  final SkillCategory category;

  const SkillDetailScreen({super.key, required this.category});

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter =
      'Semua'; // 'Semua', 'Pemula (Lvl 1-2)', 'Menengah (Lvl 3-4)', 'Ahli (Lvl 5)'
  String _sortBy = 'Nama'; // 'Nama', 'Level', 'Terbaru'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillProvider>();
    final rawSkills = provider.getSkillsForCategory(widget.category.id ?? -1);
    final theme = Theme.of(context);
    final categoryColor = Color(widget.category.colorValue);

    // 1. Jalankan penyaringan (Filtering)
    List<Skill> filteredSkills = rawSkills.where((skill) {
      final matchesSearch =
          skill.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          skill.description.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesLevel = true;
      if (_selectedFilter == 'Pemula') {
        matchesLevel = skill.level <= 2;
      } else if (_selectedFilter == 'Menengah') {
        matchesLevel = skill.level >= 3 && skill.level <= 4;
      } else if (_selectedFilter == 'Ahli') {
        matchesLevel = skill.level >= 5;
      }

      return matchesSearch && matchesLevel;
    }).toList();

    // 2. Jalankan pengurutan (Sorting)
    if (_sortBy == 'Nama') {
      filteredSkills.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else if (_sortBy == 'Level') {
      filteredSkills.sort((a, b) {
        int comp = b.level.compareTo(a.level);
        if (comp == 0) {
          return b.progress.compareTo(a.progress);
        }
        return comp;
      });
    } else if (_sortBy == 'Terbaru') {
      filteredSkills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: categoryColor.withValues(alpha: 0.1),
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 88,
              ),
              itemCount:
                  2 + (filteredSkills.isEmpty ? 1 : filteredSkills.length),
              itemBuilder: (context, index) {
                // Widget 1: Header summary card
                if (index == 0) {
                  return _buildCategorySummaryHeaderCard(
                    context,
                    rawSkills,
                    categoryColor,
                  );
                }

                // Widget 2: Panel Pencarian, Filter & Sortir
                if (index == 1) {
                  return _buildFilterPanel(context, categoryColor);
                }

                // Tampilkan Empty State jika tidak ada skill
                if (filteredSkills.isEmpty) {
                  return _buildEmptyState(
                    context,
                    theme,
                    categoryColor,
                    rawSkills.isEmpty,
                  );
                }

                final skill = filteredSkills[index - 2];

                // Menggunakan Gesture Swipe-to-Delete dengan Dismissible
                return Dismissible(
                  key: Key('skill_${skill.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.delete, color: Colors.white),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await _showDeleteConfirmDialog(
                      context,
                      skill.name,
                      categoryColor,
                    );
                  },
                  onDismissed: (direction) {
                    provider.deleteSkill(skill.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Skill "${skill.name}" berhasil dihapus'),
                        action: SnackBarAction(
                          label: 'Batal',
                          textColor: Colors.amber,
                          onPressed: () {
                            provider.addSkill(
                              categoryId: skill.categoryId,
                              name: skill.name,
                              description: skill.description,
                              level: skill.level,
                              progress: skill.progress,
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: InteractiveProgressCard(
                    skill: skill,
                    themeColor: categoryColor,
                    onProgressChanged: (newLevel, newProgress) {
                      final updatedSkill = Skill(
                        id: skill.id,
                        categoryId: skill.categoryId,
                        name: skill.name,
                        description: skill.description,
                        level: newLevel,
                        progress: newProgress,
                        createdAt: skill.createdAt,
                      );
                      provider.updateSkill(updatedSkill);
                    },
                    onLongPress: () {
                      _showEditSkillDialog(
                        context,
                        provider,
                        skill,
                        categoryColor,
                      );
                    },
                    onEdit: () {
                      _showEditSkillDialog(
                        context,
                        provider,
                        skill,
                        categoryColor,
                      );
                    },
                    onDelete: () async {
                      final confirmed = await _showDeleteConfirmDialog(
                        context,
                        skill.name,
                        categoryColor,
                      );
                      if (confirmed == true && context.mounted) {
                        provider.deleteSkill(skill.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Skill "${skill.name}" berhasil dihapus!',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showAddSkillDialog(context, provider, categoryColor),
        backgroundColor: categoryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    Color color,
    bool isCategoryEmpty,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(
                isCategoryEmpty
                    ? Icons.school_outlined
                    : Icons.search_off_rounded,
                size: 36,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCategoryEmpty
                  ? 'Belum Ada Keahlian'
                  : 'Keahlian Tidak Ditemukan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isCategoryEmpty
                  ? 'Tekan tombol tambah (+) di kanan bawah untuk mulai melacak keterampilan baru di kategori ini.'
                  : 'Cobalah kata kunci lain atau bersihkan penyaring untuk menemukan keahlian.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  /// Panel Pencarian, Filter Chip & Pengurutan
  Widget _buildFilterPanel(BuildContext context, Color themeColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = ['Semua', 'Pemula', 'Menengah', 'Ahli'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Kolom Pencarian
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeColor.withValues(alpha: 0.15)),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari keahlian atau catatan...',
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: themeColor,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),

        // 2. Baris Filter & Sortir
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: themeColor,
                        backgroundColor: isDark
                            ? Colors.grey[950]
                            : Colors.grey[200],
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Dropdown Menu Pengurutan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  icon: Icon(Icons.sort_rounded, size: 16, color: themeColor),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortBy = newValue;
                      });
                    }
                  },
                  items: <String>['Nama', 'Level', 'Terbaru']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Kartu Ringkasan Kategori
  Widget _buildCategorySummaryHeaderCard(
    BuildContext context,
    List<Skill> skills,
    Color categoryColor,
  ) {
    final theme = Theme.of(context);
    final totalSkills = skills.length;

    double avgLevel = 0.0;
    double overallProgress = 0.0;

    if (skills.isNotEmpty) {
      avgLevel =
          skills.map((s) => s.level.toDouble()).reduce((a, b) => a + b) /
          skills.length;
      final totalScore = skills
          .map((s) => ((s.level - 1) + s.progress) / 5.0)
          .reduce((a, b) => a + b);
      overallProgress = (totalScore / skills.length).clamp(0.0, 1.0);
    }

    return Card(
      elevation: 0,
      color: categoryColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: categoryColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: categoryColor.withValues(alpha: 0.2),
                  child: Icon(
                    _getIconData(widget.category.icon),
                    color: categoryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target Penguasaan Kategori',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Total Skill', totalSkills.toString(), theme),
                Container(
                  width: 1.5,
                  height: 36,
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
                _buildSummaryStat(
                  'Rerata Level',
                  avgLevel > 0 ? avgLevel.toStringAsFixed(1) : '-',
                  theme,
                ),
                Container(
                  width: 1.5,
                  height: 36,
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
                _buildSummaryStat(
                  'Penguasaan',
                  '${(overallProgress * 100).toInt()}%',
                  theme,
                  color: categoryColor,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: overallProgress,
                backgroundColor: categoryColor.withValues(alpha: 0.1),
                color: categoryColor,
                minHeight: 8,
              ),
            ),

            // Grafik Distribusi Level Baru
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _buildLevelDistributionChart(skills, categoryColor),
            ],
          ],
        ),
      ),
    );
  }

  /// Grafik Distribusi Level horizontal
  Widget _buildLevelDistributionChart(List<Skill> skills, Color color) {
    // Hitung kemunculan level 1-5
    final Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var s in skills) {
      final clampedLvl = s.level.clamp(1, 5);
      distribution[clampedLvl] = (distribution[clampedLvl] ?? 0) + 1;
    }

    final maxCount = distribution.values.reduce((a, b) => a > b ? a : b);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Grafik Tingkat Keahlian',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              'Level 1 - 5',
              style: TextStyle(fontSize: 11, color: theme.hintColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: List.generate(5, (index) {
            final lvl = index + 1;
            final count = distribution[lvl] ?? 0;
            final ratio = maxCount > 0 ? count / maxCount : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Text(
                      'Lvl $lvl',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;
                        final targetWidth = count > 0 ? maxWidth * ratio : 0.0;
                        return Stack(
                          children: [
                            // Background Bar
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            // Fill Bar
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.fastOutSlowIn,
                              height: 10,
                              width: targetWidth,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 60,
                    alignment: Alignment.centerRight,
                    child: Text(
                      count > 0 ? '$count Skill' : '-',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: count > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: count > 0 ? color : theme.hintColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSummaryStat(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: theme.hintColor)),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'code':
        return Icons.code;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'translate':
        return Icons.translate;
      case 'music_note':
        return Icons.music_note;
      case 'book':
        return Icons.book;
      case 'brush':
        return Icons.brush;
      case 'sports_basketball':
        return Icons.sports_basketball;
      default:
        return Icons.star;
    }
  }

  /// Dialog konfirmasi penghapusan skill (UI dipercantik dengan Bottom Sheet)
  Future<bool?> _showDeleteConfirmDialog(
    BuildContext parentContext,
    String skillName,
    Color accentColor,
  ) {
    final theme = Theme.of(parentContext);
    return showModalBottomSheet<bool>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle Pill
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hapus Keahlian?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(modalContext, false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Apakah Anda yakin ingin menghapus keterampilan "$skillName" dari pelacakan?',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(modalContext, true),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Hapus Keahlian'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog input untuk menambahkan keahlian baru (UI dipercantik dengan Bottom Sheet)
  void _showAddSkillDialog(
    BuildContext parentContext,
    SkillProvider provider,
    Color accentColor,
  ) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final theme = Theme.of(parentContext);

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle Pill
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tambah Keahlian',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tambahkan keterampilan baru yang ingin Anda lacak perkembangannya.',
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Keahlian',
                    hintText: 'misal: Refactoring, UI Design',
                    prefixIcon: Icon(Icons.book_rounded, color: accentColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'misal: Belajar pola Clean Architecture',
                    prefixIcon: Icon(
                      Icons.edit_note_rounded,
                      color: accentColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final desc = descController.text.trim();

                    if (name.isNotEmpty) {
                      provider.addSkill(
                        categoryId: widget.category.id!,
                        name: name,
                        description: desc,
                      );
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Keahlian "$name" berhasil ditambahkan!',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog input untuk mengedit keahlian (UI dipercantik dengan Bottom Sheet)
  void _showEditSkillDialog(
    BuildContext parentContext,
    SkillProvider provider,
    Skill skill,
    Color accentColor,
  ) {
    final nameController = TextEditingController(text: skill.name);
    final descController = TextEditingController(text: skill.description);
    final theme = Theme.of(parentContext);

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle Pill
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ubah Keahlian',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Ubah nama atau deskripsi dari keahlian ini.',
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Keahlian',
                    hintText: 'misal: Refactoring, UI Design',
                    prefixIcon: Icon(Icons.book_rounded, color: accentColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'misal: Belajar pola Clean Architecture',
                    prefixIcon: Icon(
                      Icons.edit_note_rounded,
                      color: accentColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final desc = descController.text.trim();

                    if (name.isNotEmpty) {
                      provider.updateSkill(
                        Skill(
                          id: skill.id,
                          categoryId: skill.categoryId,
                          name: name,
                          description: desc,
                          level: skill.level,
                          progress: skill.progress,
                          createdAt: skill.createdAt,
                        ),
                      );
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Keahlian "$name" berhasil diperbarui!',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
