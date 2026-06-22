import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/skill_provider.dart';
import '../models/skill_category.dart';
import '../models/skill.dart';
import 'skill_detail_screen.dart';
import '../providers/progress_provider.dart';
import '../widgets/skill_hexagon_radar.dart';

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
  String _selectedFilter =
      'Semua'; // 'Semua', 'Aktif', 'Menguasai', 'Belum Dimulai'
  bool _showRadarChart = true;

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
        final totalScore = skills
            .map((s) => ((s.level - 1) + s.progress) / 5.0)
            .reduce((a, b) => a + b);
        progress = (totalScore / skills.length).clamp(0.0, 1.0);
      }

      processedCategories.add({
        'category': cat,
        'skills': skills,
        'progress': progress,
      });
    }

    // 2. Terapkan Filter & Pencarian
    List<Map<String, dynamic>> filteredCategories = processedCategories.where((
      item,
    ) {
      final SkillCategory cat = item['category'];
      final List<Skill> skills = item['skills'];
      final double progress = item['progress'];

      // Pencarian berdasarkan nama kategori ATAU nama skill di dalamnya
      final matchesQuery =
          cat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          skills.any(
            (s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          );

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
        title: Text(
          provider.translate('nav_skills'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rawCategories.isEmpty
          ? _buildEmptyState(context, theme)
          : SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DASHBOARD STATISTIK DENGAN GRAFIK DISTRIBUSI & METRIK LENGKAP
                  _buildRichDashboardCard(context, processedCategories, provider),
                  const SizedBox(height: 20),

                  // 2. PANEL PENCARIAN & FILTER CHIP
                  _buildSearchAndFilterPanel(context, theme),
                  const SizedBox(height: 16),

                  // 3. DAFTAR GRID/LIST KATEGORI
                  filteredCategories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tidak ada kategori yang cocok',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : (context.watch<ProgressProvider>().viewMode == 'Grid'
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio:
                                          0.95, // Diberi sedikit rasio lebih tinggi untuk preview skill
                                    ),
                                itemCount: filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final item = filteredCategories[index];
                                  final SkillCategory category =
                                      item['category'];
                                  final List<Skill> skillsInCategory =
                                      item['skills'];
                                  final double progress = item['progress'];
                                  final color = Color(category.colorValue);

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SkillDetailScreen(
                                                category: category,
                                              ),
                                        ),
                                      );
                                    },
                                    onLongPress: () {
                                      _showCategoryOptionsBottomSheet(
                                        context,
                                        provider,
                                        category,
                                      );
                                    },
                                    onDoubleTap: () {
                                      _showQuickAddSkillDialog(
                                        context,
                                        provider,
                                        category,
                                      );
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              color.withValues(
                                                alpha: isDark ? 0.05 : 0.02,
                                              ),
                                              color.withValues(
                                                alpha: isDark ? 0.15 : 0.08,
                                              ),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Bagian Atas: Ikon + Mastery Tier Badge
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor: color
                                                      .withValues(alpha: 0.2),
                                                  child: Icon(
                                                    _getIconData(category.icon),
                                                    color: color,
                                                    size: 18,
                                                  ),
                                                ),
                                                _buildTierBadge(
                                                  progress,
                                                  skillsInCategory.isEmpty,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Bagian Tengah: Nama Kategori & Preview Sub-Skills
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    category.name,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),

                                                  // Preview 2 skill pertama
                                                  if (skillsInCategory
                                                      .isNotEmpty)
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: skillsInCategory.take(2).map((
                                                          s,
                                                        ) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 2.0,
                                                                ),
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  width: 4,
                                                                  height: 4,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        color,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    '${s.name} (Lvl ${s.level})',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          9.5,
                                                                      color: theme
                                                                          .textTheme
                                                                          .bodyMedium
                                                                          ?.color
                                                                          ?.withValues(
                                                                            alpha:
                                                                                0.7,
                                                                          ),
                                                                    ),
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
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
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: theme.hintColor,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),

                                            // Bagian Bawah: Statistik Progres
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: color,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child:
                                                      LinearProgressIndicator(
                                                        value: progress,
                                                        backgroundColor: color
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
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
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final item = filteredCategories[index];
                                  final SkillCategory category =
                                      item['category'];
                                  final List<Skill> skillsInCategory =
                                      item['skills'];
                                  final double progress = item['progress'];
                                  final color = Color(category.colorValue);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Slidable(
                                        key: ValueKey(category.id),
                                        endActionPane: ActionPane(
                                          motion: const BehindMotion(),
                                          extentRatio: 0.25,
                                          children: [
                                            SlidableAction(
                                              onPressed: (context) {
                                                _showDeleteConfirmDialog(
                                                  context,
                                                  provider,
                                                  category,
                                                );
                                              },
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                              icon: Icons.delete_outline_rounded,
                                              label: 'Hapus',
                                              borderRadius: const BorderRadius.horizontal(
                                                right: Radius.circular(20),
                                              ),
                                            ),
                                          ],
                                        ),
                                        startActionPane: ActionPane(
                                          motion: const BehindMotion(),
                                          extentRatio: 0.25,
                                          children: [
                                            SlidableAction(
                                              onPressed: (context) {
                                                _showEditCategoryDialog(
                                                  context,
                                                  provider,
                                                  category,
                                                );
                                              },
                                              backgroundColor:
                                                  theme.colorScheme.primary,
                                              foregroundColor: Colors.white,
                                              icon: Icons.edit_rounded,
                                              label: 'Ubah',
                                              borderRadius: const BorderRadius.horizontal(
                                                left: Radius.circular(20),
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SkillDetailScreen(
                                                      category: category,
                                                    ),
                                              ),
                                            );
                                          },
                                          onLongPress: () {
                                            _showCategoryOptionsBottomSheet(
                                              context,
                                              provider,
                                              category,
                                            );
                                          },
                                          onDoubleTap: () {
                                            _showQuickAddSkillDialog(
                                              context,
                                              provider,
                                              category,
                                            );
                                          },
                                          child: SizedBox(
                                            height: 160,
                                            child: Card(
                                              margin: EdgeInsets.zero,
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                side: BorderSide(
                                                  color: color.withValues(
                                                    alpha: 0.25,
                                                  ),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      color.withValues(
                                                        alpha: isDark
                                                            ? 0.05
                                                            : 0.02,
                                                      ),
                                                      color.withValues(
                                                        alpha: isDark
                                                            ? 0.15
                                                            : 0.08,
                                                      ),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    // Bagian Atas: Ikon + Mastery Tier Badge
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 18,
                                                          backgroundColor: color
                                                              .withValues(
                                                                  alpha: 0.2),
                                                          child: Icon(
                                                            _getIconData(
                                                              category.icon,
                                                            ),
                                                            color: color,
                                                            size: 18,
                                                          ),
                                                        ),
                                                        _buildTierBadge(
                                                          progress,
                                                          skillsInCategory
                                                              .isEmpty,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),

                                                    // Bagian Tengah: Nama Kategori & Preview Sub-Skills
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            category.name,
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                              height: 4),

                                                          // Preview 2 skill pertama
                                                          if (skillsInCategory
                                                              .isNotEmpty)
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children:
                                                                    skillsInCategory
                                                                        .take(2)
                                                                        .map((
                                                                  s,
                                                                ) {
                                                                  return Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .only(
                                                                      top: 2.0,
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        Container(
                                                                          width:
                                                                              4,
                                                                          height:
                                                                              4,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                color,
                                                                            shape:
                                                                                BoxShape.circle,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              4,
                                                                        ),
                                                                        Expanded(
                                                                          child:
                                                                              Text(
                                                                            '${s.name} (Lvl ${s.level})',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize:
                                                                                  9.5,
                                                                              color:
                                                                                  theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                                                            ),
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
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
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                color: theme
                                                                    .hintColor,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),

                                                    // Bagian Bawah: Statistik Progres
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              '${skillsInCategory.length} Skill',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: theme
                                                                    .hintColor,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${(progress * 100).toInt()}%',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: color,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            4,
                                                          ),
                                                          child:
                                                              LinearProgressIndicator(
                                                            value: progress,
                                                            backgroundColor:
                                                                color
                                                                    .withValues(
                                                              alpha: 0.1,
                                                            ),
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
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )),
                ],
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: () => _showAddCategoryDialog(context, provider),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 0.8,
        ),
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
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari kategori atau sub-keahlian...',
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary,
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
    List<Map<String, dynamic>> processedCategories,
    SkillProvider provider,
  ) {
    final theme = Theme.of(context);
    final totalSkills = provider.skills;
    final totalSkillsCount = totalSkills.length;

    // Hitung rata-rata kemajuan global
    double globalMastery = 0.0;
    int masteredSkillsCount = 0;
    if (totalSkillsCount > 0) {
      final totalScore = totalSkills
          .map((s) => ((s.level - 1) + s.progress) / 5.0)
          .reduce((a, b) => a + b);
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (processedCategories.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          _showRadarChart
                              ? Icons.analytics_outlined
                              : Icons.radar_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _showRadarChart = !_showRadarChart;
                          });
                        },
                        tooltip: _showRadarChart
                            ? 'Tampilkan Proporsi'
                            : 'Tampilkan Radar',
                      ),
                    Icon(
                      Icons.dashboard_customize_rounded,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ],
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
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
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
                      _buildDashboardStat(
                        'Kategori',
                        processedCategories.length.toString(),
                        theme,
                      ),
                      _buildDashboardStat(
                        'Keahlian',
                        totalSkillsCount.toString(),
                        theme,
                      ),
                      _buildDashboardStat(
                        'Master 🏆',
                        masteredSkillsCount.toString(),
                        theme,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (processedCategories.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              AnimatedCrossFade(
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Radar Kompetensi Heksagon:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SkillHexagonRadar(categoryData: processedCategories),
                  ],
                ),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proporsi Distribusi Kompetensi:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Tampilkan mini bar proporsi
                    Column(
                      children: processedCategories.take(3).map((item) {
                        final SkillCategory category = item['category'];
                        final List<Skill> skills = item['skills'];
                        final double ratio = totalSkillsCount > 0
                            ? skills.length / totalSkillsCount
                            : 0.0;
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
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${(ratio * 100).toInt()}% (${skills.length} Skill)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
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
                ),
                crossFadeState: _showRadarChart
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStat(
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
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: theme.hintColor)),
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
  void _showCategoryOptionsBottomSheet(
    BuildContext parentContext,
    SkillProvider provider,
    SkillCategory category,
  ) {
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
                title: const Text(
                  'Ubah Kategori',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Sesuaikan nama, ikon, atau warna kategori',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCategoryDialog(parentContext, provider, category);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                title: const Text(
                  'Hapus Kategori',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Menghapus permanen kategori beserta seluruh skill di dalamnya',
                ),
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

  /// Dialog konfirmasi penghapusan kategori (UI dipercantik dengan Bottom Sheet bertema warning)
  void _showDeleteConfirmDialog(
    BuildContext parentContext,
    SkillProvider provider,
    SkillCategory category,
  ) {
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
                      'Hapus Kategori?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Apakah Anda yakin ingin menghapus kategori "${category.name}"?\n\n'
                  'Seluruh keahlian di dalamnya akan terhapus secara permanen dari sistem.',
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    provider.deleteCategory(category.id!);
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Kategori "${category.name}" berhasil dihapus!',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Hapus Kategori'),
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

  /// Dialog dengan input kustom untuk mengedit Kategori yang ada (UI Bottom Sheet)
  void _showEditCategoryDialog(
    BuildContext parentContext,
    SkillProvider provider,
    SkillCategory category,
  ) {
    final nameController = TextEditingController(text: category.name);
    String selectedIcon = category.icon;
    int selectedColor = category.colorValue;
    final theme = Theme.of(parentContext);

    final iconsList = [
      'code',
      'fitness_center',
      'translate',
      'music_note',
      'book',
      'brush',
      'sports_basketball',
    ];
    final colorsList = [
      {'name': 'Biru', 'value': 0xFF2196F3},
      {'name': 'Hijau', 'value': 0xFF4CAF50},
      {'name': 'Jingga', 'value': 0xFFFF9800},
      {'name': 'Ungu', 'value': 0xFF9C27B0},
      {'name': 'Merah', 'value': 0xFFE91E63},
      {'name': 'Toska', 'value': 0xFF009688},
      {'name': 'Indigo', 'value': 0xFF3F51B5},
    ];

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
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
                          'Ubah Kategori',
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
                      'Ubah nama, ikon, atau warna kategori untuk menyelaraskan tracker.',
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Kategori',
                        prefixIcon: Icon(
                          Icons.category_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),

                    // Pilihan Ikon
                    const Text(
                      'Pilih Ikon:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: iconsList.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(selectedColor)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Color(selectedColor)
                                    : Colors.grey.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _getIconData(icon),
                              size: 22,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Pilihan Warna
                    const Text(
                      'Pilih Warna:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
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
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(colorVal),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? (theme.brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black)
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        final text = nameController.text.trim();
                        if (text.isNotEmpty) {
                          provider.updateCategory(
                            SkillCategory(
                              id: category.id,
                              name: text,
                              icon: selectedIcon,
                              colorValue: selectedColor,
                            ),
                          );
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Kategori "$text" berhasil diperbarui!',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Simpan Perubahan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
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
      },
    );
  }

  /// Dialog input untuk menambahkan Kategori baru (UI Bottom Sheet)
  void _showAddCategoryDialog(
    BuildContext parentContext,
    SkillProvider provider,
  ) {
    final nameController = TextEditingController();
    String selectedIcon = 'code';
    int selectedColor = 0xFF2196F3;
    final theme = Theme.of(parentContext);

    final iconsList = [
      'code',
      'fitness_center',
      'translate',
      'music_note',
      'book',
      'brush',
      'sports_basketball',
    ];
    final colorsList = [
      {'name': 'Biru', 'value': 0xFF2196F3},
      {'name': 'Hijau', 'value': 0xFF4CAF50},
      {'name': 'Jingga', 'value': 0xFFFF9800},
      {'name': 'Ungu', 'value': 0xFF9C27B0},
      {'name': 'Merah', 'value': 0xFFE91E63},
      {'name': 'Toska', 'value': 0xFF009688},
      {'name': 'Indigo', 'value': 0xFF3F51B5},
    ];

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
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
                          'Tambah Kategori Baru',
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
                      'Kelompokkan keahlian baru dengan ikon dan warna pilihan Anda.',
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Kategori',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),

                    // Pilihan Ikon
                    const Text(
                      'Pilih Ikon:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: iconsList.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(selectedColor)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Color(selectedColor)
                                    : Colors.grey.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _getIconData(icon),
                              size: 22,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Pilihan Warna
                    const Text(
                      'Pilih Warna:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
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
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(colorVal),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? (theme.brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black)
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        final text = nameController.text.trim();
                        if (text.isNotEmpty) {
                          provider.addCategory(
                            text,
                            selectedIcon,
                            selectedColor,
                          );
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Kategori "$text" berhasil ditambahkan!',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Simpan Kategori'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
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
      },
    );
  }

  /// Dialog input cepat untuk menambahkan keahlian baru (UI Bottom Sheet)
  void _showQuickAddSkillDialog(
    BuildContext parentContext,
    SkillProvider provider,
    SkillCategory category,
  ) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final theme = Theme.of(parentContext);
    final accentColor = Color(category.colorValue);

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
                      'Tambah Cepat Keahlian',
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
                  'Menambahkan keahlian baru secara instan di bawah kategori "${category.name}".',
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Keahlian',
                    prefixIcon: Icon(Icons.book_rounded, color: accentColor),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Keahlian (Opsional)',
                    prefixIcon: Icon(
                      Icons.edit_note_rounded,
                      color: accentColor,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
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
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Keahlian "$name" berhasil ditambahkan ke "${category.name}"!',
                          ),
                          backgroundColor: accentColor,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Simpan Keahlian'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
