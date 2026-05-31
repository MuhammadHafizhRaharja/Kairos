import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import 'skill_category_screen.dart';
import 'resource_placeholder_screen.dart';
import 'progress_placeholder_screen.dart';

/// Dashboard Utama aplikasi Kairos.
/// Menjadi pintu masuk navigasi ke semua modul dan mengelola data profil serta tema utama.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillProvider>();
    final theme = Theme.of(context);
    final isDark = provider.isDarkMode;

    // Sinkronisasi input field dengan state name di shared preferences
    if (!_isEditingName && _nameController.text != provider.userName) {
      _nameController.text = provider.userName;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER & TEMA TOGGLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KAIROS',
                          style: theme.textTheme.labelMedium?.copyWith(
                            letterSpacing: 3.0,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                  // Button Toggle Dark Mode (Shared Pref: appTheme)
                  IconButton(
                    icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainer,
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () {
                      provider.toggleTheme(!provider.isDarkMode);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KARTU STATISTIK PROGRESS
              _buildStatsCard(context, provider),
              const SizedBox(height: 32),

              // NAVIGASI MODUL (3 MODUL)
              Text(
                'Modul Pertumbuhan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildModuleCard(
                context: context,
                title: 'Modul Skill (Milik Saya)',
                subtitle: 'CRUD Kategori & Keahlian',
                description: 'Lacak keterampilan pemrograman, bahasa, olahraga, dll.',
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFF2196F3),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SkillCategoryScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),
              _buildModuleCard(
                context: context,
                title: 'Modul Resource (Rekan Tim)',
                subtitle: 'CRUD Materi & Referensi',
                description: 'Simpan artikel, tutorial, dan video penunjang.',
                icon: Icons.auto_stories_rounded,
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ResourcePlaceholderScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),
              _buildModuleCard(
                context: context,
                title: 'Modul Progress (Rekan Tim)',
                subtitle: 'CRUD Log & Tantangan',
                description: 'Catat progres latihan harian dan rintangan belajar.',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFFFF9800),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProgressPlaceholderScreen()),
                  );
                },
              ),
              const SizedBox(height: 32),

              // PENGATURAN PROFIL CEPAT (SHARED PREFERENCES)
              Text(
                'Pengaturan Profil',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _isEditingName
                            ? TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Masukkan nama...',
                                  isDense: true,
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                autofocus: true,
                                onSubmitted: (val) {
                                  _saveName(provider);
                                },
                              )
                            : Text(
                                provider.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      IconButton(
                        icon: Icon(_isEditingName ? Icons.check_circle : Icons.edit),
                        color: _isEditingName ? Colors.green : theme.colorScheme.primary,
                        onPressed: () {
                          if (_isEditingName) {
                            _saveName(provider);
                          } else {
                            setState(() {
                              _isEditingName = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveName(SkillProvider provider) {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) {
      provider.updateUserName(text);
    }
    setState(() {
      _isEditingName = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nama profil disimpan secara persisten!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, SkillProvider provider) {
    final theme = Theme.of(context);
    final totalCategories = provider.categories.length;
    final totalSkills = provider.skills.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hari ini adalah kesempatan untuk tumbuh.',
            style: TextStyle(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lanjutkan Pelatihan Anda!',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(totalCategories.toString(), 'Kategori', theme.colorScheme.onPrimary),
              Container(width: 1, height: 32, color: Colors.white24),
              _buildStatItem(totalSkills.toString(), 'Skill Aktif', theme.colorScheme.onPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label, Color fontColor) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: fontColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: fontColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon Modul
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 18),
              // Deskripsi & Teks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.hintColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
