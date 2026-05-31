import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../models/skill_category.dart';
import '../models/skill.dart';
import 'skill_detail_screen.dart';

/// Halaman utama Modul Skill. Menampilkan kategori keahlian dalam Grid.
/// Mendukung tambah kategori baru dan hapus kategori via long-press gesture.
/// Mendukung pencarian kategori/sub-keahlian, filter chip, dan memiliki dashboard statistik yang kaya.
class SkillCategoryScreen extends StatefulWidget {
  const SkillCategoryScreen({super.key});

  @override
  State<SkillCategoryScreen> createState() => _SkillCategoryScreenState();
}

class _SkillCategoryScreenState extends State<SkillCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua', 'Aktif', 'Menguasai', 'Belum Dimulai'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillProvider>();
    final rawCategories = provider.categories;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Hitung progres dan saring kategori dinamis
    List<Map<String, dynamic>> processedCategories = [];
    for (var cat in rawCategories) {
      final skills = provider.getSkillsForCategory(cat.id ?? -1);
      
      double progress = 0.0;
      if (skills.isNotEmpty) {
        final totalScore = skills.map((s) => ((s.level - 1) + s.progress) / 5.0).reduce((a, b) => a + b);
        progress = (totalScore / skills.length).clamp(0.0, 1.0);
      }

      processedCategories.add({
        'category': cat,
        'skills': skills,
        'progress': progress,
      });
    }

    // 2. Terapkan Filter & Pencarian
    List<Map<String, dynamic>> filteredCategories = processedCategories.where((item) {
      final SkillCategory cat = item['category'];
      final List<Skill> skills = item['skills'];
      final double progress = item['progress'];

      // Pencarian berdasarkan nama kategori ATAU nama skill di dalamnya
      final matchesQuery = cat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          skills.any((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()));

      bool matchesFilter = true;
      if (_selectedFilter == 'Aktif') {
        // Kategori aktif memiliki skill yang sudah berkembang (progres > 0 atau lvl > 1)
        matchesFilter = skills.any((s) => s.level > 1 || s.progress > 0.0);
      } else if (_selectedFilter == 'Menguasai') {
        // Rata-rata penguasaan >= 80%
        matchesFilter = progress >= 0.8 && skills.isNotEmpty;
      } else if (_selectedFilter == 'Belum Dimulai') {
        // Belum ada skill atau rata-rata progres masih 0%
        matchesFilter = progress == 0.0 || skills.isEmpty;
      }

      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modul Keahlian',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rawCategories.isEmpty
              ? _buildEmptyState(context, theme)
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. DASHBOARD STATISTIK DENGAN GRAFIK DISTRIBUSI & METRIK LENGKAP
                      _buildRichDashboardCard(context, rawCategories, provider),
                      const SizedBox(height: 20),

                      // 2. PANEL PENCARIAN & FILTER CHIP
                      _buildSearchAndFilterPanel(context, theme),
                      const SizedBox(height: 16),

                      // 3. DAFTAR GRID KATEGORI
                      filteredCategories.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 48, color: theme.hintColor),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tidak ada kategori yang cocok',
                                      style: TextStyle(color: theme.hintColor, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.95, // Diberi sedikit rasio lebih tinggi untuk preview skill
                              ),
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                final item = filteredCategories[index];
                                final SkillCategory category = item['category'];
                                final List<Skill> skillsInCategory = item['skills'];
                                final double progress = item['progress'];
                                final color = Color(category.colorValue);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SkillDetailScreen(category: category),
                                      ),
                                    );
                                  },
                                  onLongPress: () {
                                    _showCategoryOptionsBottomSheet(context, provider, category);
                                  },
                                  onDoubleTap: () {
                                    _showQuickAddSkillDialog(context, provider, category);
                                  },
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: color.withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: LinearGradient(
                                          colors: [
                                            color.withValues(alpha: isDark ? 0.05 : 0.02),
                                            color.withValues(alpha: isDark ? 0.15 : 0.08),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Bagian Atas: Ikon + Mastery Tier Badge
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: color.withValues(alpha: 0.2),
                                                child: Icon(
                                                  _getIconData(category.icon),
                                                  color: color,
                                                  size: 18,
                                                ),
                                              ),
                                              _buildTierBadge(progress, skillsInCategory.isEmpty),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Bagian Tengah: Nama Kategori & Preview Sub-Skills
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  category.name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                
                                                // Preview 2 skill pertama
                                                if (skillsInCategory.isNotEmpty)
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: skillsInCategory.take(2).map((s) {
                                                        return Padding(
                                                          padding: const EdgeInsets.only(top: 2.0),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                width: 4,
                                                                height: 4,
                                                                decoration: BoxDecoration(
                                                                  color: color,
                                                                  shape: BoxShape.circle,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Expanded(
                                                                child: Text(
                                                                  '${s.name} (Lvl ${s.level})',
                                                                  style: TextStyle(
                                                                    fontSize: 9.5,
                                                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    'Belum ada keahlian',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontStyle: FontStyle.italic,
                                                      color: theme.hintColor,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),

                                          // Bagian Bawah: Statistik Progres
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '${skillsInCategory.length} Skill',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: theme.hintColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${(progress * 100).toInt()}%',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: color,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  backgroundColor: color.withValues(alpha: 0.1),
                                                  color: color,
                                                  minHeight: 4,
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
                    ],
                  ),
                ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: () => _showAddCategoryDialog(context, provider),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_rounded),
        ),
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
            Icon(
              Icons.category_outlined,
              size: 80,
              color: theme.hintColor.withValues(alpha: 0.5),
            ),
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
            ElevatedButton.icon(
              onPressed: () => _showAddCategoryDialog(context, provider),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Kategori Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membuat visual lencana tingkat penguasaan
  Widget _buildTierBadge(double progress, bool isEmpty) {
    if (isEmpty) return const SizedBox.shrink();

    String label = 'Pemula';
    Color badgeColor = Colors.blue;

    if (progress >= 1.0) {
      label = 'Master 🏆';
      badgeColor = Colors.amber;
    } else if (progress >= 0.8) {
      label = 'Ahli';
      badgeColor = Colors.redAccent;
    } else if (progress >= 0.4) {
      label = 'Menengah';
      badgeColor = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  /// Bar Pencarian & Panel Filter Chip
  Widget _buildSearchAndFilterPanel(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final filters = ['Semua', 'Aktif', 'Menguasai', 'Belum Dimulai'];

    return Column(
      children: [
        // Bar Pencarian Kategori / Skill
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.deepPurple.withValues(alpha: 0.15),
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari kategori atau sub-keahlian...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.deepPurple),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
        const SizedBox(height: 10),

        // Horisontal Filter Chips
        SingleChildScrollView(
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.deepPurple,
                  backgroundColor: isDark ? Colors.grey[950] : Colors.grey[200],
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
      ],
    );
  }

  /// Dashboard Statistik Kompetensi Kaya
  Widget _buildRichDashboardCard(
    BuildContext context,
    List<SkillCategory> categories,
    SkillProvider provider,
  ) {
    final theme = Theme.of(context);
    final totalSkills = provider.skills;
    final totalSkillsCount = totalSkills.length;

    // Hitung rata-rata kemajuan global
    double globalMastery = 0.0;
    int masteredSkillsCount = 0;
    if (totalSkillsCount > 0) {
      final totalScore = totalSkills.map((s) => ((s.level - 1) + s.progress) / 5.0).reduce((a, b) => a + b);
      globalMastery = (totalScore / totalSkillsCount).clamp(0.0, 1.0);
      masteredSkillsCount = totalSkills.where((s) => s.level >= 5).length;
    }

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
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Panel Dashboard
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard Keahlian',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.dashboard_customize_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Baris Metrik: Lingkaran Penguasaan Global + Grid Metrik Ringkas
            Row(
              children: [
                // 1. Circular Progress Penguasaan Global
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: globalMastery,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        color: theme.colorScheme.primary,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(globalMastery * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // 2. Status Angka Detail
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDashboardStat('Kategori', categories.length.toString(), theme),
                      _buildDashboardStat('Keahlian', totalSkillsCount.toString(), theme),
                      _buildDashboardStat('Master 🏆', masteredSkillsCount.toString(), theme, color: Colors.amber),
                    ],
                  ),
                ),
              ],
            ),

            if (categories.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Text(
                'Proporsi Distribusi Kompetensi:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Tampilkan mini bar proporsi
              Column(
                children: categories.take(3).map((category) {
                  final skills = provider.getSkillsForCategory(category.id ?? -1);
                  final double ratio = totalSkillsCount > 0 ? skills.length / totalSkillsCount : 0.0;
                  final color = Color(category.colorValue);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${(ratio * 100).toInt()}% (${skills.length} Skill)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio,
                            backgroundColor: color.withValues(alpha: 0.1),
                            color: color,
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStat(String label, String value, ThemeData theme, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
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

  /// Bottom sheet opsi kategori (Ubah / Hapus) yang dipercantik dengan drag pill handle
  void _showCategoryOptionsBottomSheet(BuildContext parentContext, SkillProvider provider, SkillCategory category) {
    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle Pill
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'Pilihan Kategori',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.edit_rounded, color: Colors.blue),
                ),
                title: const Text('Ubah Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Sesuaikan nama, ikon, atau warna kategori'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCategoryDialog(parentContext, provider, category);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                ),
                title: const Text('Hapus Kategori', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                subtitle: const Text('Menghapus permanen kategori beserta seluruh skill di dalamnya'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(parentContext, provider, category);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// Dialog konfirmasi penghapusan kategori (UI dipercantik dengan ikon warning mencolok)
  void _showDeleteConfirmDialog(
    BuildContext parentContext,
    SkillProvider provider,
    SkillCategory category,
  ) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Column(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
                  'Hapus Kategori?',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              'Apakah Anda yakin ingin menghapus kategori "${category.name}"?\n\n'
              'Seluruh keahlian di dalamnya akan terhapus secara permanen dari sistem.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.deleteCategory(category.id!);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Kategori "${category.name}" berhasil dihapus!',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog dengan input kustom untuk mengedit Kategori yang ada (UI dipercantik)
  void _showEditCategoryDialog(BuildContext parentContext, SkillProvider provider, SkillCategory category) {
    final nameController = TextEditingController(text: category.name);
    String selectedIcon = category.icon;
    int selectedColor = category.colorValue;

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
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Column(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.mode_edit_outline_rounded, color: Colors.white, size: 26),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ubah Kategori',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Kategori',
                        hintText: 'misal: Memasak, Menulis',
                        prefixIcon: const Icon(Icons.category_rounded, color: Colors.deepPurple),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pilihan Ikon
                    const Text('Pilih Ikon:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: iconsList.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(selectedColor) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Color(selectedColor) : Colors.grey.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _getIconData(icon),
                              size: 20,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pilihan Warna
                    const Text('Pilih Warna:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colorsList.map((colorMap) {
                        final colorVal = colorMap['value'] as int;
                        final isSelected = selectedColor == colorVal;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
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
                                color: isSelected
                                    ? (Theme.of(builderContext).brightness == Brightness.dark ? Colors.white : Colors.black)
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final text = nameController.text.trim();
                    if (text.isNotEmpty) {
                      provider.updateCategory(SkillCategory(
                        id: category.id,
                        name: text,
                        icon: selectedIcon,
                        colorValue: selectedColor,
                      ));
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('Kategori "$text" berhasil diperbarui!'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Dialog input untuk menambahkan Kategori baru (UI dipercantik)
  void _showAddCategoryDialog(BuildContext parentContext, SkillProvider provider) {
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
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Column(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.category_rounded, color: Colors.white, size: 26),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tambah Kategori',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Kategori',
                        hintText: 'misal: Memasak, Menulis',
                        prefixIcon: const Icon(Icons.category_outlined, color: Colors.deepPurple),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pilihan Ikon
                    const Text('Pilih Ikon:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: iconsList.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(selectedColor) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Color(selectedColor) : Colors.grey.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _getIconData(icon),
                              size: 20,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pilihan Warna
                    const Text('Pilih Warna:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colorsList.map((colorMap) {
                        final colorVal = colorMap['value'] as int;
                        final isSelected = selectedColor == colorVal;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
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
                                color: isSelected
                                    ? (Theme.of(builderContext).brightness == Brightness.dark ? Colors.white : Colors.black)
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final text = nameController.text.trim();
                    if (text.isNotEmpty) {
                      provider.addCategory(text, selectedIcon, selectedColor);
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('Kategori "$text" berhasil ditambahkan!'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Dialog input cepat untuk menambahkan keahlian baru (UI dipercantik)
  void _showQuickAddSkillDialog(
    BuildContext parentContext,
    SkillProvider provider,
    SkillCategory category,
  ) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final accentColor = Color(category.colorValue);

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tambah Cepat (${category.name})',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Keahlian',
                    hintText: 'misal: Refactoring, UI Design',
                    prefixIcon: Icon(Icons.book_rounded, color: accentColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'misal: Belajar pola Clean Architecture',
                    prefixIcon: Icon(Icons.edit_note_rounded, color: accentColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
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
                      content: Text(
                        'Keahlian "$name" berhasil ditambahkan ke "${category.name}"!',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Simpan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        );
      },
    );
  }
}
