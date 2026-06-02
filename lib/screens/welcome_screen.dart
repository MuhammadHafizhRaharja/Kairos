import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Halaman gerbang awal masuk aplikasi yang interaktif dan estetis.
/// Menyediakan pilihan "Saya Pengguna Baru" (ke Onboarding Register) dan "Sudah Punya Akun" (ke Login).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Latar Belakang Gradasi Dinamis dengan Efek Lingkaran Cahaya
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E1B4B), // Indigo gelap
                        const Color(0xFF0F172A), // Slate gelap
                        const Color(0xFF311042), // Ungu gelap
                      ]
                    : [
                        const Color(0xFFEEF2F6), // Abu sangat terang
                        const Color(0xFFE0E7FF), // Indigo sangat terang
                        const Color(0xFFFAE8FF), // Pink sangat terang
                      ],
              ),
            ),
          ),

          // Lingkaran Dekorasi Blur Bercahaya (Ungu/DeepPurple)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),

          // Lingkaran Dekorasi Blur Bercahaya (Biru/Cyan)
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withValues(alpha: isDark ? 0.25 : 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: const SizedBox(),
              ),
            ),
          ),

          // 2. Konten Utama
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),

                  // Logo / Nama Aplikasi KAIROS
                  Center(
                    child: Text(
                      'KAIROS',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8.0,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle / Slogan Motivasi
                  Center(
                    child: Text(
                      'Pintu Masuk Perkembangan Dirimu',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Lacak perkembangan keahlianmu dan kuasai masa depanmu secara terstruktur.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.hintColor.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Pilihan 1: Saya Pengguna Baru
                  _buildSelectionCard(
                    context: context,
                    theme: theme,
                    isDark: isDark,
                    title: 'Saya Pengguna Baru',
                    subtitle:
                        'Mulai petualangan belajar baru & set target pertama',
                    icon: Icons.rocket_launch_rounded,
                    color: theme.colorScheme.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Pilihan 2: Sudah Punya Akun
                  _buildSelectionCard(
                    context: context,
                    theme: theme,
                    isDark: isDark,
                    title: 'Sudah Punya Akun',
                    subtitle:
                        'Masuk kembali untuk melanjutkan perkembangan keahlianmu',
                    icon: Icons.lock_open_rounded,
                    color: theme.colorScheme.secondary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),

                  const Spacer(),

                  // Footer Copyright / Slogan Kecil
                  Center(
                    child: Text(
                      'Fokus • Konsisten • Berkembang',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.hintColor.withValues(alpha: 0.6),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: (isDark ? Colors.white : color).withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                splashColor: color.withValues(alpha: 0.15),
                highlightColor: color.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.hintColor.withValues(alpha: 0.8),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.hintColor.withValues(alpha: 0.7),
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
  }
}
