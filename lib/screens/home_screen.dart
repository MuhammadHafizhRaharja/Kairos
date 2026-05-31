import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../widgets/activity_rings_chart.dart';

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
                  Row(
                    children: [
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
                      const SizedBox(width: 8),
                      // Tappable Avatar
                      GestureDetector(
                        onTap: () => _showEditProfileBottomSheet(context, provider),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                          child: Text(
                            provider.userName.isNotEmpty ? provider.userName[0].toUpperCase() : 'K',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // GRAFIK RING KEMAJUAN KUSTOM
              _buildActivityRingsCard(context, provider),
              const SizedBox(height: 20),

              // KARTU STATISTIK PROGRESS
              _buildStatsCard(context, provider),
              const SizedBox(height: 32),

              // AKSES FITUR (HORIZONTAL BAR)
              Text(
                'Fitur Pelacakan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureBarItem(
                      context: context,
                      title: 'Keahlian',
                      subtitle: '${provider.skills.length} Keahlian',
                      icon: Icons.emoji_events_rounded,
                      color: theme.colorScheme.primary,
                      onTap: () => widget.onNavigate?.call(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFeatureBarItem(
                      context: context,
                      title: 'Referensi',
                      subtitle: provider.isNotificationEnabled ? 'Notifikasi Aktif' : 'Notifikasi Mati',
                      icon: Icons.auto_stories_rounded,
                      color: const Color(0xFF4CAF50),
                      onTap: () => widget.onNavigate?.call(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFeatureBarItem(
                      context: context,
                      title: 'Jurnal',
                      subtitle: 'Font ${provider.fontSize.toInt()} pt',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFFFF9800),
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

  void _showEditProfileBottomSheet(BuildContext context, SkillProvider provider) {
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
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 8),
              Text(
                'Ubah nama panggilan Anda untuk personalisasi dashboard.',
                style: TextStyle(color: theme.hintColor, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    provider.userName.isNotEmpty ? provider.userName[0].toUpperCase() : 'K',
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
                decoration: const InputDecoration(
                  labelText: 'Nama Panggilan',
                  prefixIcon: Icon(Icons.person_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final text = nameController.text.trim();
                  if (text.isNotEmpty) {
                    provider.updateUserName(text);
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nama profil berhasil disimpan secara persisten!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Simpan Perubahan'),
              ),
            ],
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
      final totalScore = provider.skills.map((s) {
        return ((s.level - 1) + s.progress) / 5.0;
      }).reduce((a, b) => a + b);
      skillProgress = (totalScore / provider.skills.length).clamp(0.0, 1.0);
    }

    // 2. Hitung progres Resource
    double resourceProgress = 0.5;
    if (provider.isNotificationEnabled) resourceProgress += 0.2;
    if (provider.defaultLang == 'id') resourceProgress += 0.1;
    resourceProgress = resourceProgress.clamp(0.15, 0.95);

    // 3. Hitung progres Progress Log
    double progressLogProgress = 0.3 + ((provider.fontSize - 12.0) / 12.0) * 0.5;
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
                  Icons.analytics_outlined,
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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

  Widget _buildFeatureBarItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
