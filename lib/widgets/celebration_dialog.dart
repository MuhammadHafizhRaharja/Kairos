import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// [PENTING] Dialog selebrasi ini adalah bagian krusial dari fitur "Gamifikasi".
/// Saat pengguna menyelesaikan tantangan, memunculkan sekadar teks "Berhasil" itu membosankan.
/// Dialog ini menggunakan library `lottie` (Assessment 3: library eksternal) untuk memutar
/// animasi vektor (Konfeti) yang menciptakan "Dopamine Hit" (Rasa senang/reward) di otak pengguna,
/// sehingga pengguna termotivasi untuk terus menyelesaikan tantangan berikutnya.
class CelebrationDialog {
  /// Tampilkan dialog selebrasi dengan animasi konfetti.
  static Future<void> show(BuildContext context, {String? title, String? message}) async {
    final theme = Theme.of(context);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Celebration',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animasi Lottie dari network (confetti / celebration)
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Lottie.network(
                      'https://lottie.host/3a7e0d7f-8c72-4c6c-b3f6-82e5a72e3b6e/KjZXJqFLkN.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback jika tidak bisa load dari network
                        return _buildFallbackAnimation(theme);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title ?? '🎉 Selamat!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message ?? 'Tantangan berhasil diselesaikan!',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Lanjutkan! 🚀',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Animasi fallback jika Lottie tidak bisa dimuat dari network.
  /// Menggunakan animasi Flutter bawaan sebagai pengganti.
  static Widget _buildFallbackAnimation(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.2),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}
