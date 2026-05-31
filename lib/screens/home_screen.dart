import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../models/skill.dart';
import '../models/skill_category.dart';
import '../widgets/activity_rings_chart.dart';
import '../widgets/weekly_activity_chart.dart';
import 'skill_detail_screen.dart';

/// Dashboard Utama aplikasi Kairos.
/// Menjadi pintu masuk navigasi ke semua modul dan mengelola data profil serta tema utama.
class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillProvider>();
    final theme = Theme.of(context);
    final isDark = provider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 20.0,
            bottom: 120.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER UTAMA (Greeting, Hari & Tanggal, Toggle Mode Gelap, Avatar Profil)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo KAIROS
                        Text(
                          'KAIROS',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Halo, ',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${provider.userName}! 👋',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Button Toggle Dark Mode (Shared Pref: appTheme)
                      IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainer,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          provider.toggleTheme(!provider.isDarkMode);
                        },
                      ),
                      const SizedBox(width: 10),
                      // Tappable Avatar dengan outline bercahaya
                      GestureDetector(
                        onTap: () =>
                            _showEditProfileBottomSheet(context, provider),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.5,
                              ),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            child: Text(
                              provider.userName.isNotEmpty
                                  ? provider.userName[0].toUpperCase()
                                  : 'K',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. MOTIVATIONAL BANNER DENGAN DESAIN PREMIUM GRADIENT
              _buildMotivationalBanner(theme),
              const SizedBox(height: 20),

              // 3. GRAFIK RING KEMAJUAN KUSTOM
              _buildActivityRingsCard(context, provider),
              const SizedBox(height: 20),

              // 4. KARTU STATISTIK PROGRESS CEPAT
              _buildStatsCard(context, provider),
              const SizedBox(height: 20),

              // 5. DIAGRAM BATANG AKTIVITAS MINGGUAN
              const WeeklyActivityChart(),
              const SizedBox(height: 24),

              // 6. AKTIVITAS KEAHLIAN TERKINI (Resume belajar dengan navigasi cepat)
              _buildRecentSkillsSection(context, provider, theme),
              const SizedBox(height: 24),

              // 7. AKSES FITUR UTAMA (HORIZONTAL GRID DENGAN PREMIUM GRADIENT CARD)
              Text(
                'Menu Navigasi Fitur',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureBarItem(
                      context: context,
                      title: 'Keahlian',
                      subtitle: '${provider.skills.length} Keahlian',
                      icon: Icons.emoji_events_rounded,
                      startColor: theme.colorScheme.primary,
                      endColor: theme.colorScheme.primary.withValues(
                        alpha: 0.7,
                      ),
                      onTap: () => widget.onNavigate?.call(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFeatureBarItem(
                      context: context,
                      title: 'Referensi',
                      subtitle: provider.isNotificationEnabled
                          ? 'Notifikasi Aktif'
                          : 'Notifikasi Mati',
                      icon: Icons.auto_stories_rounded,
                      startColor: const Color(0xFF4CAF50),
                      endColor: const Color(0xFF81C784),
                      onTap: () => widget.onNavigate?.call(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFeatureBarItem(
                      context: context,
                      title: 'Jurnal',
                      subtitle: 'Font ${provider.fontSize.toInt()} pt',
                      icon: Icons.trending_up_rounded,
                      startColor: const Color(0xFFFF9800),
                      endColor: const Color(0xFFFFB74D),
                      onTap: () => widget.onNavigate?.call(3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner motivasi premium
  Widget _buildMotivationalBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.85),
            theme.colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Icon(Icons.bolt_rounded, color: Colors.amber[300], size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fokus & Konsisten',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Langkah kecil setiap hari akan mengakumulasi perubahan besar. Keahlian apa yang ingin kamu asah hari ini?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bagian Aktivitas Keahlian Terkini
  Widget _buildRecentSkillsSection(
    BuildContext context,
    SkillProvider provider,
    ThemeData theme,
  ) {
    final List<Skill> recentSkills = provider.skills.take(3).toList();
    if (recentSkills.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Keahlian Terkini',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(Icons.history_rounded, color: theme.hintColor, size: 18),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: recentSkills.map((Skill skill) {
            // Cari kategori skill untuk warna dan ikon
            SkillCategory? parentCat;
            try {
              parentCat = provider.categories.firstWhere(
                (c) => c.id == skill.categoryId,
              );
            } catch (_) {
              // Jika kategori tidak ditemukan, buat placeholder
              parentCat = SkillCategory(
                name: 'Lainnya',
                icon: 'star',
                colorValue: 0xFF9C27B0,
              );
            }
            final catColor = Color(parentCat.colorValue);

            return Card(
              elevation: 0.5,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (parentCat != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SkillDetailScreen(category: parentCat!),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: catColor.withValues(alpha: 0.15),
                        child: Icon(
                          _getIconData(parentCat.icon),
                          color: catColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              skill.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              parentCat.name,
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Lvl ${skill.level}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: catColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: skill.progress,
                                backgroundColor: catColor.withValues(
                                  alpha: 0.1,
                                ),
                                color: catColor,
                                minHeight: 4,
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
          }).toList(),
        ),
      ],
    );
  }

  void _showEditProfileBottomSheet(
    BuildContext context,
    SkillProvider provider,
  ) {
    final nameController = TextEditingController(text: provider.userName);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
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
                      'Pengaturan Profil',
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
                  'Ubah nama panggilan Anda untuk personalisasi dashboard.',
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    child: Text(
                      provider.userName.isNotEmpty
                          ? provider.userName[0].toUpperCase()
                          : 'K',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Panggilan',
                    prefixIcon: const Icon(
                      Icons.person_rounded,
                      color: Colors.deepPurple,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.deepPurple,
                        width: 2,
                      ),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    final text = nameController.text.trim();
                    if (text.isNotEmpty) {
                      provider.updateUserName(text);
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nama profil berhasil disimpan secara persisten!',
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Simpan Perubahan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
  }

  Widget _buildActivityRingsCard(BuildContext context, SkillProvider provider) {
    final theme = Theme.of(context);

    // 1. Hitung progres Skill
    double skillProgress = 0.0;
    if (provider.skills.isNotEmpty) {
      final totalScore = provider.skills
          .map((s) {
            return ((s.level - 1) + s.progress) / 5.0;
          })
          .reduce((a, b) => a + b);
      skillProgress = (totalScore / provider.skills.length).clamp(0.0, 1.0);
    }

    // 2. Hitung progres Resource
    double resourceProgress = 0.5;
    if (provider.isNotificationEnabled) resourceProgress += 0.2;
    if (provider.defaultLang == 'id') resourceProgress += 0.1;
    resourceProgress = resourceProgress.clamp(0.15, 0.95);

    // 3. Hitung progres Progress Log
    double progressLogProgress =
        0.3 + ((provider.fontSize - 12.0) / 12.0) * 0.5;
    progressLogProgress = progressLogProgress.clamp(0.15, 0.95);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cincin Kemajuan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.donut_large_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const ActivityRingsChart(size: 110),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRingLegendItem(
                        color: theme.colorScheme.primary,
                        label: 'Modul Skill',
                        value: '${(skillProgress * 100).toInt()}%',
                      ),
                      const SizedBox(height: 10),
                      _buildRingLegendItem(
                        color: const Color(0xFF4CAF50),
                        label: 'Modul Resource',
                        value: '${(resourceProgress * 100).toInt()}%',
                      ),
                      const SizedBox(height: 10),
                      _buildRingLegendItem(
                        color: const Color(0xFFFF9800),
                        label: 'Modul Progress',
                        value: '${(progressLogProgress * 100).toInt()}%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, SkillProvider provider) {
    final theme = Theme.of(context);
    final totalCategories = provider.categories.length;
    final totalSkills = provider.skills.length;

    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            context: context,
            title: 'Kategori',
            value: totalCategories.toString(),
            icon: Icons.category_rounded,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            context: context,
            title: 'Keahlian Aktif',
            value: totalSkills.toString(),
            icon: Icons.bolt_rounded,
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.hintColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBarItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color startColor,
    required Color endColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: startColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              startColor.withValues(alpha: isDark ? 0.05 : 0.02),
              endColor.withValues(alpha: isDark ? 0.18 : 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 8.0,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: startColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: startColor, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9.5, color: theme.hintColor),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
}
