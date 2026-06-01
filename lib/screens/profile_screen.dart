import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/skill_provider.dart';

/// Layar Detail Profil Pengguna yang mewah, interaktif, dan berdedikasi tinggi.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                const Text('Keluar Sesi', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Apakah Anda yakin ingin keluar dari akun Anda? Seluruh pencapaian belajarmu tetap tersimpan dengan aman.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: TextStyle(color: theme.hintColor)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx); // Tutup dialog
                  Navigator.pop(context); // Tutup halaman profil
                  await authProvider.logout(); // Bersihkan sesi aktif
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Anda telah berhasil keluar akun! Sampai jumpa lagi! 👋'),
                        backgroundColor: Colors.blueGrey,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final authProvider = context.watch<AuthProvider>();
    final skillProvider = context.watch<SkillProvider>();
    
    final user = authProvider.currentUser;
    final String initial = user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    
    // Formatting date
    final String formattedDate = user != null
        ? '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
        : '1/6/2026';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profil Pengguna', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Latar Belakang Gradasi Premium
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        theme.colorScheme.surface,
                      ]
                    : [
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                        theme.colorScheme.surface,
                      ],
              ),
            ),
          ),
          
          // Lingkaran Hiasan Blur
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: const SizedBox(),
              ),
            ),
          ),

          // 2. Konten Utama
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  
                  // A. HEAD SHOT & GLOWING AVATAR CARD
                  Center(
                    child: Column(
                      children: [
                        // Avatar Berkilau
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              initial,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Nama Lengkap Pengguna
                        Text(
                          user?.name ?? 'Pengguna Kairos',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        
                        // Email Pengguna
                        Text(
                          user?.email ?? 'user@kairos.app',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Joined Chip
                        Chip(
                          avatar: Icon(Icons.calendar_today_rounded, size: 12, color: theme.colorScheme.primary),
                          label: Text(
                            'Bergabung: $formattedDate',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // B. SECTION STATISTIK AKTIF (Visual Riil)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pencapaian Belajar Anda',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      _buildStatCard(
                        theme, 
                        Icons.dashboard_customize_rounded, 
                        'Kategori', 
                        '${skillProvider.categories.length}',
                        theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        theme, 
                        Icons.workspace_premium_rounded, 
                        'Keahlian', 
                        '${skillProvider.skills.length}',
                        theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        theme, 
                        Icons.menu_book_rounded, 
                        'Referensi', 
                        '${skillProvider.resources.length}',
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // C. SECTION PREFERENSI & SETELAN
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Preferensi & Setelan',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          // 1. Switch Notifikasi
                          ListTile(
                            leading: Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
                            title: const Text('Notifikasi Reaktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Aktifkan pengingat belajar reaktif', style: TextStyle(fontSize: 11)),
                            trailing: Switch(
                              value: skillProvider.isNotificationEnabled,
                              onChanged: (val) => skillProvider.toggleNotification(val),
                            ),
                          ),
                          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                          
                          // 2. Switch Mode Gelap
                          ListTile(
                            leading: Icon(
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: Colors.purple,
                            ),
                            title: const Text('Mode Gelap / Tema', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              isDark ? 'Tema gelap elegan aktif' : 'Tema terang dinamis aktif',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Switch(
                              value: skillProvider.isDarkMode,
                              onChanged: (val) => skillProvider.toggleTheme(val),
                            ),
                          ),
                          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                          
                          // 3. Dropdown Bahasa Default
                          ListTile(
                            leading: const Icon(Icons.language_rounded, color: Colors.blue),
                            title: const Text('Bahasa Utama', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Bahasa sistem referensi materi', style: TextStyle(fontSize: 11)),
                            trailing: DropdownButton<String>(
                              value: skillProvider.defaultLang,
                              underline: const SizedBox(),
                              borderRadius: BorderRadius.circular(16),
                              items: const [
                                DropdownMenuItem(value: 'id', child: Text('Indonesia (ID)', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'en', child: Text('English (EN)', style: TextStyle(fontSize: 12))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  skillProvider.updateDefaultLang(val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // D. TOMBOL LOGOUT PREMIUM
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.4), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: theme.colorScheme.error,
                        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.03),
                      ),
                      onPressed: () => _showLogoutDialog(context, authProvider, theme),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Keluar dari Sesi Aktif',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.hintColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
