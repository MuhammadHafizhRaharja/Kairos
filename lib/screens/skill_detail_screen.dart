import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../models/skill.dart';
import '../models/skill_category.dart';
import '../widgets/interactive_progress_card.dart';

/// Halaman Detail Kategori yang berisi daftar keahlian (Skills) di dalamnya.
/// Menggunakan gesture Dismissible (Swipe-to-Delete) dan kustom widget InteractiveProgressCard.
class SkillDetailScreen extends StatelessWidget {
  final SkillCategory category;

  const SkillDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillProvider>();
    final skills = provider.getSkillsForCategory(category.id ?? -1);
    final theme = Theme.of(context);
    final categoryColor = Color(category.colorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        centerTitle: true,
        backgroundColor: categoryColor.withValues(alpha: 0.1),
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
              itemCount: skills.isEmpty ? 2 : skills.length + 1,
              itemBuilder: (context, index) {
                // Tampilkan summary card pada indeks pertama
                if (index == 0) {
                  return _buildCategorySummaryHeaderCard(context, skills, categoryColor);
                }

                // Tampilkan empty state jika tidak ada skill
                if (skills.isEmpty) {
                  return _buildEmptyState(context, theme, categoryColor);
                }

                final skill = skills[index - 1];

                // Menggunakan Gesture Swipe-to-Delete dengan Dismissible
                return Dismissible(
                  key: Key('skill_${skill.id}'),
                  direction: DismissDirection.endToStart,
                  // Visual background merah saat diswipe ke kiri
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
                  // Dialog konfirmasi sebelum benar-benar menghapus
                  confirmDismiss: (direction) async {
                    return await _showDeleteConfirmDialog(context, skill.name);
                  },
                  // Aksi yang dilakukan setelah disetujui untuk dihapus
                  onDismissed: (direction) {
                    provider.deleteSkill(skill.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Skill "${skill.name}" berhasil dihapus'),
                        action: SnackBarAction(
                          label: 'Kembali',
                          onPressed: () {
                            // Menambahkan kembali data jika pengguna menekan Undo
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
                  child: GestureDetector(
                    onDoubleTap: () => _showEditSkillDialog(context, provider, skill),
                    child: InteractiveProgressCard(
                      skill: skill,
                      themeColor: categoryColor,
                      onProgressChanged: (newLevel, newProgress) {
                        // Membuat objek skill baru dengan nilai terupdate untuk dikirim ke DB
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
                        _showEditSkillDialog(context, provider, skill);
                      },
                      onEdit: () {
                        _showEditSkillDialog(context, provider, skill);
                      },
                      onDelete: () async {
                        final confirmed = await _showDeleteConfirmDialog(context, skill.name);
                        if (confirmed == true && context.mounted) {
                          provider.deleteSkill(skill.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Skill "${skill.name}" berhasil dihapus!'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Menghindari tabrakan dengan navbar
        child: FloatingActionButton(
          onPressed: () => _showAddSkillDialog(context, provider),
          backgroundColor: categoryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(Icons.task_alt, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Keterampilan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol tambah (+) di kanan bawah untuk mulai melacak keterampilan baru di kategori ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog konfirmasi penghapusan skill
  Future<bool?> _showDeleteConfirmDialog(BuildContext parentContext, String skillName) {
    return showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Skill?'),
          content: Text('Apakah Anda yakin ingin menghapus keterampilan "$skillName" dari pelacakan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog input untuk menambahkan keahlian baru
  void _showAddSkillDialog(BuildContext parentContext, SkillProvider provider) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Keahlian Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Keahlian',
                    hintText: 'misal: Refactoring, UI Design',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'misal: Belajar pola Clean Architecture',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final desc = descController.text.trim();

                if (name.isNotEmpty) {
                  provider.addSkill(
                    categoryId: category.id!,
                    name: name,
                    description: desc,
                  );
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Keahlian "$name" berhasil ditambahkan!'),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog input untuk mengedit keahlian
  void _showEditSkillDialog(BuildContext parentContext, SkillProvider provider, Skill skill) {
    final nameController = TextEditingController(text: skill.name);
    final descController = TextEditingController(text: skill.description);

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ubah Keahlian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Keahlian',
                    hintText: 'misal: Refactoring, UI Design',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'misal: Belajar pola Clean Architecture',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final desc = descController.text.trim();

                if (name.isNotEmpty) {
                  provider.updateSkill(Skill(
                    id: skill.id,
                    categoryId: skill.categoryId,
                    name: name,
                    description: desc,
                    level: skill.level,
                    progress: skill.progress,
                    createdAt: skill.createdAt,
                  ));
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Keahlian "$name" berhasil diperbarui!'),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  /// Kartu ringkasan kemajuan untuk kategori pembelajaran tertentu
  Widget _buildCategorySummaryHeaderCard(
    BuildContext context,
    List<Skill> skills,
    Color categoryColor,
  ) {
    final theme = Theme.of(context);
    final totalSkills = skills.length;

    // Hitung rata-rata level dan kemajuan total
    double avgLevel = 0.0;
    double overallProgress = 0.0;

    if (skills.isNotEmpty) {
      avgLevel = skills.map((s) => s.level.toDouble()).reduce((a, b) => a + b) / skills.length;
      final totalScore = skills.map((s) => ((s.level - 1) + s.progress) / 5.0).reduce((a, b) => a + b);
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
                    _getIconData(category.icon),
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
                        category.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target Penguasaan Kategori',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.hintColor,
                        ),
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
                Container(width: 1.5, height: 36, color: theme.dividerColor.withValues(alpha: 0.3)),
                _buildSummaryStat('Rerata Level', avgLevel > 0 ? avgLevel.toStringAsFixed(1) : '-', theme),
                Container(width: 1.5, height: 36, color: theme.dividerColor.withValues(alpha: 0.3)),
                _buildSummaryStat('Penguasaan', '${(overallProgress * 100).toInt()}%', theme, color: categoryColor),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, ThemeData theme, {Color? color}) {
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
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.hintColor,
          ),
        ),
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
}
