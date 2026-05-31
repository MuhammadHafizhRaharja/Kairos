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
          : skills.isEmpty
          ? _buildEmptyState(context, theme, categoryColor)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: skills.length,
              itemBuilder: (context, index) {
                final skill = skills[index];

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
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSkillDialog(context, provider),
        backgroundColor: categoryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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
  Future<bool?> _showDeleteConfirmDialog(
    BuildContext context,
    String skillName,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Skill?'),
          content: Text(
            'Apakah Anda yakin ingin menghapus keterampilan "$skillName" dari pelacakan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog input untuk menambahkan keahlian baru
  void _showAddSkillDialog(BuildContext context, SkillProvider provider) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
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
}
