import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../providers/progress_provider.dart';

/// Widget grafik lingkaran kemajuan kustom menggunakan [CustomPainter].
/// Menampilkan 3 ring konsentris mewakili status perkembangan ketiga modul (Skill, Resource, Progress).
class ActivityRingsChart extends StatelessWidget {
  final double size;

  const ActivityRingsChart({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillProvider>();

    // 1. Menghitung ring luar (Skill): Rata-rata pencapaian tingkat keahlian (level 1-5 & progres)
    double skillProgress = 0.0;
    if (provider.skills.isNotEmpty) {
      final totalScore = provider.skills
          .map((s) {
            // Asumsi level maksimal = 5.
            // Formula: (level_saat_ini - 1 + progres) / 5
            // Level 1 progres 0% -> 0.0
            // Level 5 progres 100% -> 1.0 (Naik ke tingkat berikutnya)
            return ((s.level - 1) + s.progress) / 5.0;
          })
          .reduce((a, b) => a + b);
      skillProgress = (totalScore / provider.skills.length).clamp(0.0, 1.0);
    } else {
      skillProgress = 0.0; // Jika belum ada skill
    }

    // 2. Ring tengah (Resource): Responsif terhadap status preferensi, notifikasi, dan penyelesaian materi secara dinamis
    double resourceProgress = 0.3;
    if (provider.isNotificationEnabled) {
      resourceProgress += 0.1;
    }
    if (provider.defaultLang == 'id') {
      resourceProgress += 0.1;
    }
    
    // Penanganan null-safe tambahan
    final resList = provider.resources;
    if (resList.isNotEmpty) {
      final completed = resList.where((r) => r.status == 2).length;
      resourceProgress += (completed / resList.length) * 0.45;
    }
    resourceProgress = resourceProgress.clamp(0.15, 0.95);

    // 3. Ring dalam (Progress Log): Responsif terhadap penyelesaian tantangan dan log
    double progressLogProgress = 0.3;
    final progressProvider = context.watch<ProgressProvider>();
    final challenges = progressProvider.challenges;
    final logs = progressProvider.logs;
    
    if (challenges.isNotEmpty) {
      final completed = challenges.where((c) => c.isCompleted == 1).length;
      progressLogProgress += (completed / challenges.length) * 0.65;
    } else if (logs.isNotEmpty) {
      progressLogProgress += (logs.length * 0.05);
    }
    progressLogProgress = progressLogProgress.clamp(0.15, 0.95);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingsPainter(
          skillProgress: skillProgress,
          resourceProgress: resourceProgress,
          progressProgress: progressLogProgress,
          theme: Theme.of(context),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double skillProgress;
  final double resourceProgress;
  final double progressProgress;
  final ThemeData theme;

  _RingsPainter({
    required this.skillProgress,
    required this.resourceProgress,
    required this.progressProgress,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    const double strokeWidth = 14.0;
    const double spacing = 18.0;

    // Warna Lingkaran (Ungu, Hijau, Jingga)
    final Color colorSkill = theme.colorScheme.primary; // Ungu
    final Color colorResource = const Color(0xFF4CAF50); // Hijau
    final Color colorProgress = const Color(0xFFFF9800); // Jingga

    // Menggambar 3 Ring (dari luar ke dalam)
    _drawRing(
      canvas: canvas,
      center: center,
      radius: (size.width / 2) - (strokeWidth / 2),
      strokeWidth: strokeWidth,
      progress: skillProgress,
      color: colorSkill,
    );

    _drawRing(
      canvas: canvas,
      center: center,
      radius: (size.width / 2) - (strokeWidth / 2) - spacing,
      strokeWidth: strokeWidth,
      progress: resourceProgress,
      color: colorResource,
    );

    _drawRing(
      canvas: canvas,
      center: center,
      radius: (size.width / 2) - (strokeWidth / 2) - (spacing * 2),
      strokeWidth: strokeWidth,
      progress: progressProgress,
      color: colorProgress,
    );
  }

  void _drawRing({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double strokeWidth,
    required double progress,
    required Color color,
  }) {
    // 1. Menggambar Background Track (Transparan)
    final Paint trackPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Menggambar Arc Progres Aktif
    final Paint activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap
          .round // Ujung membulat yang mewah
      ..strokeWidth = strokeWidth;

    // Mulai menggambar dari posisi atas (-90 derajat atau -pi/2)
    const double startAngle = -math.pi / 2;
    final double sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) {
    return oldDelegate.skillProgress != skillProgress ||
        oldDelegate.resourceProgress != resourceProgress ||
        oldDelegate.progressProgress != progressProgress ||
        oldDelegate.theme != theme;
  }
}
