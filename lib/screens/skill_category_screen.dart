import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../models/skill_category.dart';
import 'skill_detail_screen.dart';

/// Halaman utama Modul Skill. Menampilkan kategori keahlian dalam Grid.
/// Mendukung tambah kategori baru dan hapus kategori via long-press gesture.
class SkillCategoryScreen extends StatelessWidget {
  const SkillCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillProvider>();
    final categories = provider.categories;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modul Keahlian'),
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
              ? _buildEmptyState(context, theme)
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final skillsInCategory = provider.getSkillsForCategory(category.id ?? -1);

                    return GestureDetector(
                      // Gesture 1: Ketuk sekali untuk menavigasi ke halaman detail skill
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SkillDetailScreen(category: category),
                          ),
                        );
                      },
                      // Gesture 2: Tekan lama untuk memicu dialog hapus kategori
                      onLongPress: () {
                        _showDeleteConfirmDialog(context, provider, category);
                      },
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Color(category.colorValue).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Color(category.colorValue).withValues(alpha: 0.05),
                                Color(category.colorValue).withValues(alpha: 0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Bagian Ikon Kategori
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(category.colorValue).withValues(alpha: 0.2),
                                child: Icon(
                                  _getIconData(category.icon),
                                  color: Color(category.colorValue),
                                  size: 24,
                                ),
                              ),
                              // Bagian Teks & Statistik
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${skillsInCategory.length} Keahlian',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.hintColor,
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
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('Kategori'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    final provider = context.read<SkillProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 80, color: theme.hintColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Kategori',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan kategori baru untuk mulai mengelompokkan keterampilan yang ingin Anda kembangkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddCategoryDialog(context, provider),
              child: const Text('Buat Kategori Pertama'),
            ),
          ],
        ),
      ),
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

  /// Dialog konfirmasi penghapusan kategori (dengan relasi cascade delete)
  void _showDeleteConfirmDialog(BuildContext context, SkillProvider provider, SkillCategory category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Hapus Kategori?'),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus kategori "${category.name}"? '
            'Menghapus kategori ini juga akan menghapus SEMUA keahlian yang ada di dalamnya secara permanen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                provider.deleteCategory(category.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kategori "${category.name}" berhasil dihapus!'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog dengan input kustom warna & ikon untuk menambahkan Kategori baru
  void _showAddCategoryDialog(BuildContext context, SkillProvider provider) {
    final nameController = TextEditingController();
    String selectedIcon = 'code';
    int selectedColor = 0xFF2196F3;

    final iconsList = ['code', 'fitness_center', 'translate', 'music_note', 'book', 'brush', 'sports_basketball'];
    final colorsList = [
      {'name': 'Biru', 'value': 0xFF2196F3},
      {'name': 'Hijau', 'value': 0xFF4CAF50},
      {'name': 'Jingga', 'value': 0xFFFF9800},
      {'name': 'Ungu', 'value': 0xFF9C27B0},
      {'name': 'Merah', 'value': 0xFFE91E63},
      {'name': 'Toska', 'value': 0xFF009688},
      {'name': 'Indigo', 'value': 0xFF3F51B5},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Kategori Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori',
                        hintText: 'misal: Memasak, Menulis',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    // Pilihan Ikon
                    const Text('Pilih Ikon:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: iconsList.length,
                        itemBuilder: (context, idx) {
                          final icon = iconsList[idx];
                          final isSelected = selectedIcon == icon;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Icon(
                                _getIconData(icon),
                                size: 20,
                                color: isSelected ? Colors.white : Colors.grey,
                              ),
                              selected: isSelected,
                              selectedColor: Color(selectedColor),
                              onSelected: (_) {
                                setState(() {
                                  selectedIcon = icon;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Pilihan Warna
                    const Text('Pilih Warna:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colorsList.map((colorMap) {
                        final colorVal = colorMap['value'] as int;
                        final isSelected = selectedColor == colorVal;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = colorVal;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(colorVal),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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
                    final text = nameController.text.trim();
                    if (text.isNotEmpty) {
                      provider.addCategory(text, selectedIcon, selectedColor);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Kategori "$text" berhasil ditambahkan!'),
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
      },
    );
  }
}
